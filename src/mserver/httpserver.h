#ifndef MUNGOSERVER_H
#define MUNGOSERVER_H

#include <QTcpServer>

class HttpServer : public QTcpServer
{
public:
    HttpServer(const QString &documentRoot, QObject* parent = 0);

    QString documentRoot;

protected:
    void incomingConnection(qintptr socketDescriptor);
};

#endif // MUNGOSERVER_H
