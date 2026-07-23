#ifndef SYSTEMHANDLER_H
#define SYSTEMHANDLER_H

#pragma once

#include <QObject>

#include "../../protocol/message.h"

class SystemHandler : public QObject
{
    Q_OBJECT

public:
    explicit SystemHandler(QObject *parent = nullptr);

    void handle(const Message &msg);

signals:
    void helloReceived(const QString &deviceId,
                       const QString &deviceName);

    void helloAcknowledged();

    void heartbeatReceived();

    void heartbeatAcknowledged();

    void pairingRequested(const QString &deviceId);

    void pairingPinReceived(const QString &pin);

    void pairingAccepted();

    void pairingRejected();

    void disconnected();
};

#endif // SYSTEMHANDLER_H