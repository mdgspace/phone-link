#include "tcpserver.h"
#include "protocol.h"
#include "../protocol/messageparser.h"

#include <QFile>
#include <QHostAddress>
#include <QDebug>
#include <QSslConfiguration>
#include <QSslCertificate>
#include <QSslKey>

TcpServer::TcpServer(QObject *parent)
    : QObject{parent}
{
    connect(&m_server,
            &QSslServer::pendingConnectionAvailable,
            this,
            &TcpServer::onNewConnection);

    connect(&m_server,
            &QSslServer::errorOccurred,
            this,
            [](QSslSocket *socket, QAbstractSocket::SocketError error) {
                qWarning() << "[TLS] handshake/socket error on"
                           << (socket ? socket->peerAddress().toString() : QString("<unknown>"))
                           << error
                           << (socket ? socket->errorString() : QString());
            });
}

bool TcpServer::start(quint16 port)
{
    QFile certFile(":/tls/server.crt");
    QFile keyFile(":/tls/server.key");

    if (!certFile.open(QIODevice::ReadOnly) || !keyFile.open(QIODevice::ReadOnly)) {
        qWarning() << "[TLS] Could not load embedded server certificate/key";
        return false;
    }

    const QSslCertificate certificate(certFile.readAll(), QSsl::Pem);
    const QSslKey privateKey(keyFile.readAll(), QSsl::Rsa, QSsl::Pem);

    if (certificate.isNull() || privateKey.isNull()) {
        qWarning() << "[TLS] Invalid server certificate or private key";
        return false;
    }

    QSslConfiguration configuration = QSslConfiguration::defaultServerConfiguration();
    configuration.setLocalCertificate(certificate);
    configuration.setPrivateKey(privateKey);
    configuration.setPeerVerifyMode(QSslSocket::VerifyNone);
    configuration.setProtocol(QSsl::TlsV1_3OrLater);

    m_server.setSslConfiguration(configuration);
    m_server.setHandshakeTimeout(6000);

    if (!m_server.listen(QHostAddress::Any, port)) {
        qWarning() << "TLS server failed to start:" << m_server.errorString();
        return false;
    }

    qDebug() << "TLS TCP server listening on"
             << m_server.serverAddress() << ":" << m_server.serverPort();

    return true;
}

void TcpServer::stop()
{
    for (QSslSocket *client : std::as_const(m_clients)) {
        client->disconnect(this);
        if (client->state() == QAbstractSocket::ConnectedState)
            client->disconnectFromHost();
        client->deleteLater();
    }

    m_clients.clear();
    m_buffers.clear();
    m_server.close();

    qDebug() << "TLS TCP server stopped";
}

void TcpServer::onNewConnection()
{
    while (m_server.hasPendingConnections()) {
        auto *client = qobject_cast<QSslSocket*>(m_server.nextPendingConnection());
        if (!client)
            continue;

        qDebug() << "TLS client connected:"
                 << client->peerAddress() << ":" << client->peerPort();

        m_clients.insert(client);
        m_buffers.insert(client, QByteArray());

        connect(client, &QSslSocket::readyRead,
                this, &TcpServer::onClientReadyRead);
        connect(client, &QSslSocket::disconnected,
                this, &TcpServer::onClientDisconnected);
        connect(client, &QSslSocket::sslErrors,
                this, [](const QList<QSslError> &errors) {
                    for (const auto &error : errors)
                        qWarning() << "[TLS]" << error.errorString();
                });
    }
}

void TcpServer::onClientReadyRead()
{
    auto *client = qobject_cast<QSslSocket*>(sender());
    if (!client)
        return;

    m_buffers[client].append(client->readAll());

    while (true) {
        const int newlineIndex = m_buffers[client].indexOf('\n');
        if (newlineIndex == -1)
            break;

        const QByteArray line = m_buffers[client].left(newlineIndex).trimmed();
        m_buffers[client].remove(0, newlineIndex + 1);

        if (line.isEmpty())
            continue;

        qDebug() << "Received over TLS from"
                 << client->peerAddress().toString() << ":" << line;

        const Message msg = MessageParser::parse(line);
        if (msg.type.isEmpty()) {
            qWarning() << "Invalid packet:" << line;
            continue;
        }

        emit messageReceived(client, msg);
    }
}

void TcpServer::onClientDisconnected()
{
    auto *client = qobject_cast<QSslSocket*>(sender());
    if (!client)
        return;

    qDebug() << "TLS client disconnected:" << client->peerAddress().toString();

    m_clients.remove(client);
    m_buffers.remove(client);
    client->deleteLater();
}
