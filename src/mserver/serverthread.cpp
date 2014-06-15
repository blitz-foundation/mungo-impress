#include "serverthread.h"

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
    if (socket->canReadLine()) {
        QStringList tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));

        if (QString::compare("GET", tokens[0], Qt::CaseInsensitive) != 0) {
            socket->close();
            return;
        }
    }

    while (socket->canReadLine()) {
        QStringList tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));
    }

    socket->close();
}

void ServerThread::disconnected()
{
    socket->deleteLater();
    exit(0);
}
