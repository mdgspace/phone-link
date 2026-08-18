#ifndef SHAREDFILESMODEL_H
#define SHAREDFILESMODEL_H

#include <QAbstractListModel>
#include <QObject>

struct SharedFileItem
{
    QString transferId;
    QString fileName;
    qint64 totalBytes = 0;
    QString filePath;
};

class SharedFilesModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles
    {
        TransferIdRole = Qt::UserRole + 1,
        FileNameRole,
        TotalBytesRole,
        FilePathRole
    };
    Q_ENUM(Roles)

    explicit SharedFilesModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addFile(const QString &transferId,
                 const QString &fileName,
                 qint64 totalBytes,
                 const QString &filePath);

    Q_INVOKABLE void openFile(int index);

signals:
    void countChanged();

private:
    QList<SharedFileItem> m_items;
};

#endif // SHAREDFILESMODEL_H