#ifndef NOTIFICATIONHANDLER_H
#define NOTIFICATIONHANDLER_H

#pragma once

#include <QObject>
#include <QTcpSocket>

#include "../../protocol/message.h"

// Scope note: native desktop notification display is not implemented yet
// (see tasks.md). This handler parses/validates incoming notification
// packets and exposes them via signals so a future NotificationModel /
// OS notification bridge can consume them without changing the wire
// protocol or MessageRouter.
class NotificationHandler : public QObject
{
    Q_OBJECT

public:
    explicit NotificationHandler(QObject *parent = nullptr);

    void handle(QTcpSocket *client, const Message &msg);

signals:
    void notificationPosted(const QString &notificationId,
                             const QString &appName,
                             const QString &title,
                             const QString &text);

    void notificationDismissed(const QString &notificationId);
};

#endif // NOTIFICATIONHANDLER_H
