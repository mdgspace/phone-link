#ifndef CLIPBOARDHANDLER_H
#define CLIPBOARDHANDLER_H

#pragma once

#include <QObject>
#include <QTcpSocket>

#include "../../protocol/message.h"

class ClipboardHandler : public QObject
{
    Q_OBJECT

public:
    explicit ClipboardHandler(QObject *parent = nullptr);

    void handle(QTcpSocket *client, const Message &msg);

signals:
    void clipboardReceived(const QString &text);
};

#endif // CLIPBOARDHANDLER_H