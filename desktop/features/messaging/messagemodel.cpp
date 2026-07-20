#include "messagemodel.h"

MessageModel::MessageModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int MessageModel::rowCount(const QModelIndex &) const
{
    return m_items.size();
}

QVariant MessageModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};

    const MessageItem &msg = m_items.at(index.row());

    switch (role)
    {
    case IdRole:
        return msg.id;

    case AddressRole:
        return msg.address;

    case BodyRole:
        return msg.body;

    case IncomingRole:
        return msg.isIncoming;

    case TimestampRole:
        return msg.timestamp;

    default:
        return {};
    }
}

QHash<int, QByteArray> MessageModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {AddressRole, "address"},
        {BodyRole, "body"},
        {IncomingRole, "isIncoming"},
        {TimestampRole, "timestamp"}
    };
}

void MessageModel::addMessage(const QString &id,
                              const QString &address,
                              const QString &body,
                              bool isIncoming,
                              qint64 timestamp)
{
    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());

    MessageItem item;
    item.id = id;
    item.address = address;
    item.body = body;
    item.isIncoming = isIncoming;
    item.timestamp = timestamp;

    m_items.append(item);

    endInsertRows();
}