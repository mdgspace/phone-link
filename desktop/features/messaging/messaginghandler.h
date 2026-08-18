#ifndef MESSAGINGHANDLER_H
#define MESSAGINGHANDLER_H

#pragma once

#include <QObject>
#include <QTcpSocket>

#include "../../protocol/message.h"

class MessagingHandler : public QObject
{
    Q_OBJECT

public:
    explicit MessagingHandler(QObject *parent = nullptr);

    void handle(QTcpSocket *client, const Message &msg);

signals:
    void messageReceived(const QString &id,
                         const QString &address,
                         const QString &body,
                         bool isIncoming,
                         qint64 timestamp);
};

#endif // MESSAGINGHANDLER_H