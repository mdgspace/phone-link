#ifndef SOCKET_SERVER_H
#define SOCKET_SERVER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonObject>
#include <QList>

class SocketServer : public QObject
{
    Q_OBJECT
public:
    explicit SocketServer(QObject *parent = nullptr);
    ~SocketServer();

    /// Starts the TCP server on the specified port.
    /// If port is 0, a random available port is chosen automatically.
    bool start(quint16 port = 0);
    void stop();
    
    /// Returns the port the server is actively listening on.
    quint16 serverPort() const;

signals:
    void notificationReceived(const QJsonObject &payload);

private slots:
    void onNewConnection();
    void onReadyRead();
    void onDisconnected();

private:
    QTcpServer *m_server;
    QList<QTcpSocket *> m_clients;
};

#endif // SOCKET_SERVER_H