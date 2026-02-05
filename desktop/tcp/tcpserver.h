#ifndef TCPSERVER_H
#define TCPSERVER_H

#include <QObject>
#include <QTcpServer>
#include <QTcpSocket>
#include <QSet>
#include <QHash>

class TcpServer : public QObject
{
    Q_OBJECT

public:
    explicit TcpServer(QObject *parent = nullptr);
    bool start();

private slots:
    void onNewConnection();
    void onClientReadyRead();
    void onClientDisconnected();

private:
    QTcpServer m_server;
    QSet<QTcpSocket*> m_clients;                // track connected clients
    QHash<QTcpSocket*, QByteArray> m_buffers;   // per client receive buffers

signals:
};

#endif // TCPSERVER_H
