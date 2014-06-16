#include "httpserver.h"
#include "serverthread.h"

HttpServer::HttpServer(QObject* parent)
    : QTcpServer(parent)
{
    qDebug() << "try to create server";
}

void HttpServer::incomingConnection(qintptr socketDescriptor)
{
    qDebug() << "new client";

    ServerThread *thread = new ServerThread(socketDescriptor, this);
    connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));

    thread->start();
}
