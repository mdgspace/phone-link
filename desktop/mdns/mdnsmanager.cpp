#include "mdnsmanager.h"
#include <QDebug>

MdnsManager::MdnsManager(QObject *parent)
    : QObject(parent)
{
}

void MdnsManager::run()
{
    qDebug() << "[mDNS] Avahi thread started";

    m_poll = avahi_simple_poll_new();
    if (!m_poll) {
        qWarning() << "[mDNS] Failed to create AvahiSimplePoll";
        return;
    }

    int error = 0;
    m_client = avahi_client_new(
        avahi_simple_poll_get(m_poll),
        AVAHI_CLIENT_NO_FAIL,
        &MdnsManager::clientCallback,
        this,
        &error
        );

    if (!m_client) {
        qWarning() << "[mDNS] Failed to create AvahiClient:"
                   << avahi_strerror(error);
        return;
    }

    qDebug() << "[mDNS] Entering Avahi event loop";
    avahi_simple_poll_loop(m_poll);

    qDebug() << "[mDNS] Avahi event loop exited";
}

void MdnsManager::start()
{
    qDebug() << "[mDNS] start() called";

    if (m_thread.joinable()) {
        qDebug() << "[mDNS] thread already running";
        return;
    }

    m_thread = std::thread(&MdnsManager::run, this);
}



void MdnsManager::stop()
{
    // Stop discovery
    if (m_browser) {
        avahi_service_browser_free(m_browser);
        m_browser = nullptr;
    }

    // Stop service registration
    if (m_group) {
        avahi_entry_group_reset(m_group);
        avahi_entry_group_free(m_group);
        m_group = nullptr;
    }

    // Stop Avahi event loop
    if (m_poll) {
        avahi_simple_poll_quit(m_poll);
    }

    // Join worker thread
    if (m_thread.joinable()) {
        m_thread.join();
    }

    // Free poll object
    if (m_poll) {
        avahi_simple_poll_free(m_poll);
        m_poll = nullptr;
    }
}

MdnsManager::~MdnsManager()
{
    stop();
}

void MdnsManager::clientCallback(AvahiClient *client,
                                 AvahiClientState state,
                                 void *userdata)
{
    Q_UNUSED(client);

    auto *self = static_cast<MdnsManager *>(userdata);

    qDebug() << "[mDNS] clientCallback state =" << state;

    switch (state) {

    case AVAHI_CLIENT_S_RUNNING:
        qDebug() << "[mDNS] Avahi client running";
        self->m_ready = true;
        break;

    case AVAHI_CLIENT_FAILURE:
        qWarning() << "Avahi client failure";
        // You could stop the poll here if you want:
        // avahi_simple_poll_quit(self->m_poll);
        break;

    case AVAHI_CLIENT_S_COLLISION:
    case AVAHI_CLIENT_S_REGISTERING:
        // Name collision or re-registering — normal states
        break;

    default:
        break;
    }
}

void MdnsManager::registerService(const QString &name,
                                  const QString &serviceType,
                                  quint16 port)
{
    if (!m_ready) {
        qWarning() << "[mDNS] registerService called before Avahi ready";
        return;
    }

    m_serviceType = serviceType;

    if (!m_group) {
        m_group = avahi_entry_group_new(m_client, nullptr, nullptr);
    }

    qDebug() << "[mDNS] registerService called"
             << "name =" << name
             << "type =" << serviceType
             << "port =" << port;

    avahi_entry_group_add_service(
        m_group,
        AVAHI_IF_UNSPEC,
        AVAHI_PROTO_UNSPEC,
        AvahiPublishFlags(0),
        name.toUtf8().constData(),
        serviceType.toUtf8().constData(),
        nullptr,
        nullptr,
        port,
        nullptr
        );

    avahi_entry_group_commit(m_group);
}


// In MdnsManager.cpp
void MdnsManager::startDiscovery()
{
    // Hardcode for testing to ensure it's not empty
    const char* type = "_phonelink._tcp";

    m_browser = avahi_service_browser_new(
        m_client,
        AVAHI_IF_UNSPEC,
        AVAHI_PROTO_UNSPEC,
        type, // Use the hardcoded string
        nullptr,
        static_cast<AvahiLookupFlags>(0),
        &MdnsManager::browseCallback,
        this
        );
}

void MdnsManager::stopDiscovery()
{
    if (!m_browser)
        return;

    avahi_service_browser_free(m_browser);
    m_browser = nullptr;

    qDebug() << "[mDNS] discovery stopped";
}

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
                                  const char *,
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
         p = port]() {
            emit self->deviceDiscovered(
                n,
                a,
                self->m_serviceType,
                p
                );
        },
        Qt::QueuedConnection
        );


    avahi_service_resolver_free(r);
}
