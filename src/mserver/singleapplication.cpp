#include "singleapplication.h"

#include <QTimer>
#include <QByteArray>
#include <QFileInfo>
#include <QDesktopServices>
#include <QUrl>

SingleApplication::SingleApplication(int &argc, char *argv[], const QString uniqueKey) : QApplication(argc, argv)
{
    sharedMemory.setKey(uniqueKey);
    if (sharedMemory.attach())
        _isRunning = true;
    else
    {
        _isRunning = false;
        // attach data to shared memory.
        QByteArray byteArray("0"); // default value to note that no message is available.
        if (!sharedMemory.create(byteArray.size()))
        {
            qDebug("Unable to create single instance.");
            return;
        }
        sharedMemory.lock();
        char *to = (char*)sharedMemory.data();
        const char *from = byteArray.data();
        memcpy(to, from, qMin(sharedMemory.size(), byteArray.size()));
        sharedMemory.unlock();
        // start checking for messages of other instances.
        QTimer *timer = new QTimer(this);
        connect(timer, SIGNAL(timeout()), this, SLOT(checkForMessage()));
        timer->start(1000);

        _port = 8079;
    }
}

// public slots.

void SingleApplication::checkForMessage()
{
    sharedMemory.lock();
    QByteArray byteArray = QByteArray((char*)sharedMemory.constData(), sharedMemory.size());
    sharedMemory.unlock();
    if (byteArray.left(1) == "0")
        return;
    byteArray.remove(0, 1);

    createHttpServer(QString::fromUtf8(byteArray.constData()));

    // remove message from shared memory.
    byteArray = "0";
    sharedMemory.lock();
    char *to = (char*)sharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(sharedMemory.size(), byteArray.size()));
    sharedMemory.unlock();
}

// public functions.

bool SingleApplication::isRunning()
{
    return _isRunning;
}

bool SingleApplication::sendMessage(const QString &message)
{
    if (!_isRunning)
        return false;
    QByteArray byteArray("1");
    byteArray.append(message.toUtf8());
    byteArray.append('\0'); // < should be as char here, not a string!
    sharedMemory.lock();
    char *to = (char*)sharedMemory.data();
    const char *from = byteArray.data();
    memcpy(to, from, qMin(sharedMemory.size(), byteArray.size()));
    sharedMemory.unlock();
    return true;
}

void SingleApplication::createHttpServer(QString filename)
{
    QFileInfo f(filename);

    if (!_httpServers.contains(f.absolutePath())) {
        _port += 1;

        HttpServer httpServer;
        httpServer.start(_port);

        _httpServers.insert(f.absolutePath());
    }

    //QDesktopServices::openUrl(QUrl(QString("http://localhost:%1/%2").arg(QString::number(_port), f.fileName())));
}
