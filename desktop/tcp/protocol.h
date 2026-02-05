#pragma once
#include <qtypes.h>

constexpr quint16 TCP_SERVER_PORT = 4242;

namespace Protocol {
    constexpr char HELLO[] = "HELLO";
    constexpr char PING[] = "PING";
}
