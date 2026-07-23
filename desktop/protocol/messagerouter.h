#ifndef MESSAGEROUTER_H
#define MESSAGEROUTER_H

#pragma once

#include "message.h"

#include "../features/clipboard/clipboardhandler.h"
#include "../features/filetransfer/filetransferhandler.h"
#include "../features/messaging/messaginghandler.h"
#include "../features/system/systemhandler.h"

class MessageRouter
{
public:
    ClipboardHandler* clipboardHandler() { return &m_clipboardHandler; }
    MessagingHandler* messagingHandler() { return &m_messageHandler; }
    FileTransferHandler* fileHandler() { return &m_fileHandler; }
    SystemHandler* systemHandler() { return m_systemHandler; }

    void route(const Message &msg);

private:
    ClipboardHandler m_clipboardHandler;
    FileTransferHandler m_fileHandler;
    MessagingHandler m_messageHandler;
    SystemHandler m_systemHandler;
};

#endif // MESSAGEROUTER_H
