#include <QCoreApplication>
#include <QTcpServer>
#include "singleapplication.h"
#include "mungoserver.h"

int main(int argc, char *argv[])
{
    SingleApplication app(argc, argv, "MungoServer");

    if (app.isRunning())
    {
        app.sendMessage("TODO");
        return 0;
    }

    MungoServer mserver;
    mserver.start(8080);

    return app.exec();
}
