#ifndef MUNGOSERVER_H
#define MUNGOSERVER_H

#include <QTcpServer>

class HttpServer : public QTcpServer
{
public:
    HttpServer(const QString &documentRoot, QObject* parent = 0);

protected:
    void incomingConnection(qintptr socketDescriptor);

private:
    QString documentRoot;
};

#endif // MUNGOSERVER_H
