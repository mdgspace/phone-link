#include "clipboardhandler.h"
#include <QDebug>

ClipboardHandler::ClipboardHandler(QObject *parent)
    : QObject(parent)
{
}

void ClipboardHandler::handle(const Message &msg)
{
    QString text = msg.payload["text"].toString();
    qDebug() << "[Clipboard] Received text:" << text;

    emit clipboardReceived(text);
}
