#include "httpserver.h"

HttpServer::HttpServer(const QString &documentRoot, QObject* parent)
    : QTcpServer(parent), documentRoot(documentRoot)
{
}

void HttpServer::incomingConnection(qintptr socketDescriptor)
{
    ServerThread *thread = new ServerThread(socketDescriptor, this);
    connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));

    thread->start();
}

const QString HttpServer::getMimeType(const QString &filename)
{
    QString mimeType = mimeTypes.mimeTypeForFile(filename).name();

    if (mimeType == "text/html")
        mimeType += "; charset=\"utf-8\"";

    return mimeType;
}
