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
        // Flutter sends the Android StatusBarNotification fields:
        // key, app_package, app_name, title, text, posted_at.
        // Older desktop code expected notification_id, which caused every
        // valid phone notification to be rejected as "Invalid".
        QString notificationId =
            msg.payload.value("notification_id").toString();

        if (notificationId.isEmpty())
            notificationId = msg.payload.value("key").toString();

        if (notificationId.isEmpty())
        {
            qWarning() << "[Notification] Invalid notification_posted packet:"
                       << msg.payload;
            return;
        }

        const QString appName =
            msg.payload.value("app_name").toString();
        const QString title =
            msg.payload.value("title").toString();
        const QString text =
            msg.payload.value("text").toString();

        qDebug() << "[Notification] Posted:"
                 << appName << "-" << title;

        emit notificationPosted(notificationId, appName, title, text);
    }
    else if (msg.type == ProtocolTypes::NOTIFICATION_DISMISSED)
    {
        QString notificationId =
            msg.payload.value("notification_id").toString();

        if (notificationId.isEmpty())
            notificationId = msg.payload.value("key").toString();

        if (notificationId.isEmpty())
        {
            qWarning() << "[Notification] Invalid notification_dismissed packet:"
                       << msg.payload;
            return;
        }

        qDebug() << "[Notification] Dismissed:" << notificationId;
        emit notificationDismissed(notificationId);
    }
}
