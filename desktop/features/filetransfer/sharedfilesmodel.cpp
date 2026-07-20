#include "sharedfilesmodel.h"

SharedFilesModel::SharedFilesModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int SharedFilesModel::rowCount(const QModelIndex &) const
{
    return m_items.size();
}

QVariant SharedFilesModel::data(const QModelIndex &index,
                                int role) const
{
    if (!index.isValid())
        return {};

    const SharedFileItem &file = m_items.at(index.row());

    switch (role)
    {
    case TransferIdRole:
        return file.transferId;

    case FileNameRole:
        return file.fileName;

    case TotalBytesRole:
        return file.totalBytes;

    default:
        return {};
    }
}

QHash<int, QByteArray> SharedFilesModel::roleNames() const
{
    return {
        {TransferIdRole, "transferId"},
        {FileNameRole, "fileName"},
        {TotalBytesRole, "totalBytes"}
    };
}

void SharedFilesModel::addFile(const QString &transferId,
                               const QString &fileName,
                               qint64 totalBytes)
{
    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());

    SharedFileItem item;
    item.transferId = transferId;
    item.fileName = fileName;
    item.totalBytes = totalBytes;

    m_items.append(item);

    endInsertRows();
}