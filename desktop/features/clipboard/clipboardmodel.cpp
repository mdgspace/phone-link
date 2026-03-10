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

    if (role == TextRole)
        return m_items[index.row()];

    return {};
}

QHash<int, QByteArray> ClipboardModel::roleNames() const
{
    return {
        {TextRole, "text"}
    };
}

void ClipboardModel::addClipboard(const QString &text)
{
    beginInsertRows({}, m_items.size(), m_items.size());
    m_items.append(text);
    endInsertRows();
}
