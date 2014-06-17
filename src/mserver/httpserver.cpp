#include "httpserver.h"
#include "serverthread.h"

HttpServer::HttpServer(const QString &documentRoot, QObject* parent)
    : QTcpServer(parent)
{
    this->documentRoot = documentRoot;
}

void HttpServer::incomingConnection(qintptr socketDescriptor)
{
    ServerThread *thread = new ServerThread(socketDescriptor, this);
    connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));

    thread->start();
}
