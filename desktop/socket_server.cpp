#include "socket_server.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QHostAddress>

SocketServer::SocketServer(QObject *parent)
    : QObject(parent), m_server(new QTcpServer(this))
{
    connect(m_server, &QTcpServer::newConnection, this, &SocketServer::onNewConnection);
}

SocketServer::~SocketServer()
{
    stop();
}

bool SocketServer::start(quint16 port)
{
    if (m_server->isListening()) {
        stop();
    }

    // Listen on all network interfaces
    if (!m_server->listen(QHostAddress::Any, port)) {
        qCritical() << "Failed to start TCP server:" << m_server->errorString();
        return false;
    }

    qDebug() << "TCP Server listening on port:" << m_server->serverPort();
    return true;
}

void SocketServer::stop()
{
    if (m_server->isListening()) {
        m_server->close();
        qDebug() << "TCP Server stopped.";
    }
    
    for (QTcpSocket *client : m_clients) {
        client->disconnectFromHost();
    }
    m_clients.clear();
}

quint16 SocketServer::serverPort() const
{
    return m_server->serverPort();
}

void SocketServer::onNewConnection()
{
    while (m_server->hasPendingConnections()) {
        QTcpSocket *client = m_server->nextPendingConnection();
        connect(client, &QTcpSocket::readyRead, this, &SocketServer::onReadyRead);
        connect(client, &QTcpSocket::disconnected, this, &SocketServer::onDisconnected);
        m_clients.append(client);
        qDebug() << "New client connected from:" << client->peerAddress().toString();
    }
}

void SocketServer::onReadyRead()
{
    QTcpSocket *client = qobject_cast<QTcpSocket *>(sender());
    if (!client) return;

    // Read line-by-line using the newline delimiter sent by Flutter
    while (client->canReadLine()) {
        QByteArray data = client->readLine().trimmed();
        if (data.isEmpty()) continue;

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(data, &error);

        if (error.error != QJsonParseError::NoError) {
            qWarning() << "Failed to parse JSON payload:" << error.errorString();
            continue;
        }

        if (doc.isObject()) {
            emit notificationReceived(doc.object());
        } else {
            qWarning() << "Received JSON is not an object.";
        }
    }
}

void SocketServer::onDisconnected()
{
    QTcpSocket *client = qobject_cast<QTcpSocket *>(sender());
    if (!client) return;

    qDebug() << "Client disconnected:" << client->peerAddress().toString();
    m_clients.removeOne(client);
    client->deleteLater();
}