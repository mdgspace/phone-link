#include "nsd_broadcaster.h"
#include <QDebug>
#include <QtEndian>

// Note: To compile this on Windows/macOS/Linux with native zero-conf support, 
// you should link against the Bonjour / Avahi compatibility library (`dns_sd`).
// In your CMakeLists.txt add: find_package(DNSSD REQUIRED) and link it.
// For now, if -DHAS_DNS_SD is provided to the compiler, it activates true broadcasting.

#if defined(HAS_DNS_SD)
#include <dns_sd.h>
#else
// Stub definition for when the dns_sd library is not yet linked
typedef void* DNSServiceRef;
#endif

NsdBroadcaster::NsdBroadcaster(QObject *parent)
    : QObject(parent), m_serviceRef(nullptr)
{
}

NsdBroadcaster::~NsdBroadcaster()
{
    stop();
}

bool NsdBroadcaster::start(const QString &serviceName, const QString &serviceType, quint16 port)
{
    if (m_serviceRef) {
        stop();
    }

    qDebug() << "Starting NSD Broadcast for" << serviceName << "type:" << serviceType << "on port" << port;

#if defined(HAS_DNS_SD)
    // Use the native Bonjour/Avahi C API
    DNSServiceErrorType err = DNSServiceRegister(
        reinterpret_cast<DNSServiceRef*>(&m_serviceRef),
        0,                  // flags
        0,                  // interface index (0 = all interfaces)
        serviceName.toUtf8().constData(),
        serviceType.toUtf8().constData(),
        nullptr,            // domain (nullptr = default local domain)
        nullptr,            // host (nullptr = default host)
        qToBigEndian<quint16>(port), // port must be in network byte order
        0,                  // txt record length
        nullptr,            // txt record data
        nullptr,            // callback
        nullptr             // context
    );

    if (err != 0) {
        qCritical() << "Failed to register NSD service, error code:" << err;
        return false;
    }
#else
    qWarning() << "DNS-SD library not linked. Broadcasting is mocked and will not emit actual mDNS packets on the network.";
    qWarning() << "To fix: Link your project with the Bonjour/Avahi client libraries and add -DHAS_DNS_SD to compiler definitions.";
#endif

    qDebug() << "NSD Service broadcast started successfully.";
    return true;
}

void NsdBroadcaster::stop()
{
    if (m_serviceRef) {
        qDebug() << "Stopping NSD Broadcast.";
#if defined(HAS_DNS_SD)
        DNSServiceRefDeallocate(reinterpret_cast<DNSServiceRef>(m_serviceRef));
#endif
        m_serviceRef = nullptr;
    }
}