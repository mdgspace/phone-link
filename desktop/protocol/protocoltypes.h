#pragma once

#include <QString>

namespace ProtocolTypes
{
// Device
const QString DEVICE_HELLO = "device.hello";
const QString DEVICE_HELLO_ACK = "device.hello_ack";

// System
const QString SYSTEM_PING = "system.ping";
const QString SYSTEM_PONG = "system.pong";

// Clipboard
const QString CLIPBOARD_PUSH = "clipboard.push";

// Messaging
const QString MESSAGE_SEND = "message.send";

// File transfer
const QString FILE_START = "file.start";
const QString FILE_CHUNK = "file.chunk";
const QString FILE_END = "file.end";
}
