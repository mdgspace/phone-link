#ifndef MESSAGE_H
#define MESSAGE_H

#include <QString>
#include <QJsonObject>

struct Message
{
    QString type;
    QString from;
    qint64 timestamp = 0;
    QJsonObject payload;
};

#endif // MESSAGE_H