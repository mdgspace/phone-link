#ifndef MESSAGINGHANDLER_H
#define MESSAGINGHANDLER_H

#include "protocol/message.h"

class MessagingHandler : public QObject
{
    Q_OBJECT

public:
    explicit MessagingHandler(QObject *parent = nullptr);

    void handle(const Message &msg);

signals:
    void messageReceived(const QString &sender, const QString &text);
};

#endif // MESSAGINGHANDLER_H
