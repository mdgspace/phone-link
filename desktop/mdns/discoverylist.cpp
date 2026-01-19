#include "discoverylist.h"

DiscoveryList::DiscoveryList(QObject *parent)
    : QAbstractListModel{parent}
{
}

int DiscoveryList::rowCount(const QModelIndex &) const
{
    return m_deviceList.size();
}

QVariant DiscoveryList::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()) {
        return {};
    }

    const auto &device = m_deviceList[index.row()];

    // roles in Qt are like the second index which specifies which column we want to access
    switch ( role )
    {
    case NameRole: return device.name;
    case AddressRole: return device.address;
    case ServiceRole: return device.service;
    case PortRole: return device.port;
    }

    return {};
}

QHash<int, QByteArray> DiscoveryList::roleNames() const
{
    return {
        { NameRole, "name" },
        { AddressRole, "address" },
        { ServiceRole, "service" },
        { PortRole, "port" }
    };
}

void DiscoveryList::addDevice(const QString &name,
                              const QString &address,
                              const QString &service,
                              quint16 port)
{
    beginInsertRows(QModelIndex(), m_deviceList.size(), m_deviceList.size());
    m_deviceList.append({name, address, service, port});
    endInsertRows();
}
