#ifndef TCPSERVER_H
#define TCPSERVER_H

#include <QObject>
#include <QSslServer>
#include <QSslSocket>
#include <QSet>
#include <QHash>
#include "../protocol/message.h"

class TcpServer : public QObject
{
    Q_OBJECT

public:
    explicit TcpServer(QObject *parent = nullptr);
    bool start(quint16 port);
    void stop();

private slots:
    void onNewConnection();
    void onClientReadyRead();
    void onClientDisconnected();

private:
    QSslServer m_server;
    QSet<QSslSocket*> m_clients;
    QHash<QSslSocket*, QByteArray> m_buffers;

signals:
    void messageReceived(QTcpSocket *client, const Message &message);
};

#endif // TCPSERVER_H
