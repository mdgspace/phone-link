#include "filetransferhandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>
#include <QStandardPaths>

FileTransferHandler::FileTransferHandler(QObject *parent)
    : QObject(parent)
{
}

void FileTransferHandler::handle(const Message &msg)
{
    if (msg.type == ProtocolTypes::FILE_START)
    {
        QString fileName = msg.payload["name"].toString();

        QString path =
            QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)
            + "/" + fileName;

        m_currentFile.setFileName(path);
        int retVal = m_currentFile.open(QIODevice::WriteOnly);

        if (retVal) {

        }

        qDebug() << "[FileTransfer] Saving to:" << path;
    }

    else if (msg.type == ProtocolTypes::FILE_CHUNK)
    {
        QByteArray data =
            QByteArray::fromBase64(msg.payload["data"].toString().toUtf8());

        m_currentFile.write(data);
    }

    else if (msg.type == ProtocolTypes::FILE_END)
    {
        m_currentFile.close();

        qDebug() << "[FileTransfer] File saved";

        emit fileReceived(m_currentFile.fileName());
    }
}
