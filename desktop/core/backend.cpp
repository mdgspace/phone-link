#include "backend.h"
#include "../protocol/messageparser.h"
#include <QThread>
#include <QDebug>

Backend::Backend(QObject *parent)
    : QObject(parent)
{
    qDebug() << "[Backend] constructor";
    qDebug() << "[Backend] thread:" << QThread::currentThread();

    // connect signals and slots
    connect(&m_clipboardHandler,
            &ClipboardHandler::clipboardReceived,
            this,
            &Backend::onClipboardReceived);

    connect(&m_messageHandler,
            &MessagingHandler::messageReceived,
            this,
            &Backend::onMessageReceived);

    connect(&m_fileHandler,
            &FileTransferHandler::fileReceived,
            this,
            &Backend::onFileReceived);

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
        qWarning() << "Failed to start TCP server";
        return;
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
        m_port
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

void Backend::handleIncomingMessage(QTcpSocket *client, const QByteArray &data)
{
    Message msg = MessageParser::parse(data);
    m_router.route(msg);
}

void Backend::onClipboardReceived(const QString &text)
{
    m_clipboardModel.addClipboard(text);
}

void Backend::onMessageReceived(const QString &sender, const QString &text)
{
    m_messageModel.addMessage(sender, text);
}

void Backend::onFileReceived(const QString &path)
{
    m_sharedFilesModel.addFile(path);
}
