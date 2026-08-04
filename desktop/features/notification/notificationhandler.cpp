#include "notificationhandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>

NotificationHandler::NotificationHandler(QObject *parent)
    : QObject(parent)
{
}

void NotificationHandler::handle(QTcpSocket *client, const Message &msg)
{
    Q_UNUSED(client);

    if (msg.type == ProtocolTypes::NOTIFICATION_POSTED)
    {
        if (!msg.payload.contains("notification_id"))
        {
            qWarning() << "[Notification] Invalid notification_posted packet";
            return;
        }

        QString notificationId = msg.payload.value("notification_id").toString();
        QString appName = msg.payload.value("app_name").toString();
        QString title = msg.payload.value("title").toString();
        QString text = msg.payload.value("text").toString();

        qDebug() << "[Notification] Posted:" << appName << "-" << title;

        emit notificationPosted(notificationId, appName, title, text);
    }
    else if (msg.type == ProtocolTypes::NOTIFICATION_DISMISSED)
    {
        if (!msg.payload.contains("notification_id"))
        {
            qWarning() << "[Notification] Invalid notification_dismissed packet";
            return;
        }

        QString notificationId = msg.payload.value("notification_id").toString();

        qDebug() << "[Notification] Dismissed:" << notificationId;

        emit notificationDismissed(notificationId);
    }
}
