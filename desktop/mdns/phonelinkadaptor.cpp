#include "phonelinkadaptor.h"

PhoneLinkAdaptor::PhoneLinkAdaptor(PhoneLinkBackend *backend) : QDBusAbstractAdaptor(backend), m_backend(backend)
{
    connect(backend, &PhoneLinkBackend::deviceConnected,
            this, &PhoneLinkAdaptor::deviceConnected);
}

QString PhoneLinkAdaptor::deviceName() const
{
    return m_backend->deviceName();
}

void PhoneLinkAdaptor::connectDevice(const QString &id)
{
    m_backend->connectDevice(id);
}
