#pragma once

#include <QObject>
#include <mutex>

extern "C" {
#include <avahi-client/client.h>
#include <avahi-client/publish.h>
#include <avahi-client/lookup.h>
#include <avahi-common/thread-watch.h>
#include <avahi-common/error.h>
}

class MdnsManager : public QObject
{
    Q_OBJECT
public:
    explicit MdnsManager(QObject *parent = nullptr);
    ~MdnsManager();

    // Queues the service and publishes it on the Avahi thread.
    // Avahi objects are not safe to use from the Qt GUI thread.
    bool registerService(const QString &name,
                         const QString &serviceType,
                         quint16 port,
                         const QString &deviceId,
                         int protocolVersion = 1);

    void start();
    void stop();

signals:
    void deviceDiscovered(const QString &name,
                          const QString &address,
                          const QString &service,
                          quint16 port);

private:
    struct PendingService {
        QString name;
        QString serviceType;
        quint16 port = 0;
        QString deviceId;
        int protocolVersion = 1;
        bool present = false;
    };

    // Caller must hold the Avahi threaded-poll lock, or be inside an Avahi callback.
    bool publishPending();

    AvahiThreadedPoll *m_poll = nullptr;
    AvahiClient *m_client = nullptr;
    AvahiEntryGroup *m_group = nullptr;
    AvahiServiceBrowser *m_browser = nullptr;

    std::mutex m_mutex;
    PendingService m_pending;

    static void clientCallback(AvahiClient *, AvahiClientState, void *);
    static void browseCallback(AvahiServiceBrowser *,
                               AvahiIfIndex,
                               AvahiProtocol,
                               AvahiBrowserEvent,
                               const char *,
                               const char *,
                               const char *,
                               AvahiLookupResultFlags,
                               void *);
    static void resolveCallback(AvahiServiceResolver *,
                                AvahiIfIndex,
                                AvahiProtocol,
                                AvahiResolverEvent,
                                const char *,
                                const char *,
                                const char *,
                                const char *,
                                const AvahiAddress *,
                                uint16_t,
                                AvahiStringList *,
                                AvahiLookupResultFlags,
                                void *);
};
