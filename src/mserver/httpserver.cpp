#include "httpserver.h"
#include "serverthread.h"

HttpServer::HttpServer(QObject* parent)
    : QTcpServer(parent)
{
}

void HttpServer::start(quint16 port)
{
    if (this->listen(QHostAddress::Any, port)) {
        qDebug() << "HttpServer active and listening on port" << port;
    } else {
        qDebug() << "HttpServer: server failed to bind socket to port";
    }
}

void HttpServer::incomingConnection(qintptr socketDescriptor)
{
    qDebug() << "New connection";

    ServerThread *thread = new ServerThread(socketDescriptor, this);
    connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));

    thread->start();
}
