#include <QCoreApplication>
#include <QTcpServer>
#include "mungoserver.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    MungoServer mserver;
    mserver.start(8080);

    return app.exec();
}
