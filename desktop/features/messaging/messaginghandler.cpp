#include "messaginghandler.h"

#include <QDebug>

MessagingHandler::MessagingHandler(QObject *parent)
    : QObject(parent)
{
}

void MessagingHandler::handle(const Message &msg)
{
    QString text = msg.payload["text"].toString();
    QString sender = msg.payload["sender"].toString();

    qDebug() << "[Message] From:" << sender;
    qDebug() << "[Message] Content:" << text;

    emit messageReceived(sender, text);
}
