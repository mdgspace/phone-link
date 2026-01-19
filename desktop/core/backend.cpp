#include "backend.h"
#include <QThread>

Backend::Backend(QObject *parent)
    : QObject(parent)
{

    qDebug() << "[Backend] constructor";

    m_mdnsManager.start();

    connect(&m_mdnsManager,
            &MdnsManager::deviceDiscovered,
            this,
            &Backend::onDeviceDiscovered,
            Qt::QueuedConnection);
}

// Getters
QString Backend::deviceName() const
{
    return m_deviceName;
}

DiscoveryList* Backend::discoveryList()
{
    return &m_discoveryList;
}

bool Backend::isRegistering() const
{
    return m_registering;
}

bool Backend::isDiscovering() const
{ return m_discovering; }


void Backend::setDeviceName(const QString &name)
{
    // Avoid unnecessary work
    if (name == m_deviceName)
        return;

    // Very light sanity check (optional but good)
    if (name.trimmed().isEmpty())
        return;

    m_deviceName = name;
    emit deviceNameChanged();
}

void Backend::startDiscovery()
{
    if (m_discovering)
        return;

    m_discovering = true;
    emit discoveringChanged();

    m_mdnsManager.startDiscovery();
}


void Backend::stopDiscovery()
{
    if (!m_discovering)
        return;

    m_discovering = false;
    emit discoveringChanged();

    m_mdnsManager.stopDiscovery();
}


void Backend::registerOnMdns()
{
    if (m_registering)
        return;

    m_mdnsManager.registerService(
        m_deviceName,
        m_serviceType,
        m_port
        );

    m_registering = true;
    emit registeringChanged();
}

void Backend::stopRegistration()
{
    if (!m_registering)
        return;

    // m_mdnsManager.stopRegistration();

    m_registering = false;
    emit registeringChanged();
}


// const means that this function will not modify the caller's variables
void Backend::onDeviceDiscovered(const QString &name,
                                 const QString &address,
                                 const QString &service,
                                 quint16 port)
{
    qDebug() << "[UI THREAD]" << QThread::currentThread();

    qDebug() << "[Backend] device discovered:"
             << name << address << port;

    m_discoveryList.addDevice(name, address, service, port);
}


