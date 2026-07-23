#include "messaginghandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>

MessagingHandler::MessagingHandler(QObject *parent)
    : QObject(parent)
{
}

void MessagingHandler::handle(const Message &msg)
{
    // Only handle live SMS packets
    if (msg.type != ProtocolTypes::SMS_SEND &&
        msg.type != ProtocolTypes::SMS_RECEIVED)
    {
        return;
    }

    // Validate payload
    if (!msg.payload.contains("id") ||
        !msg.payload.contains("address") ||
        !msg.payload.contains("body") ||
        !msg.payload.contains("isIncoming") ||
        !msg.payload.contains("timestamp"))
    {
        qWarning() << "[Messaging] Invalid SMS packet";
        return;
    }

    QString id =
        msg.payload.value("id").toString();

    QString address =
        msg.payload.value("address").toString();

    QString body =
        msg.payload.value("body").toString();

    bool isIncoming =
        msg.payload.value("isIncoming").toBool();

    qint64 timestamp =
        msg.payload.value("timestamp").toInteger();

    qDebug() << "[Messaging]"
             << (isIncoming ? "Incoming" : "Outgoing")
             << "Address:" << address
             << "Body:" << body;

    emit messageReceived(
        id,
        address,
        body,
        isIncoming,
        timestamp);
}