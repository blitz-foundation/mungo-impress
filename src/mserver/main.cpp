#include <QCoreApplication>
#include <QTcpServer>

#include "singleapplication.h"
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    SingleApplication app(argc, argv, "MungoServer");

    if (app.isRunning())
    {
        app.sendMessage(QString(argv[1]));
        return 0;
    }

    MainWindow w;

    QObject::connect(&app, SIGNAL(messageAvailable(QString)), &w, SLOT(receiveMessage(QString)));

    if (argc > 1)
        w.createHttpServer(QString(argv[1]));

    w.show();

    return app.exec();
}
