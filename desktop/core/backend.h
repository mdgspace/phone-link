#pragma once

#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QUuid>
#include <QSysInfo>
#include <QHash>
#include <QTcpSocket>

#include "../mdns/mdnsmanager.h"
#include "../tcp/tcpserver.h"
#include "../tcp/protocol.h"
#include "../protocol/messagerouter.h"

#include "../features/clipboard/clipboardmodel.h"
#include "../features/filetransfer/sharedfilesmodel.h"
#include "../features/messaging/messagemodel.h"
#include "../features/notification/notificationmodel.h"

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

    // Pairing dialog state (shown on desktop while a phone waits to pair)
    Q_PROPERTY(bool pairingPending
                   READ isPairingPending
                       NOTIFY pairingPendingChanged)

    Q_PROPERTY(QString pairingPin
                   READ pairingPin
                       NOTIFY pairingPendingChanged)

    Q_PROPERTY(QString pairingDeviceName
                   READ pairingDeviceName
                       NOTIFY pairingPendingChanged)

    // Real connection state for ConnectedPage.qml (was hardcoded before)
    Q_PROPERTY(bool peerConnected
                   READ isPeerConnected
                       NOTIFY peerConnectionChanged)

    Q_PROPERTY(QString peerDeviceName
                   READ peerDeviceName
                       NOTIFY peerConnectionChanged)

    // Desktop-side error/status surface, e.g. "port already in use".
    // Mirrors the errorMessage exposed by Flutter's ConnectionManager,
    // but for server-side failures rather than outbound connection ones.
    Q_PROPERTY(QString errorMessage
                   READ errorMessage
                       NOTIFY errorMessageChanged)

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

    Q_PROPERTY(NotificationModel* notificationModel
                   READ notificationModel
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

    // Pairing dialog actions (called from QML once the user responds)
    Q_INVOKABLE void confirmPairing();
    Q_INVOKABLE void rejectPairing();

    /*
     * ================================
     * PROPERTY GETTERS
     * ================================
     */

    QString deviceName() const;
    bool isRegistering() const;
    bool isServerRunning() const;

    bool isPairingPending() const { return m_pairingPending; }
    QString pairingPin() const { return m_pairingPin; }
    QString pairingDeviceName() const { return m_pairingDeviceName; }

    bool isPeerConnected() const { return m_peerConnected; }
    QString peerDeviceName() const { return m_peerDeviceName; }
    QString errorMessage() const { return m_errorMessage; }

    ClipboardModel* clipboardModel() { return &m_clipboardModel; }
    MessageModel* messageModel() { return &m_messageModel; }
    SharedFilesModel* sharedFilesModel() { return &m_sharedFilesModel; }
    NotificationModel* notificationModel() { return &m_notificationModel; }

    /*
     * ================================
     * NETWORK MESSAGE ENTRY POINT
     * ================================
     */

private slots:
    void handleIncomingMessage(QTcpSocket *client, const Message &message);
    void onHelloReceived(const QString &deviceId, const QString &deviceName);
    void onPairingRequested(const QString &deviceId, const QString &pin);
    void onPairingAcceptedFromPhone();
    void onDisconnected();
    void onNotificationPosted(const QString &notificationId,
                               const QString &appName,
                               const QString &title,
                               const QString &text);
    void onNotificationDismissed(const QString &notificationId);

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
    void onMessageReceived(const QString &id, const QString &address, const QString &body, bool isIncoming, qint64 timestamp);
    void onFileReceived(const QString &transferId, const QString &fileName, qint64 totalBytes, const QString &filePath);

signals:
    /*
     * ================================
     * PROPERTY CHANGE SIGNALS
     * ================================
     */

    void deviceNameChanged();
    void registeringChanged();
    void serverRunningChanged();
    void pairingPendingChanged();
    void peerConnectionChanged();
    void errorMessageChanged();

private:
    /*
     * ================================
     * APPLICATION CONFIGURATION
     * ================================
     */

    QString m_deviceId = QUuid::createUuid().toString(QUuid::WithoutBraces);
    QString m_deviceName = QSysInfo::machineHostName();
    QString m_serviceType = "_phonelink._tcp";
    quint16 m_port = TCP_SERVER_PORT;
    int m_protocolVersion = 1; // matches mobile/flutter_ui/lib/data/local_device.dart

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
     * PAIRING
     * ================================
     */
    bool m_pairingPending = false;
    QString m_pairingPin;
    QString m_pairingDeviceId;
    QString m_pairingDeviceName;

    /*
     * ================================
     * DATA MODELS
     * ================================
     */

    ClipboardModel m_clipboardModel;
    MessageModel m_messageModel;
    SharedFilesModel m_sharedFilesModel;
    NotificationModel m_notificationModel;

    // The socket for the connection currently being processed / paired.
    // PhoneLink only expects a single active phone connection at a time,
    // so tracking "the current client" is sufficient here.
    QTcpSocket *m_activeClient = nullptr;

    bool m_peerConnected = false;
    QString m_peerDeviceName;
    QString m_errorMessage;

    // Most recently seen device name per device id, captured from HELLO,
    // so it's available by the time PAIRING_REQUEST (which only carries
    // device_id) arrives.
    QHash<QString, QString> m_recentDeviceNames;

    bool isDeviceTrusted(const QString &deviceId) const;
    void trustDevice(const QString &deviceId, const QString &deviceName);
};

#endif // BACKEND_H