#include "backend.h"
#include <QThread>
#include <QDebug>
#include <QSettings>
#include <QRandomGenerator>
#include "../protocol/protocoltypes.h"
#include "../protocol/messageparser.h"

Backend::Backend(QObject *parent)
    : QObject(parent)
{
    qDebug() << "[Backend] constructor";
    qDebug() << "[Backend] thread:" << QThread::currentThread();

    // connect signals and slots
    connect(&m_tcpServer,
            &TcpServer::messageReceived,
            this,
            &Backend::handleIncomingMessage);

    connect(m_router.clipboardHandler(),
            &ClipboardHandler::clipboardReceived,
            this,
            &Backend::onClipboardReceived);

    connect(m_router.messagingHandler(),
            &MessagingHandler::messageReceived,
            this,
            &Backend::onMessageReceived);

    connect(m_router.fileHandler(),
            &FileTransferHandler::fileReceived,
            this,
            &Backend::onFileReceived);

    // SystemHandler -> Backend
    connect(
        m_router.systemHandler(),
        &SystemHandler::helloReceived,
        this,
        &Backend::onHelloReceived);

    connect(
        m_router.systemHandler(),
        &SystemHandler::pairingRequested,
        this,
        &Backend::onPairingRequested);

    connect(
        m_router.systemHandler(),
        &SystemHandler::disconnected,
        this,
        &Backend::onDisconnected);

    connect(
        m_router.systemHandler(),
        &SystemHandler::pairingAccepted,
        this,
        &Backend::onPairingAcceptedFromPhone);

    connect(
        m_router.notificationHandler(),
        &NotificationHandler::notificationPosted,
        this,
        &Backend::onNotificationPosted);

    // Start mDNS subsystem
    m_mdnsManager.start();
}


// ======================
// Getters
// ======================

QString Backend::deviceName() const
{
    return m_deviceName;
}

bool Backend::isRegistering() const
{
    return m_registering;
}

bool Backend::isServerRunning() const
{
    return m_serverRunning;
}


// ======================
// Device name
// ======================

void Backend::setDeviceName(const QString &name)
{
    if (name == m_deviceName)
        return;

    if (name.trimmed().isEmpty())
        return;

    m_deviceName = name;
    emit deviceNameChanged();
}


// ======================
// TCP Server Control
// ======================

void Backend::startTcpServer()
{
    if (m_serverRunning)
        return;

    if (!m_tcpServer.start(m_port)) {
        m_errorMessage = QString("Failed to start TCP server on port %1 "
                                  "(port may already be in use)").arg(m_port);
        qWarning() << m_errorMessage;
        emit errorMessageChanged();
        return;
    }

    if (!m_errorMessage.isEmpty()) {
        m_errorMessage.clear();
        emit errorMessageChanged();
    }

    m_serverRunning = true;
    emit serverRunningChanged();

    qDebug() << "TCP server started";
}

void Backend::stopTcpServer()
{
    if (!m_serverRunning)
        return;

    m_tcpServer.stop();

    m_serverRunning = false;
    emit serverRunningChanged();

    qDebug() << "TCP server stopped";
}


// ======================
// mDNS Registration
// ======================

void Backend::registerOnMdns()
{
    if (m_registering)
        return;

    m_mdnsManager.registerService(
        m_deviceName,
        m_serviceType,
        m_port,
        m_deviceId,
        m_protocolVersion
        );

    m_registering = true;
    emit registeringChanged();
}

void Backend::stopRegistration()
{
    if (!m_registering)
        return;

    // If you later add this in MdnsManager:
    // m_mdnsManager.stopRegistration();

    m_registering = false;
    emit registeringChanged();
}


// ======================
// Router
// ======================

void Backend::handleIncomingMessage(QTcpSocket *client, const Message &msg)
{
    m_activeClient = client;
    m_router.route(client, msg);
}

void Backend::onClipboardReceived(const QString &text)
{
    m_clipboardModel.addClipboard(text);
}

void Backend::onMessageReceived(const QString &id,
                                const QString &address,
                                const QString &body,
                                bool isIncoming,
                                qint64 timestamp)
{
    m_messageModel.addMessage(id, address, body, isIncoming, timestamp);
}

void Backend::onFileReceived(const QString &transferId, const QString &fileName, qint64 totalBytes)
{
    m_sharedFilesModel.addFile(transferId, fileName, totalBytes);
}

// ======================
// System / Pairing
// ======================

void Backend::onHelloReceived(const QString &deviceId, const QString &deviceName)
{
    m_recentDeviceNames[deviceId] = deviceName;
    qDebug() << "[Backend] Hello from" << deviceName << "(" << deviceId << ")";
}

void Backend::onPairingRequested(const QString &deviceId)
{
    if (!m_activeClient)
    {
        qWarning() << "[Backend] Pairing requested with no active client";
        return;
    }

    if (isDeviceTrusted(deviceId))
    {
        // Already trusted: skip the PIN dance and accept immediately.
        QString deviceName = m_recentDeviceNames.value(deviceId, deviceId);
        m_router.systemHandler()->sendPairingAccepted(
            m_activeClient, m_deviceName, QSysInfo::productType());

        m_peerConnected = true;
        m_peerDeviceName = deviceName;
        emit peerConnectionChanged();
        return;
    }

    m_pairingPending = true;
    m_pairingDeviceId = deviceId;
    m_pairingDeviceName = m_recentDeviceNames.value(deviceId, deviceId);
    m_pairingPin = QString::number(QRandomGenerator::global()->bounded(100000, 1000000));

    qDebug() << "[Backend] Pairing PIN for" << m_pairingDeviceName << ":" << m_pairingPin;

    emit pairingPendingChanged();
}

void Backend::confirmPairing()
{
    if (!m_pairingPending || !m_activeClient)
        return;

    m_router.systemHandler()->sendPairingPin(m_activeClient, m_pairingPin);
    // Waiting for the phone to echo back pairing_accepted{} (see
    // onPairingAcceptedFromPhone), which finalizes trust.
}

void Backend::rejectPairing()
{
    if (!m_pairingPending || !m_activeClient)
        return;

    m_router.systemHandler()->sendPairingRejected(m_activeClient);

    m_pairingPending = false;
    m_pairingPin.clear();
    m_pairingDeviceId.clear();
    m_pairingDeviceName.clear();

    emit pairingPendingChanged();
}

void Backend::onPairingAcceptedFromPhone()
{
    if (!m_pairingPending || !m_activeClient)
    {
        qWarning() << "[Backend] pairing_accepted received with no pending pairing";
        return;
    }

    trustDevice(m_pairingDeviceId, m_pairingDeviceName);

    m_router.systemHandler()->sendPairingAccepted(
        m_activeClient, m_deviceName, QSysInfo::productType());

    qDebug() << "[Backend] Paired with" << m_pairingDeviceName;

    m_peerConnected = true;
    m_peerDeviceName = m_pairingDeviceName;
    emit peerConnectionChanged();

    m_pairingPending = false;
    m_pairingPin.clear();
    m_pairingDeviceId.clear();
    m_pairingDeviceName.clear();

    emit pairingPendingChanged();
}

bool Backend::isDeviceTrusted(const QString &deviceId) const
{
    QSettings settings;
    return settings.contains("TrustedDevices/" + deviceId);
}

void Backend::trustDevice(const QString &deviceId, const QString &deviceName)
{
    QSettings settings;
    settings.setValue("TrustedDevices/" + deviceId, deviceName);
}

void Backend::onNotificationPosted(const QString &notificationId,
                                    const QString &appName,
                                    const QString &title,
                                    const QString &text)
{
    // Native desktop notification display is intentionally out of scope
    // for now (see tasks.md); just log so the pipeline is verifiable.
    Q_UNUSED(notificationId);
    qDebug() << "[Backend] Notification from" << appName << "-" << title << ":" << text;
}

// Replies
void Backend::onDisconnected()
{
    qDebug()
    << "[Backend] Phone disconnected";

    if (m_pairingPending)
    {
        m_pairingPending = false;
        m_pairingPin.clear();
        m_pairingDeviceId.clear();
        m_pairingDeviceName.clear();
        emit pairingPendingChanged();
    }

    if (m_peerConnected)
    {
        m_peerConnected = false;
        m_peerDeviceName.clear();
        emit peerConnectionChanged();

        m_errorMessage = "Connection to phone was lost";
        emit errorMessageChanged();
    }

    m_activeClient = nullptr;
}