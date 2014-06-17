#include "serverthread.h"
#include "httpserver.h"

ServerThread::ServerThread(qintptr clientId, QObject *parent) :
    QThread(parent)
{
    this->clientId = clientId;
}

void ServerThread::run()
{
    socket = new QTcpSocket();

    if(!socket->setSocketDescriptor(this->clientId))
    {
        emit error(socket->error());
        return;
    }

    connect(socket, SIGNAL(readyRead()), this, SLOT(readyRead()), Qt::DirectConnection);
    connect(socket, SIGNAL(disconnected()), this, SLOT(disconnected()));

    exec();
}

void ServerThread::readyRead()
{
    QStringList tokens;

    if (socket->canReadLine())
    {
        tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));

        if (QString::compare("GET", tokens[0], Qt::CaseInsensitive) != 0 || tokens.length() < 2)
        {
            socket->close();
            return;
        }
    }

    QFileInfo fileInfo = QFileInfo(((HttpServer*)this->parent())->documentRoot + tokens[1]);
    if (!fileInfo.exists())
    {
        socket->close();
        return;
    }

    while (socket->canReadLine())
    {
        tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));
    }

    QFile file(fileInfo.absoluteFilePath());
    file.open(QIODevice::ReadOnly);

    socket->write(file.readAll());

    file.close();
    socket->close();
}

void ServerThread::disconnected()
{
    socket->deleteLater();
    exit(0);
}
