#include "messageparser.h"

#include <QJsonDocument>
#include <QJsonObject>

Message MessageParser::parse(const QByteArray &data)
{
    Message msg;

    QJsonDocument doc = QJsonDocument::fromJson(data);

    if (!doc.isObject())
        return msg;

    QJsonObject obj = doc.object();

    msg.type = obj["type"].toString();
    msg.payload = obj["payload"].toObject();

    return msg;
}
