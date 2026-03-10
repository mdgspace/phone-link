#pragma once

#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>

#include "../mdns/mdnsmanager.h"
#include "../tcp/tcpserver.h"
#include "../protocol/messagerouter.h"

#include "../models/clipboardmodel.h"
#include "../models/messagemodel.h"
#include "../models/sharedfilesmodel.h"

class Backend : public QObject
{
    Q_OBJECT

    /*
     * ================================
     * QML EXPOSED PROPERTIES
     * ================================
     */

    // Device configuration
    Q_PROPERTY(QString deviceName
                   READ deviceName
                       WRITE setDeviceName
                           NOTIFY deviceNameChanged)

    // mDNS advertising state
    Q_PROPERTY(bool registering
                   READ isRegistering
                       NOTIFY registeringChanged)

    // TCP server state
    Q_PROPERTY(bool serverRunning
                   READ isServerRunning
                       NOTIFY serverRunningChanged)

    // Data models exposed to UI
    Q_PROPERTY(ClipboardModel* clipboardModel
                   READ clipboardModel
                       CONSTANT)

    Q_PROPERTY(MessageModel* messageModel
                   READ messageModel
                       CONSTANT)

    Q_PROPERTY(SharedFilesModel* sharedFilesModel
                   READ sharedFilesModel
                       CONSTANT)

public:
    /*
     * ================================
     * CONSTRUCTOR
     * ================================
     */

    explicit Backend(QObject *parent = nullptr);

    /*
     * ================================
     * QML CALLABLE FUNCTIONS
     * ================================
     */

    // mDNS control
    Q_INVOKABLE void registerOnMdns();
    Q_INVOKABLE void stopRegistration();

    // TCP server control
    Q_INVOKABLE void startTcpServer();
    Q_INVOKABLE void stopTcpServer();

    /*
     * ================================
     * PROPERTY GETTERS
     * ================================
     */

    QString deviceName() const;
    bool isRegistering() const;
    bool isServerRunning() const;

    ClipboardModel* clipboardModel() { return &m_clipboardModel; }
    MessageModel* messageModel() { return &m_messageModel; }
    SharedFilesModel* sharedFilesModel() { return &m_sharedFilesModel; }

    /*
     * ================================
     * NETWORK MESSAGE ENTRY POINT
     * ================================
     */

    void handleIncomingMessage(QTcpSocket *client, const QByteArray &data);

public slots:
    /*
     * ================================
     * PROPERTY MUTATORS
     * ================================
     */

    void setDeviceName(const QString &name);

    /*
     * ================================
     * FEATURE HANDLER EVENTS
     * ================================
     */

    void onClipboardReceived(const QString &text);
    void onMessageReceived(const QString &sender, const QString &text);
    void onFileReceived(const QString &path);

signals:
    /*
     * ================================
     * PROPERTY CHANGE SIGNALS
     * ================================
     */

    void deviceNameChanged();
    void registeringChanged();
    void serverRunningChanged();

private:
    /*
     * ================================
     * APPLICATION CONFIGURATION
     * ================================
     */

    QString m_deviceName = "Ava's Dell Laptop";
    QString m_serviceType = "_phonelink._tcp";
    quint16 m_port = 5555;

    /*
     * ================================
     * NETWORK SUBSYSTEMS
     * ================================
     */

    MdnsManager m_mdnsManager;
    TcpServer m_tcpServer;

    bool m_registering = false;
    bool m_serverRunning = false;

    /*
     * ================================
     * PROTOCOL ROUTER
     * ================================
     */

    MessageRouter m_router;

    /*
     * ================================
     * UI DATA MODELS
     * ================================
     */

    ClipboardModel m_clipboardModel;
    MessageModel m_messageModel;
    SharedFilesModel m_sharedFilesModel;
};

#endif // BACKEND_H
