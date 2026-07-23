#ifndef FILETRANSFERHANDLER_H
#define FILETRANSFERHANDLER_H

#pragma once

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

    void fileTransferAccepted(const QString &transferId);

    void fileTransferRejected(const QString &transferId);

private:
    QString m_transferId;
    QString m_fileName;
    qint64 m_totalBytes = 0;

    QFile m_currentFile;
};

#endif // FILETRANSFERHANDLER_H