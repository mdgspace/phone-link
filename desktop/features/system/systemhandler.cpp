#include "systemhandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>

void SystemHandler::handle(const Message &msg)
{
    if (msg.type == ProtocolTypes::SYSTEM_PING)
    {
        qDebug() << "[System] Ping received";
    }
    else if (msg.type == ProtocolTypes::SYSTEM_PONG)
    {
        qDebug() << "[System] Pong received";
    }
    else if (msg.type == ProtocolTypes::DEVICE_HELLO)
    {
        QString device = msg.payload["deviceName"].toString();

        qDebug() << "[System] Hello from device:" << device;
    }
    else if (msg.type == ProtocolTypes::DEVICE_HELLO_ACK)
    {
        qDebug() << "[System] Handshake acknowledged";
    }
}
