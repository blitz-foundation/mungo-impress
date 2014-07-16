#ifndef HTTPSERVER_H
#define HTTPSERVER_H

#include <QTcpServer>
#include <QMimeType>
#include <QMimeDatabase>

#include "serverthread.h"

class HttpServer : public QTcpServer
{
public:
    HttpServer(const QString &documentRoot, int port, QObject* parent = 0);

    const QString getMimeType(const QString &filename);

    QString documentRoot;

    int port;

protected:
    void incomingConnection(qintptr socketDescriptor);

private:
    QMimeDatabase mimeTypes;
};

#endif // HTTPSERVER_H
