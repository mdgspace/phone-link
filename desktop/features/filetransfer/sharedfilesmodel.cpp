#include "sharedfilesmodel.h"

#include <QDesktopServices>
#include <QFileInfo>
#include <QUrl>

SharedFilesModel::SharedFilesModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int SharedFilesModel::rowCount(const QModelIndex &) const
{
    return m_items.size();
}

QVariant SharedFilesModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_items.size())
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

    case FilePathRole:
        return file.filePath;

    default:
        return {};
    }
}

QHash<int, QByteArray> SharedFilesModel::roleNames() const
{
    return {
        {TransferIdRole, "transferId"},
        {FileNameRole, "fileName"},
        {TotalBytesRole, "totalBytes"},
        {FilePathRole, "filePath"}
    };
}

void SharedFilesModel::addFile(const QString &transferId,
                               const QString &fileName,
                               qint64 totalBytes,
                               const QString &filePath)
{
    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());

    SharedFileItem item;
    item.transferId = transferId;
    item.fileName = fileName;
    item.totalBytes = totalBytes;
    item.filePath = filePath;

    m_items.append(item);

    endInsertRows();
    emit countChanged();
}

void SharedFilesModel::openFile(int index)
{
    if (index < 0 || index >= m_items.size())
        return;

    const QString path = m_items.at(index).filePath;
    if (path.isEmpty())
        return;

    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}