#include "filetransferhandler.h"

#include "../../protocol/protocoltypes.h"
#include "../../protocol/messageparser.h"

#include <QDebug>
#include <QFileInfo>
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

        const QString transferId =
            msg.payload.value("transfer_id").toString();

        // Keep only the filename component. This prevents a remote filename
        // from escaping the Downloads directory.
        const QString fileName =
            QFileInfo(msg.payload.value("file_name").toString()).fileName();

        const qint64 totalBytes =
            msg.payload.value("total_bytes").toInteger();

        if (fileName.isEmpty())
        {
            qWarning() << "[FileTransfer] Empty file name.";
            return;
        }

        const QString downloadDir =
            QStandardPaths::writableLocation(
                QStandardPaths::DownloadLocation);

        const QString path = downloadDir + "/" + fileName;

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
        m_filePath = path;
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
        const QString transferId =
            msg.payload.value("transfer_id").toString();

        qDebug() << "[FileTransfer] Transfer accepted:"
                 << transferId;

        emit fileTransferAccepted(transferId);
    }
    else if (msg.type == ProtocolTypes::FILE_REJECT)
    {
        const QString transferId =
            msg.payload.value("transfer_id").toString();

        qDebug() << "[FileTransfer] Transfer rejected:"
                 << transferId;

        if (m_currentFile.isOpen())
            m_currentFile.close();

        emit fileTransferRejected(transferId);
    }
    else if (msg.type == ProtocolTypes::FILE_CHUNK)
    {
        if (!m_currentFile.isOpen())
        {
            qWarning() << "[FileTransfer] No open file.";
            return;
        }

        const QJsonValue rawData = msg.payload.value("data");
        QByteArray bytes;

        // New mobile clients send base64 strings.
        if (rawData.isString())
        {
            bytes = QByteArray::fromBase64(
                rawData.toString().toUtf8());
        }
        // Older mobile builds send a JSON array of byte values.
        else if (rawData.isArray())
        {
            const QJsonArray array = rawData.toArray();
            bytes.reserve(array.size());

            for (const QJsonValue &value : array)
                bytes.append(static_cast<char>(value.toInt()));
        }
        else
        {
            qWarning() << "[FileTransfer] Invalid chunk data.";
            return;
        }

        if (m_currentFile.write(bytes) != bytes.size())
        {
            qWarning() << "[FileTransfer] Failed to write complete chunk.";
        }
    }
    else if (msg.type == ProtocolTypes::FILE_DONE)
    {
        if (m_currentFile.isOpen())
            m_currentFile.close();

        qDebug() << "[FileTransfer] Saved:" << m_filePath;

        emit fileReceived(
            m_transferId,
            m_fileName,
            m_totalBytes,
            m_filePath);

        m_transferId.clear();
        m_fileName.clear();
        m_filePath.clear();
        m_totalBytes = 0;
    }
    else
    {
        qWarning() << "[FileTransfer] Unknown packet:" << msg.type;
    }
}