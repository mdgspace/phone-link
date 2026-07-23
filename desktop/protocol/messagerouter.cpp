#include "messagerouter.h"
#include "protocoltypes.h"

void MessageRouter::route(const Message &msg)
{
    // ======================
    // Clipboard
    // ======================

    if (msg.type == ProtocolTypes::CLIPBOARD_PUSH)
    {
        m_clipboardHandler.handle(msg);
    }

    // ======================
    // SMS
    // ======================

    else if (msg.type == ProtocolTypes::SMS_LIST ||
             msg.type == ProtocolTypes::SMS_SEND ||
             msg.type == ProtocolTypes::SMS_RECEIVED)
    {
        m_messageHandler.handle(msg);
    }

    // ======================
    // File Transfer
    // ======================

    else if (msg.type == ProtocolTypes::FILE_OFFER ||
             msg.type == ProtocolTypes::FILE_ACCEPT ||
             msg.type == ProtocolTypes::FILE_REJECT ||
             msg.type == ProtocolTypes::FILE_CHUNK ||
             msg.type == ProtocolTypes::FILE_DONE)
    {
        m_fileHandler.handle(msg);
    }

    // ======================
    // System / Pairing
    // ======================

    else if (msg.type == ProtocolTypes::HELLO ||
             msg.type == ProtocolTypes::HELLO_ACK ||
             msg.type == ProtocolTypes::HEARTBEAT ||
             msg.type == ProtocolTypes::HEARTBEAT_ACK ||
             msg.type == ProtocolTypes::PAIRING_REQUEST ||
             msg.type == ProtocolTypes::PAIRING_PIN ||
             msg.type == ProtocolTypes::PAIRING_ACCEPTED ||
             msg.type == ProtocolTypes::PAIRING_REJECTED ||
             msg.type == ProtocolTypes::DISCONNECT)
    {
        m_systemHandler.handle(msg);
    }

    // ======================
    // Notifications
    // ======================

    else if (msg.type == ProtocolTypes::NOTIFICATION_POSTED ||
             msg.type == ProtocolTypes::NOTIFICATION_DISMISSED)
    {
        // TODO
        // m_notificationHandler.handle(msg);
    }
}