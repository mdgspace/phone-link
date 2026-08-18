#include "notificationmodel.h"

NotificationModel::NotificationModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int NotificationModel::rowCount(const QModelIndex &) const
{
    return m_items.size();
}

QVariant NotificationModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
        return {};

    const auto &item = m_items.at(index.row());

    switch (role)
    {
    case IdRole:          return item.id;
    case AppPackageRole:  return item.appPackage;
    case AppNameRole:     return item.appName;
    case TitleRole:       return item.title;
    case TextRole:        return item.text;
    case PostedAtRole:    return item.postedAt;
    default:              return {};
    }
}

QHash<int, QByteArray> NotificationModel::roleNames() const
{
    return {
        {IdRole, "notificationId"},
        {AppPackageRole, "appPackage"},
        {AppNameRole, "appName"},
        {TitleRole, "title"},
        {TextRole, "text"},
        {PostedAtRole, "postedAt"}
    };
}

void NotificationModel::addOrUpdateNotification(const QString &id,
                                                 const QString &appPackage,
                                                 const QString &appName,
                                                 const QString &title,
                                                 const QString &text,
                                                 qint64 postedAt)
{
    // Android notification keys identify a notification across updates.
    // Replace an existing item instead of creating duplicates.
    for (int i = 0; i < m_items.size(); ++i)
    {
        if (m_items[i].id == id)
        {
            m_items[i].appPackage = appPackage;
            m_items[i].appName = appName;
            m_items[i].title = title;
            m_items[i].text = text;
            m_items[i].postedAt = postedAt;

            emit dataChanged(index(i), index(i));
            return;
        }
    }

    const int row = m_items.size();
    beginInsertRows(QModelIndex(), row, row);

    NotificationItem item;
    item.id = id;
    item.appPackage = appPackage;
    item.appName = appName;
    item.title = title;
    item.text = text;
    item.postedAt = postedAt;
    m_items.append(item);

    endInsertRows();

    // Keep the desktop list bounded.
    while (m_items.size() > 200)
    {
        beginRemoveRows(QModelIndex(), m_items.size() - 1, m_items.size() - 1);
        m_items.removeLast();
        endRemoveRows();
    }
}

void NotificationModel::removeNotification(const QString &id)
{
    for (int i = 0; i < m_items.size(); ++i)
    {
        if (m_items[i].id == id)
        {
            beginRemoveRows(QModelIndex(), i, i);
            m_items.removeAt(i);
            endRemoveRows();
            return;
        }
    }
}
