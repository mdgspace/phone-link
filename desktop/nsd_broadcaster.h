#ifndef NSD_BROADCASTER_H
#define NSD_BROADCASTER_H

#include <QObject>
#include <QString>

class NsdBroadcaster : public QObject
{
    Q_OBJECT
public:
    explicit NsdBroadcaster(QObject *parent = nullptr);
    ~NsdBroadcaster();

    /// Starts broadcasting the NSD service on the local network.
    /// @param serviceName The human-readable name of the device (e.g., "Meet's Laptop").
    /// @param serviceType The service type, matching the Flutter app (e.g., "_phonelink._tcp").
    /// @param port The TCP port your desktop server will listen on.
    bool start(const QString &serviceName, const QString &serviceType, quint16 port);
    
    /// Stops the NSD broadcast.
    void stop();

private:
    // Opaque pointer to the underlying service reference (e.g., DNSServiceRef for Bonjour/Avahi)
    // Kept as void* in the header so we don't have to expose the native dns_sd library to all includers.
    void *m_serviceRef;
};

#endif // NSD_BROADCASTER_H