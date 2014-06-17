#ifndef SERVERTHREAD_H
#define SERVERTHREAD_H

#include <QThread>
#include <QTcpSocket>
#include <QFileInfo>

class ServerThread : public QThread
{
    Q_OBJECT
public:
    explicit ServerThread(qintptr clientId, QObject *parent = 0);

    void run();

    void writeDataType(QString filename, QTcpSocket *socket);

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
