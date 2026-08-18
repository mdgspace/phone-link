#ifndef MESSAGE_H
#define MESSAGE_H

#include <QString>
#include <QJsonObject>

struct Message
{
    QString type;
    QString from;
    // Seconds since Unix epoch — matches Flutter's Packet default
    // (DateTime.now().millisecondsSinceEpoch ~/ 1000). Do not switch this
    // to milliseconds without updating dart:core/packet.dart in tandem.
    qint64 timestamp = 0;
    QJsonObject payload;
};

#endif // MESSAGE_H