#ifndef SYSTEMHANDLER_H
#define SYSTEMHANDLER_H

#pragma once

#include <QObject>
#include <QTcpSocket>

#include "../../protocol/message.h"

class SystemHandler : public QObject
{
    Q_OBJECT

public:
    explicit SystemHandler(QObject *parent = nullptr);

    // Real local identity, used in hello_ack / pairing_accepted replies
    // instead of hardcoded placeholder values.
    void setLocalDevice(const QString &deviceId, const QString &deviceName);

    void handle(QTcpSocket *client, const Message &msg);

    // Sent once the desktop user confirms the PIN shown in the pairing dialog.
    void sendPairingPin(QTcpSocket *client, const QString &pin);

    // Sent after the phone echoes pairing_accepted{} and the device has
    // been persisted as trusted.
    void sendPairingAccepted(QTcpSocket *client,
                              const QString &deviceName,
                              const QString &platform);

    // Sent if the desktop user declines the incoming pairing request.
    void sendPairingRejected(QTcpSocket *client);

signals:
    void helloReceived(const QString &deviceId,
                       const QString &deviceName);

    void helloAcknowledged();

    void heartbeatReceived();

    void heartbeatAcknowledged();

    void pairingRequested(const QString &deviceId, const QString &pin);

    void pairingPinReceived(const QString &pin);

    void pairingAccepted();

    void pairingRejected();

    void disconnected();

private:
    QString m_localDeviceId;
    QString m_localDeviceName;
};

#endif // SYSTEMHANDLER_H