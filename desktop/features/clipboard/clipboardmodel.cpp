#include "clipboardmodel.h"

ClipboardModel::ClipboardModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ClipboardModel::rowCount(const QModelIndex &) const
{
    return m_items.size();
}

QVariant ClipboardModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};

    const ClipboardItem &item = m_items.at(index.row());

    switch (role)
    {
    case TextRole:
        return item.text;

    default:
        return {};
    }
}

QHash<int, QByteArray> ClipboardModel::roleNames() const
{
    return {
        {TextRole, "text"}
    };
}

void ClipboardModel::addClipboard(const QString &text)
{
    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());

    ClipboardItem item;
    item.text = text;

    m_items.append(item);

    endInsertRows();
}