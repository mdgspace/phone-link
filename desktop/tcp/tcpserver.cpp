#include "tcpserver.h"
#include "protocol.h"

#include <QHostAddress>
#include <QDebug>

TcpServer::TcpServer(QObject *parent)
    : QObject{parent}
{
    connect(&m_server,
            &QTcpServer::newConnection,
            this,
            &TcpServer::onNewConnection);
}

bool TcpServer::start()
{
    bool ok = m_server.listen(QHostAddress::Any, TCP_SERVER_PORT);

    if (!ok) {
        qWarning() << "TCP server failed to start:" << m_server.errorString();
        return false;
    }

    qDebug() << "TCP server listening on"
             << m_server.serverAddress() << " : "
             << m_server.serverPort();

    return true;
}

void TcpServer::onNewConnection()
{
    while (m_server.hasPendingConnections()) {
        QTcpSocket *client = m_server.nextPendingConnection();

        qDebug() << "Client connected: "
                 << client->peerAddress() << " : "
                 << client->peerPort();

        m_clients.insert(client);
        m_buffers.insert(client, QByteArray());

        connect(client, &QTcpSocket::readyRead, this, &TcpServer::onClientReadyRead);
        connect(client, &QTcpSocket::disconnected, this, &TcpServer::onClientDisconnected);

        client->write("WELCOME\n");
    }
}

void TcpServer::onClientReadyRead()
{
    auto *client = qobject_cast<QTcpSocket*>(sender());
    if (!client) return;

    // Append incoming data to this client's buffer
    m_buffers[client].append(client->readAll());

    // Line based protocol
    while (true) {
        int newlineIndex = m_buffers[client].indexOf('\n');
        if (newlineIndex == -1) break;

        QByteArray line = m_buffers[client].left(newlineIndex);
        m_buffers[client].remove(0, newlineIndex + 1);

        qDebug() << "From" << client->peerAddress().toString()
                 << " : " << line;

        // Protocol Handling
        if (line == Protocol::PING) {
            client->write("PONG\n");
        } else {
            client->write("ECHO: " + line + "\n");
        }
    }
}

void TcpServer::onClientDisconnected()
{
    auto *client = qobject_cast<QTcpSocket*>(sender());
    if (!client) return;

    qDebug() << "Client disconnected:" << client->peerAddress().toString()
             << " : " << client->peerPort();

    m_clients.remove(client);
    m_buffers.remove(client);

    client->deleteLater();
}
