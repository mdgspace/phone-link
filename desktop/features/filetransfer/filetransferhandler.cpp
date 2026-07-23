#include "filetransferhandler.h"

#include "../../protocol/protocoltypes.h"

#include <QDebug>
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

        m_transferId =
            msg.payload.value("transfer_id").toString();

        m_fileName =
            msg.payload.value("file_name").toString();

        m_totalBytes =
            msg.payload.value("total_bytes").toInteger();

        QString path =
            QStandardPaths::writableLocation(
                QStandardPaths::DownloadLocation)
            + "/" + m_fileName;

        m_currentFile.setFileName(path);

        if (!m_currentFile.open(QIODevice::WriteOnly))
        {
            qWarning() << "[FileTransfer] Failed to create"
                       << path;
            return;
        }

        qDebug() << "[FileTransfer] Incoming file:"
                 << m_fileName
                 << "(" << m_totalBytes << "bytes )";
    }

    else if (msg.type == ProtocolTypes::FILE_ACCEPT)
    {
        QString transferId =
            msg.payload.value("transfer_id").toString();

        qDebug() << "[FileTransfer] Transfer accepted:"
                 << transferId;

        emit fileTransferAccepted(transferId);
    }

    else if (msg.type == ProtocolTypes::FILE_REJECT)
    {
        QString transferId =
            msg.payload.value("transfer_id").toString();

        qDebug() << "[FileTransfer] Transfer rejected:"
                 << transferId;

        if (m_currentFile.isOpen())
        {
            m_currentFile.close();
        }

        emit fileTransferRejected(transferId);
    }

    else if (msg.type == ProtocolTypes::FILE_CHUNK)
    {
        if (!m_currentFile.isOpen())
        {
            qWarning() << "[FileTransfer] No open file.";
            return;
        }

        QJsonArray array =
            msg.payload.value("data").toArray();

        QByteArray bytes;
        bytes.reserve(array.size());

        for (const auto &value : array)
        {
            bytes.append(static_cast<char>(value.toInt()));
        }

        m_currentFile.write(bytes);
    }

    else if (msg.type == ProtocolTypes::FILE_DONE)
    {
        if (m_currentFile.isOpen())
        {
            m_currentFile.close();
        }

        qDebug() << "[FileTransfer] Saved:"
                 << m_currentFile.fileName();

        emit fileReceived(
            m_transferId,
            m_fileName,
            m_totalBytes);

        m_transferId.clear();
        m_fileName.clear();
        m_totalBytes = 0;
    }

    else
    {
        qWarning() << "[FileTransfer] Unknown packet:"
                   << msg.type;
    }
}