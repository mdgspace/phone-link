#ifndef FILETRANSFERHANDLER_H
#define FILETRANSFERHANDLER_H

#include <QObject>
#include <QFile>
#include "../../protocol/message.h"

class FileTransferHandler : public QObject
{
    Q_OBJECT

public:
    explicit FileTransferHandler(QObject *parent = nullptr);

    void handle(const Message &msg);

signals:
    void fileReceived(const QString &transferId,
                      const QString &fileName,
                      qint64 totalBytes);

private:
    QFile m_currentFile;

    QString m_transferId;
    QString m_fileName;
    qint64 m_totalBytes = 0;
};

#endif // FILETRANSFERHANDLER_H