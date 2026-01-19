#pragma once

#include <QObject>
#include <thread>

extern "C" {
#include <avahi-client/client.h>
#include <avahi-client/publish.h>
#include <avahi-client/lookup.h>
#include <avahi-common/simple-watch.h>
#include <avahi-common/error.h>
}

class MdnsManager : public QObject
{
    Q_OBJECT
public:
    explicit MdnsManager(QObject *parent = nullptr);
    ~MdnsManager();

    void registerService(const QString &name,
                         const QString &serviceType,
                         quint16 port);

    void startDiscovery();
    void stopDiscovery();
    void start();
    void stop();

signals:
    void deviceDiscovered(const QString &name,
                          const QString &address,
                          const QString &service,
                          quint16 port);

private:
    void run();

    std::thread m_thread;
    AvahiSimplePoll *m_poll = nullptr;
    AvahiClient *m_client = nullptr;
    AvahiEntryGroup *m_group = nullptr;
    AvahiServiceBrowser *m_browser = nullptr;

    QString m_serviceType = "_phonelink._tcp";
    bool m_ready = false;

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
