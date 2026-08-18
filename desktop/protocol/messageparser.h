#ifndef MESSAGEPARSER_H
#define MESSAGEPARSER_H

#include "message.h"
#include <QByteArray>

class QTcpSocket;

class MessageParser
{
public:
    static Message parse(const QByteArray &data);

    static QByteArray serialize(const Message &msg);

    static void send(QTcpSocket *client, const Message &msg);
};

#endif // MESSAGEPARSER_H