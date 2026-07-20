#ifndef MESSAGINGHANDLER_H
#define MESSAGINGHANDLER_H

#include <QObject>
#include "../../protocol/message.h"

class MessagingHandler : public QObject
{
    Q_OBJECT

public:
    explicit MessagingHandler(QObject *parent = nullptr);

    void handle(const Message &msg);

signals:
    void messageReceived(const QString &id,
                         const QString &address,
                         const QString &body,
                         bool isIncoming,
                         qint64 timestamp);
};

#endif // MESSAGINGHANDLER_H