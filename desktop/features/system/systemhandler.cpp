#include "systemhandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>

SystemHandler::SystemHandler(QObject *parent)
    : QObject(parent)
{
}

void SystemHandler::handle(const Message &msg)
{
    if (msg.type == ProtocolTypes::HELLO)
    {
        QString deviceId =
            msg.payload.value("device_id").toString();

        QString deviceName =
            msg.payload.value("device_name").toString();

        qDebug() << "[System] Hello from"
                 << deviceName
                 << "(" << deviceId << ")";

        emit helloReceived(deviceId, deviceName);
    }

    else if (msg.type == ProtocolTypes::HELLO_ACK)
    {
        qDebug() << "[System] Hello acknowledged";

        emit helloAcknowledged();
    }

    else if (msg.type == ProtocolTypes::HEARTBEAT)
    {
        qDebug() << "[System] Heartbeat";

        emit heartbeatReceived();
    }

    else if (msg.type == ProtocolTypes::HEARTBEAT_ACK)
    {
        qDebug() << "[System] Heartbeat acknowledged";

        emit heartbeatAcknowledged();
    }

    else if (msg.type == ProtocolTypes::PAIRING_REQUEST)
    {
        QString deviceId =
            msg.payload.value("device_id").toString();

        qDebug() << "[System] Pairing request from"
                 << deviceId;

        emit pairingRequested(deviceId);
    }

    else if (msg.type == ProtocolTypes::PAIRING_PIN)
    {
        QString pin =
            msg.payload.value("pin").toString();

        qDebug() << "[System] Pairing PIN:" << pin;

        emit pairingPinReceived(pin);
    }

    else if (msg.type == ProtocolTypes::PAIRING_ACCEPTED)
    {
        qDebug() << "[System] Pairing accepted";

        emit pairingAccepted();
    }

    else if (msg.type == ProtocolTypes::PAIRING_REJECTED)
    {
        qDebug() << "[System] Pairing rejected";

        emit pairingRejected();
    }

    else if (msg.type == ProtocolTypes::DISCONNECT)
    {
        qDebug() << "[System] Device disconnected";

        emit disconnected();
    }
}