#pragma once
#include <QtGlobal>

// Single source of truth for the desktop's TCP listen port. The phone
// never hardcodes a port — it always connects to whatever port is
// advertised in the mDNS TXT/SRV record (see MdnsManager::registerService),
// so this only needs to stay consistent between TcpServer::start() and
// Backend's call to registerService(). Flutter's own `defaultPort` (4040)
// is unrelated: it's only used for the phone's own (currently unused)
// self-registration, not for connecting to the desktop.
constexpr quint16 TCP_SERVER_PORT = 5555;

namespace Protocol {
    constexpr char HELLO[] = "HELLO";
    constexpr char PING[] = "PING";
}
