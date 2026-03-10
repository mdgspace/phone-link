#pragma once

#include <QString>
#include <QJsonObject>

struct Message
{
    QString type;
    QJsonObject payload;
};
