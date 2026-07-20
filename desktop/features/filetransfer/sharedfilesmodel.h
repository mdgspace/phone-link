#ifndef SHAREDFILESMODEL_H
#define SHAREDFILESMODEL_H

#include <QAbstractListModel>
#include <QObject>

struct SharedFileItem
{
    QString transferId;
    QString fileName;
    qint64 totalBytes;
};

class SharedFilesModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles
    {
        TransferIdRole = Qt::UserRole + 1,
        FileNameRole,
        TotalBytesRole
    };

    explicit SharedFilesModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;

    QHash<int, QByteArray> roleNames() const override;

    void addFile(const QString &transferId,
                 const QString &fileName,
                 qint64 totalBytes);

private:
    QList<SharedFileItem> m_items;
};

#endif // SHAREDFILESMODEL_H