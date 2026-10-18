#include "mdnsmanager.h"
#include <QDebug>

MdnsManager::MdnsManager(QObject *parent)
    : QObject(parent)
{
}

void MdnsManager::start()
{
    qDebug() << "[mDNS] start() called";

    if (m_poll)
        return;

    m_poll = avahi_threaded_poll_new();
    if (!m_poll) {
        qWarning() << "[mDNS] Failed to create AvahiThreadedPoll";
        return;
    }

    int error = 0;
    m_client = avahi_client_new(
        avahi_threaded_poll_get(m_poll),
        AVAHI_CLIENT_NO_FAIL,
        &MdnsManager::clientCallback,
        this,
        &error
        );

    if (!m_client) {
        qWarning() << "[mDNS] Failed to create AvahiClient:"
                   << avahi_strerror(error);
        avahi_threaded_poll_free(m_poll);
        m_poll = nullptr;
        return;
    }

    if (avahi_threaded_poll_start(m_poll) < 0) {
        qWarning() << "[mDNS] Failed to start Avahi thread";
        avahi_client_free(m_client);
        m_client = nullptr;
        avahi_threaded_poll_free(m_poll);
        m_poll = nullptr;
        return;
    }

    qDebug() << "[mDNS] Avahi thread started";
}

void MdnsManager::stop()
{
    if (!m_poll)
        return;

    avahi_threaded_poll_stop(m_poll);

    if (m_browser) {
        avahi_service_browser_free(m_browser);
        m_browser = nullptr;
    }

    if (m_group) {
        avahi_entry_group_free(m_group);
        m_group = nullptr;
    }

    if (m_client) {
        avahi_client_free(m_client);
        m_client = nullptr;
    }

    avahi_threaded_poll_free(m_poll);
    m_poll = nullptr;
}

MdnsManager::~MdnsManager()
{
    stop();
}

void MdnsManager::clientCallback(AvahiClient *client,
                                 AvahiClientState state,
                                 void *userdata)
{
    auto *self = static_cast<MdnsManager *>(userdata);

    qDebug() << "[mDNS] clientCallback state =" << state;

    switch (state) {

    case AVAHI_CLIENT_S_RUNNING:
        qDebug() << "[mDNS] Avahi client running";
        self->publishPending();
        break;

    case AVAHI_CLIENT_FAILURE:
        qWarning() << "[mDNS] Avahi client failure:"
                   << avahi_strerror(avahi_client_errno(client));
        break;

    case AVAHI_CLIENT_S_COLLISION:
    case AVAHI_CLIENT_S_REGISTERING:
        if (self->m_group)
            avahi_entry_group_reset(self->m_group);
        break;

    default:
        break;
    }
}

bool MdnsManager::registerService(const QString &name,
                                  const QString &serviceType,
                                  quint16 port,
                                  const QString &deviceId,
                                  int protocolVersion)
{
    if (!m_poll || !m_client) {
        qWarning() << "[mDNS] registerService called before Avahi started";
        return false;
    }

    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_pending.name = name;
        m_pending.serviceType = serviceType;
        m_pending.port = port;
        m_pending.deviceId = deviceId;
        m_pending.protocolVersion = protocolVersion;
        m_pending.present = true;
    }

    avahi_threaded_poll_lock(m_poll);
    const bool published = publishPending();
    avahi_threaded_poll_unlock(m_poll);
    return published;
}

bool MdnsManager::publishPending()
{
    PendingService pending;
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_pending.present)
            return false;
        pending = m_pending;
    }

    if (!m_client || avahi_client_get_state(m_client) != AVAHI_CLIENT_S_RUNNING) {
        qDebug() << "[mDNS] service queued until Avahi is running";
        return true;
    }

    if (m_group)
        avahi_entry_group_reset(m_group);
    else
        m_group = avahi_entry_group_new(m_client, nullptr, nullptr);

    if (!m_group) {
        qWarning() << "[mDNS] avahi_entry_group_new failed:"
                   << avahi_strerror(avahi_client_errno(m_client));
        return false;
    }

    qDebug() << "[mDNS] registerService called"
             << "name =" << pending.name
             << "type =" << pending.serviceType
             << "port =" << pending.port;

    // TXT records mirror the phone's own registration
    // (mobile/flutter_ui/lib/services/mdns_registration.dart): id, proto,
    // plat. We additionally publish "name" since mdns_discovery.dart
    // reads txt['name'] for display, falling back to the raw service
    // instance name if absent.
    const QByteArray idTxt = ("id=" + pending.deviceId).toUtf8();
    const QByteArray protoTxt =
        ("proto=" + QString::number(pending.protocolVersion)).toUtf8();
    const QByteArray platTxt = QByteArray("plat=desktop");
    const QByteArray nameTxt = ("name=" + pending.name).toUtf8();
    const QByteArray serviceName = pending.name.toUtf8();
    const QByteArray serviceType = pending.serviceType.toUtf8();

    const int added = avahi_entry_group_add_service(
        m_group,
        AVAHI_IF_UNSPEC,
        AVAHI_PROTO_UNSPEC,
        AvahiPublishFlags(0),
        serviceName.constData(),
        serviceType.constData(),
        nullptr,
        nullptr,
        pending.port,
        idTxt.constData(),
        protoTxt.constData(),
        platTxt.constData(),
        nameTxt.constData(),
        nullptr
        );

    if (added < 0) {
        qWarning() << "[mDNS] add service failed:"
                   << avahi_strerror(added);
        return false;
    }

    const int committed = avahi_entry_group_commit(m_group);
    if (committed < 0) {
        qWarning() << "[mDNS] commit service failed:"
                   << avahi_strerror(committed);
        return false;
    }

    return true;
}


// // In MdnsManager.cpp
// void MdnsManager::startDiscovery()
// {
//     // Hardcode for testing to ensure it's not empty
//     const char* type = "_phonelink._tcp";

//     m_browser = avahi_service_browser_new(
//         m_client,
//         AVAHI_IF_UNSPEC,
//         AVAHI_PROTO_UNSPEC,
//         type, // Use the hardcoded string
//         nullptr,
//         static_cast<AvahiLookupFlags>(0),
//         &MdnsManager::browseCallback,
//         this
//         );
// }

// void MdnsManager::stopDiscovery()
// {
//     if (!m_browser)
//         return;

//     avahi_service_browser_free(m_browser);
//     m_browser = nullptr;

//     qDebug() << "[mDNS] discovery stopped";
// }

void MdnsManager::browseCallback(AvahiServiceBrowser *,
                                 AvahiIfIndex interface,
                                 AvahiProtocol protocol,
                                 AvahiBrowserEvent event,
                                 const char *name,
                                 const char *type,
                                 const char *domain,
                                 AvahiLookupResultFlags,
                                 void *userdata)
{
    qDebug() << "[mDNS] browseCallback event:" << event << "name:" << (name ? name : "NULL");

    if (event != AVAHI_BROWSER_NEW)
        return;

    auto *self = static_cast<MdnsManager *>(userdata);

    avahi_service_resolver_new(
        self->m_client,
        interface,
        protocol,
        name,
        type,
        domain,
        AVAHI_PROTO_UNSPEC,
        static_cast<AvahiLookupFlags>(0),
        &MdnsManager::resolveCallback,
        userdata
        );
}

void MdnsManager::resolveCallback(AvahiServiceResolver *r,
                                  AvahiIfIndex,
                                  AvahiProtocol,
                                  AvahiResolverEvent event,
                                  const char *name,
                                  const char *type,
                                  const char *,
                                  const char *,
                                  const AvahiAddress *addr,
                                  uint16_t port,
                                  AvahiStringList *,
                                  AvahiLookupResultFlags,
                                  void *userdata)
{
    if (event != AVAHI_RESOLVER_FOUND) {
        qWarning() << "[mDNS] Resolve failed for" << (name ? name : "unknown");
        avahi_service_resolver_free(r);
        return;
    }
    qDebug() << "[mDNS] Resolved successfully:" << name << "at" << addr;

    char address[AVAHI_ADDRESS_STR_MAX];
    avahi_address_snprint(address, sizeof(address), addr);

    auto *self = static_cast<MdnsManager *>(userdata);

    qDebug() << "[mDNS] emitting deviceDiscovered";

    QMetaObject::invokeMethod(
        self,
        [self,
         n = QString::fromUtf8(name),
         a = QString::fromUtf8(address),
         t = QString::fromUtf8(type ? type : ""),
         p = port]() {
            emit self->deviceDiscovered(
                n,
                a,
                t,
                p
                );
        },
        Qt::QueuedConnection
        );


    avahi_service_resolver_free(r);
}
