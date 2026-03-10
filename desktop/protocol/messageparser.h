#ifndef MESSAGEPARSER_H
#define MESSAGEPARSER_H
#include "message.h"
#include <QByteArray>

class MessageParser
{
public:
    static Message parse(const QByteArray &data);
};

#endif // MESSAGEPARSER_H
