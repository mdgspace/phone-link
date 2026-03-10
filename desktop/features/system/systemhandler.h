#ifndef SYSTEMHANDLER_H
#define SYSTEMHANDLER_H

#include "protocol/message.h"

class SystemHandler
{
public:
    void handle(const Message &msg);
};

#endif // SYSTEMHANDLER_H
