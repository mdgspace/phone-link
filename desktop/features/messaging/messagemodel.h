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

    Q_PROPERTY(QString latestAddress READ latestAddress NOTIFY latestChanged)
    Q_PROPERTY(QString latestBody READ latestBody NOTIFY latestChanged)
    Q_PROPERTY(bool latestIsIncoming READ latestIsIncoming NOTIFY latestChanged)

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

    QString latestAddress() const;
    QString latestBody() const;
    bool latestIsIncoming() const;

    void addMessage(const QString &id,
                    const QString &address,
                    const QString &body,
                    bool isIncoming,
                    qint64 timestamp);
signals:
    void latestChanged();

private:
    QList<MessageItem> m_items;
};

#endif // MESSAGEMODEL_H