#pragma once

#include <QString>

namespace ProtocolTypes
{
// ==========================
// Connection
// ==========================

inline const QString HELLO            = "hello";
inline const QString HELLO_ACK        = "hello_ack";

inline const QString HEARTBEAT        = "heartbeat";
inline const QString HEARTBEAT_ACK    = "heartbeat_ack";

inline const QString DISCONNECT       = "disconnect";

// ==========================
// Pairing
// ==========================

inline const QString PAIRING_REQUEST  = "pairing_request";
inline const QString PAIRING_PIN      = "pairing_pin";
inline const QString PAIRING_ACCEPTED = "pairing_accepted";
inline const QString PAIRING_REJECTED = "pairing_rejected";

// ==========================
// Clipboard
// ==========================

inline const QString CLIPBOARD_PUSH   = "clipboard_push";

// ==========================
// SMS
// ==========================

inline const QString SMS_LIST         = "sms_list";
inline const QString SMS_SEND         = "sms_send";
inline const QString SMS_RECEIVED     = "sms_received";

// ==========================
// Notifications
// ==========================

inline const QString NOTIFICATION_POSTED =
    "notification_posted";

inline const QString NOTIFICATION_DISMISSED =
    "notification_dismissed";

// ==========================
// File Transfer
// ==========================

inline const QString FILE_OFFER       = "file_offer";
inline const QString FILE_ACCEPT      = "file_accept";
inline const QString FILE_REJECT      = "file_reject";
inline const QString FILE_CHUNK       = "file_chunk";
inline const QString FILE_DONE        = "file_done";
}