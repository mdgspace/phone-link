#pragma once

#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include "../mdns/mdnsmanager.h"
#include "../tcp/tcpserver.h"

class Backend : public QObject
{
    Q_OBJECT

    // Device name exposed to QML
    Q_PROPERTY(QString deviceName READ deviceName WRITE setDeviceName NOTIFY deviceNameChanged FINAL)

    // mDNS registration state
    Q_PROPERTY(bool registering READ isRegistering NOTIFY registeringChanged FINAL)

    // TCP server state
    Q_PROPERTY(bool serverRunning READ isServerRunning NOTIFY serverRunningChanged FINAL)

public:
    explicit Backend(QObject *parent = nullptr);

    // mDNS control
    Q_INVOKABLE void registerOnMdns();
    Q_INVOKABLE void stopRegistration();

    // TCP server control
    Q_INVOKABLE void startTcpServer();
    Q_INVOKABLE void stopTcpServer();

    // Property getters
    QString deviceName() const;
    bool isRegistering() const;
    bool isServerRunning() const;

public slots:
    void setDeviceName(const QString &name);

signals:
    void deviceNameChanged();
    void registeringChanged();
    void serverRunningChanged();

private:
    // mDNS (advertising only)
    MdnsManager m_mdnsManager;

    // TCP server
    TcpServer m_tcpServer;

    bool m_registering = false;
    bool m_serverRunning = false;

    // app configuration
    QString m_deviceName = "Ava's Dell Laptop";
    QString m_serviceType = "_phonelink._tcp";
    quint16 m_port = 5555;
};

#endif // BACKEND_H
