#include "filetransferhandler.h"

#include "../../protocol/protocoltypes.h"
#include "../../protocol/messageparser.h"

#include <QDebug>
#include <QJsonArray>
#include <QStandardPaths>
#include <QTcpSocket>

FileTransferHandler::FileTransferHandler(QObject *parent)
    : QObject(parent)
{
}

void FileTransferHandler::handle(QTcpSocket *client, const Message &msg)
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

        QString transferId =
            msg.payload.value("transfer_id").toString();

        QString fileName =
            msg.payload.value("file_name").toString();

        qint64 totalBytes =
            msg.payload.value("total_bytes").toInteger();

        QString path =
            QStandardPaths::writableLocation(
                QStandardPaths::DownloadLocation)
            + "/" + fileName;

        m_currentFile.setFileName(path);

        if (!m_currentFile.open(QIODevice::WriteOnly | QIODevice::Truncate))
        {
            qWarning() << "[FileTransfer] Failed to create"
                       << path << "- rejecting offer";

            Message reject;
            reject.type = ProtocolTypes::FILE_REJECT;
            reject.payload["transfer_id"] = transferId;
            MessageParser::send(client, reject);
            return;
        }

        m_transferId = transferId;
        m_fileName = fileName;
        m_totalBytes = totalBytes;

        qDebug() << "[FileTransfer] Incoming file:"
                 << m_fileName
                 << "(" << m_totalBytes << "bytes )";

        Message accept;
        accept.type = ProtocolTypes::FILE_ACCEPT;
        accept.payload["transfer_id"] = m_transferId;
        MessageParser::send(client, accept);
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