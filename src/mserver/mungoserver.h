#ifndef MUNGOSERVER_H
#define MUNGOSERVER_H

#include <QTcpServer>

class MungoServer : public QTcpServer
{
public:
    MungoServer(QObject* parent = 0);
    void start(quint16 port);

protected:
    void incomingConnection(qintptr socketDescriptor);
};

#endif // MUNGOSERVER_H
