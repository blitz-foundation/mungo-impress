#include "mungoserver.h"
#include "serverthread.h"

MungoServer::MungoServer(QObject* parent)
    : QTcpServer(parent)
{
    qDebug() << "MungoServer v0.0.0";
}

void MungoServer::start(quint16 port)
{
    if (this->listen(QHostAddress::Any, port)) {
        qDebug() << "MungoServer active and listening on port" << port;
    } else {
        qDebug() << "MungoServer: server failed to bind socket to port";
    }
}

void MungoServer::incomingConnection(qintptr socketDescriptor)
{
    ServerThread *thread = new ServerThread(socketDescriptor, this);
    connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));

    thread->start();
}
