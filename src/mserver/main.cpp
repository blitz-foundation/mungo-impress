#include <QProcess>
#include "singleapplication.h"
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    SingleApplication app(argc, argv, "MungoServer");

    if (app.isRunning())
    {
        if (argc > 1)
            app.sendMessage(QString(argv[1]));
        return 0;
    }
    else if (argc > 1 && (argc < 3 || QString(argv[2]) != "--server"))
    {
        app.quit();

        QStringList args;
        args.append(QString(argv[1]));
        args.append("--server");

        QProcess::startDetached(QString(argv[0]), args);
        return 0;
    }

    MainWindow w;

    QObject::connect(&app, SIGNAL(messageAvailable(QString)), &w, SLOT(receiveMessage(QString)));

    if (argc > 1)
        w.createHttpServer(QString(argv[1]));

    return app.exec();
}
