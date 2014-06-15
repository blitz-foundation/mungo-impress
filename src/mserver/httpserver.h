#ifndef MUNGOSERVER_H
#define MUNGOSERVER_H

#include <QTcpServer>

class HttpServer : public QTcpServer
{
public:
    HttpServer(QObject* parent = 0);
    void start(quint16 port);

protected:
    void incomingConnection(qintptr socketDescriptor);
};

#endif // MUNGOSERVER_H
