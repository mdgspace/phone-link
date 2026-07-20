#ifndef MESSAGEMODEL_H
#define MESSAGEMODEL_H

#include <QAbstractListModel>
#include <QObject>

struct MessageItem
{
    QString id;
    QString address;      // phone number / contact
    QString body;         // SMS body
    bool isIncoming;
    qint64 timestamp;
};

class MessageModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles
    {
        IdRole = Qt::UserRole + 1,
        AddressRole,
        BodyRole,
        IncomingRole,
        TimestampRole
    };

    explicit MessageModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addMessage(const QString &id,
                    const QString &address,
                    const QString &body,
                    bool isIncoming,
                    qint64 timestamp);

private:
    QList<MessageItem> m_items;
};

#endif // MESSAGEMODEL_H