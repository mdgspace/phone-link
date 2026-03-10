#include "messagerouter.h"
#include "protocoltypes.h"

void MessageRouter::route(const Message &msg)
{
    if (msg.type == ProtocolTypes::CLIPBOARD_PUSH)
    {
        m_clipboardHandler.handle(msg);
    }
    else if (msg.type == ProtocolTypes::MESSAGE_SEND)
    {
        m_messageHandler.handle(msg);
    }
    else if (msg.type == ProtocolTypes::FILE_START ||
             msg.type == ProtocolTypes::FILE_CHUNK ||
             msg.type == ProtocolTypes::FILE_END)
    {
        m_fileHandler.handle(msg);
    }
    else if (msg.type == ProtocolTypes::SYSTEM_PING ||
             msg.type == ProtocolTypes::SYSTEM_PONG ||
             msg.type == ProtocolTypes::DEVICE_HELLO ||
             msg.type == ProtocolTypes::DEVICE_HELLO_ACK)
    {
        m_systemHandler.handle(msg);
    }
}
