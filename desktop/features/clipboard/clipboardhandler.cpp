#include "clipboardhandler.h"

#include <QDebug>
#include <QJsonObject>

ClipboardHandler::ClipboardHandler(QObject *parent)
    : QObject(parent)
{
}

void ClipboardHandler::handle(const Message &msg)
{
    if (!msg.payload.contains("text")) {
        qWarning() << "[Clipboard] Invalid clipboard packet";
        return;
    }

    QString text = msg.payload.value("text").toString();

    if (text.isEmpty())
        return;

    qDebug() << "[Clipboard] Received text:" << text;

    emit clipboardReceived(text);
}