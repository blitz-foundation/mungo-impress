#ifndef SERVERTHREAD_H
#define SERVERTHREAD_H

#include <QThread>
#include <QTcpSocket>
#include <QFileInfo>
#include <QDateTime>

#include "httpserver.h"

class ServerThread : public QThread
{
    Q_OBJECT
public:
    explicit ServerThread(qintptr clientId, QObject *parent = 0);

    void run();

    void abort(quint16 code, const QString &message);

signals:
    void error(QTcpSocket::SocketError socketerror);

public slots:
    void readyRead();
    void disconnected();

private:
    QTcpSocket *socket;
    qintptr clientId;

};

#endif // SERVERTHREAD_H
