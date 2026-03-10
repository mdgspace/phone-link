#ifndef FILETRANSFERHANDLER_H
#define FILETRANSFERHANDLER_H

#include "protocol/message.h"

#include <QObject>
#include <QFile>

class FileTransferHandler : public QObject
{
    Q_OBJECT

public:
    explicit FileTransferHandler(QObject *parent = nullptr);

    void handle(const Message &msg);

signals:
    void fileReceived(const QString &text);

private:
    QFile m_currentFile;
};

#endif // FILETRANSFERHANDLER_H
