#include "tcpserver.h"
#include "protocol.h"
#include "../protocol/messageparser.h"

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

bool TcpServer::start(quint16 port)
{
    bool ok = m_server.listen(QHostAddress::Any, port);

    if (!ok) {
        qWarning() << "TCP server failed to start:" << m_server.errorString();
        return false;
    }

    qDebug() << "TCP server listening on"
             << m_server.serverAddress() << " : "
             << m_server.serverPort();

    return true;
}

void TcpServer::stop()
{
    if (!m_server.isListening()) {
        qDebug() << "TCP server already stopped";
        return;
    }

    // Disconnect all clients
    for (QTcpSocket *client : std::as_const(m_clients)) {
        if (client->state() == QAbstractSocket::ConnectedState) {
            client->disconnectFromHost();
        }
        client->deleteLater();
    }

    m_clients.clear();
    m_buffers.clear();

    // Stop listening
    m_server.close();

    qDebug() << "TCP server stopped listening";
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

// read bytes - split into complete packets - parse the packet - emit the parsed message
void TcpServer::onClientReadyRead()
{
    auto *client = qobject_cast<QTcpSocket*>(sender());
    if (!client)
        return;

    // Append incoming bytes to this client's buffer
    m_buffers[client].append(client->readAll());

    // Process complete newline-delimited messages
    while (true) {
        int newlineIndex = m_buffers[client].indexOf('\n');
        if (newlineIndex == -1)
            break;

        QByteArray line = m_buffers[client].left(newlineIndex).trimmed();
        m_buffers[client].remove(0, newlineIndex + 1);

        if (line.isEmpty())
            continue;

        qDebug() << "Received from"
                 << client->peerAddress().toString()
                 << ":" << line;

        Message msg = MessageParser::parse(line);
        if (msg.type.isEmpty()) {
            qWarning() << "Invalid packet:" << line;
            continue;
        }

        emit messageReceived(client, msg);
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
