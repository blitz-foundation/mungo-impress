#ifndef MUNGOSERVER_H
#define MUNGOSERVER_H

#include <QTcpServer>

class HttpServer : public QTcpServer
{
public:
    HttpServer(QObject* parent = 0);

protected:
    void incomingConnection(qintptr socketDescriptor);
};

#endif // MUNGOSERVER_H
