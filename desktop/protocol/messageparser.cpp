#include "messageparser.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>

Message MessageParser::parse(const QByteArray &data)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);

    if (err.error != QJsonParseError::NoError)
        return {};

    if (!doc.isObject())
        return {};

    QJsonObject obj = doc.object();

    if (!obj.contains("type") || !obj["type"].isString())
        return {};

    if (!obj.contains("payload") || !obj["payload"].isObject())
        return {};

    Message msg;

    msg.type = obj["type"].toString();
    msg.payload = obj["payload"].toObject();

    // Optional metadata
    if (obj.contains("from") && obj["from"].isString())
        msg.from = obj["from"].toString();

    if (obj.contains("timestamp"))
        msg.timestamp = obj["timestamp"].toInteger();

    return msg;
}