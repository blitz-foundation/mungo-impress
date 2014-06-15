#include <QCoreApplication>
#include <QTcpServer>
#include "singleapplication.h"
#include "httpserver.h"

int main(int argc, char *argv[])
{
    SingleApplication app(argc, argv, "MungoServer");

    if (app.isRunning())
    {
        app.sendMessage(QString(argv[1]));
        return 0;
    }

    qDebug() << "MungoServer v0.0.0";
    app.createHttpServer(QString(argv[1]));

    return app.exec();
}
