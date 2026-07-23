#include "clipboardhandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>

ClipboardHandler::ClipboardHandler(QObject *parent)
    : QObject(parent)
{
}

void ClipboardHandler::handle(const Message &msg)
{
    if (msg.type != ProtocolTypes::CLIPBOARD_PUSH)
    {
        return;
    }

    if (!msg.payload.contains("text"))
    {
        qWarning() << "[Clipboard] Invalid clipboard packet";
        return;
    }

    QString text = msg.payload.value("text").toString().trimmed();

    if (text.isEmpty())
    {
        qDebug() << "[Clipboard] Empty clipboard text";
        return;
    }

    qDebug() << "[Clipboard] Received:" << text;

    emit clipboardReceived(text);
}