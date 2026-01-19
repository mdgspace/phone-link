#pragma once

#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include "../mdns/mdnsmanager.h"
#include "../mdns/discoverylist.h"

class Backend : public QObject
{
    Q_OBJECT

    // Exposing this property to QML
    Q_PROPERTY(DiscoveryList* discoveryList READ discoveryList CONSTANT)
    Q_PROPERTY(QString deviceName READ deviceName WRITE setDeviceName NOTIFY deviceNameChanged FINAL)
    Q_PROPERTY(bool registering READ isRegistering NOTIFY registeringChanged FINAL)
    Q_PROPERTY(bool discovering READ isDiscovering NOTIFY discoveringChanged)

public:
    explicit Backend(QObject *parent = nullptr);

    // Called from QML Buttons
    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void stopDiscovery();
    Q_INVOKABLE void registerOnMdns();
    Q_INVOKABLE void stopRegistration();

    // Model access for QML
    DiscoveryList* discoveryList();

    // Property getters
    QString deviceName() const;
    bool isRegistering() const;
    bool isDiscovering() const;

public slots:
    void setDeviceName(const QString &name);

private slots:
    // react to mDNS events
    void onDeviceDiscovered(const QString &name,
                            const QString &address,
                            const QString &service,
                            quint16 port);

signals:
    void deviceNameChanged();
    void registeringChanged();
    void discoveringChanged();

private:
    // owned components
    MdnsManager m_mdnsManager;
    DiscoveryList m_discoveryList;

    bool m_registering = false;
    bool m_discovering = false;

    // app-level policy / configuration
    QString m_deviceName = "Ava's Dell Laptop";
    QString m_serviceType = "_phonelink._tcp";
    quint16 m_port = 5555;
};

#endif // BACKEND_H
