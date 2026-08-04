#include "systemhandler.h"

#include "../../protocol/protocoltypes.h"
#include "../../protocol/messageparser.h"

#include <QDebug>
#include <QTcpSocket>

SystemHandler::SystemHandler(QObject *parent)
    : QObject(parent)
{
}

void SystemHandler::sendPairingPin(QTcpSocket *client, const QString &pin)
{
    Message reply;
    reply.type = ProtocolTypes::PAIRING_PIN;
    reply.payload["pin"] = pin;
    MessageParser::send(client, reply);
}

void SystemHandler::sendPairingAccepted(QTcpSocket *client,
                                         const QString &deviceName,
                                         const QString &platform)
{
    Message reply;
    reply.type = ProtocolTypes::PAIRING_ACCEPTED;
    reply.payload["device_name"] = deviceName;
    reply.payload["platform"] = platform;
    MessageParser::send(client, reply);
}

void SystemHandler::sendPairingRejected(QTcpSocket *client)
{
    Message reply;
    reply.type = ProtocolTypes::PAIRING_REJECTED;
    MessageParser::send(client, reply);
}

void SystemHandler::handle(QTcpSocket *client, const Message &msg)
{
    if (msg.type == ProtocolTypes::HELLO)
    {
        if (!msg.payload.contains("device_id") ||
            !msg.payload.contains("device_name"))
        {
            qWarning() << "[System] Invalid hello packet";
            return;
        }

        QString deviceId =
            msg.payload.value("device_id").toString();

        QString deviceName =
            msg.payload.value("device_name").toString();

        qDebug() << "[System] Hello from"
                 << deviceName
                 << "(" << deviceId << ")";

        emit helloReceived(deviceId, deviceName);

        // Send hello acknowledgement
        Message reply;
        reply.type = ProtocolTypes::HELLO_ACK;

        reply.payload["device_id"] = "desktop";
        reply.payload["device_name"] = "Ava's Dell Laptop";

        MessageParser::send(client, reply);
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

        // Send heartbeat acknowledgement
        Message reply;
        reply.type = ProtocolTypes::HEARTBEAT_ACK;

        MessageParser::send(client, reply);
    }

    else if (msg.type == ProtocolTypes::HEARTBEAT_ACK)
    {
        qDebug() << "[System] Heartbeat acknowledged";

        emit heartbeatAcknowledged();
    }

    else if (msg.type == ProtocolTypes::PAIRING_REQUEST)
    {
        if (!msg.payload.contains("device_id"))
        {
            qWarning() << "[System] Invalid pairing request";
            return;
        }

        QString deviceId =
            msg.payload.value("device_id").toString();

        qDebug() << "[System] Pairing request from"
                 << deviceId;

        emit pairingRequested(deviceId);
    }

    else if (msg.type == ProtocolTypes::PAIRING_PIN)
    {
        if (!msg.payload.contains("pin"))
        {
            qWarning() << "[System] Invalid pairing PIN";
            return;
        }

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

    else
    {
        qWarning() << "[System] Unknown packet type:"
                   << msg.type;
    }
}