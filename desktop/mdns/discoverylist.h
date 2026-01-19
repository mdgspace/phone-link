#ifndef DISCOVERYLIST_H
#define DISCOVERYLIST_H

#include <QAbstractListModel>

struct Device {
    QString name;
    QString address;
    QString service;
    quint16 port;
};

class DiscoveryList : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        AddressRole,
        ServiceRole,
        PortRole
    };

    explicit DiscoveryList(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addDevice(const QString &name,
                   const QString &address,
                   const QString &service,
                   quint16 port);

private:
    QList<Device> m_deviceList;
};

#endif // DISCOVERYLIST_H
