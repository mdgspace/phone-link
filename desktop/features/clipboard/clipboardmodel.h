#ifndef CLIPBOARDMODEL_H
#define CLIPBOARDMODEL_H

#include <QAbstractListModel>
#include <QObject>

struct ClipboardItem
{
    QString text;
};

class ClipboardModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Roles
    {
        TextRole = Qt::UserRole + 1
    };

    explicit ClipboardModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addClipboard(const QString &text);

private:
    QList<ClipboardItem> m_items;
};

#endif // CLIPBOARDMODEL_H