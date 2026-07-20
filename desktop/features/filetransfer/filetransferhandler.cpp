#include "filetransferhandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>
#include <QDir>
#include <QJsonArray>
#include <QStandardPaths>

FileTransferHandler::FileTransferHandler(QObject *parent)
    : QObject(parent)
{
}

void FileTransferHandler::handle(const Message &msg)
{
    if (msg.type == ProtocolTypes::FILE_OFFER)
    {
        if (!msg.payload.contains("transfer_id") ||
            !msg.payload.contains("file_name") ||
            !msg.payload.contains("total_bytes"))
        {
            qWarning() << "[FileTransfer] Invalid file offer.";
            return;
        }

        m_transferId = msg.payload["transfer_id"].toString();
        m_fileName = msg.payload["file_name"].toString();
        m_totalBytes = msg.payload["total_bytes"].toInteger();

        QString path =
            QStandardPaths::writableLocation(QStandardPaths::DownloadLocation)
            + "/" + m_fileName;

        m_currentFile.setFileName(path);

        if (!m_currentFile.open(QIODevice::WriteOnly))
        {
            qWarning() << "[FileTransfer] Failed to create"
                       << path;
            return;
        }

        qDebug() << "[FileTransfer] Receiving"
                 << m_fileName;
    }

    else if (msg.type == ProtocolTypes::FILE_CHUNK)
    {
        if (!m_currentFile.isOpen())
            return;

        QJsonArray array = msg.payload["data"].toArray();

        QByteArray bytes;
        bytes.reserve(array.size());

        for (const auto &value : array)
            bytes.append(static_cast<char>(value.toInt()));

        m_currentFile.write(bytes);
    }

    else if (msg.type == ProtocolTypes::FILE_DONE)
    {
        if (m_currentFile.isOpen())
            m_currentFile.close();

        qDebug() << "[FileTransfer] Saved:"
                 << m_currentFile.fileName();

        emit fileReceived(
            m_transferId,
            m_fileName,
            m_totalBytes);
    }
}