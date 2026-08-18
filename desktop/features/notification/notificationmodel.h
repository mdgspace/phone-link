#ifndef NOTIFICATIONMODEL_H
#define NOTIFICATIONMODEL_H

#include <QAbstractListModel>
#include <QString>

struct NotificationItem
{
    QString id;
    QString appPackage;
    QString appName;
    QString title;
    QString text;
    qint64 postedAt = 0;
};

class NotificationModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        AppPackageRole,
        AppNameRole,
        TitleRole,
        TextRole,
        PostedAtRole
    };

    explicit NotificationModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addOrUpdateNotification(const QString &id,
                                 const QString &appPackage,
                                 const QString &appName,
                                 const QString &title,
                                 const QString &text,
                                 qint64 postedAt);

    void removeNotification(const QString &id);

private:
    QList<NotificationItem> m_items;
};

#endif
