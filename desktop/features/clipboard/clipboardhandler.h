#ifndef CLIPBOARDHANDLER_H
#define CLIPBOARDHANDLER_H

#pragma once

#include <QObject>

#include "../../protocol/message.h"

class ClipboardHandler : public QObject
{
    Q_OBJECT

public:
    explicit ClipboardHandler(QObject *parent = nullptr);

    void handle(const Message &msg);

signals:
    void clipboardReceived(const QString &text);
};

#endif // CLIPBOARDHANDLER_H