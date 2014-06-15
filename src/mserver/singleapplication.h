#ifndef SINGLEAPPLICATION_H
#define SINGLEAPPLICATION_H

#include <QApplication>
#include <QSharedMemory>
#include "httpserver.h"

class SingleApplication : public QApplication
{
    Q_OBJECT
public:
    explicit SingleApplication(int &argc, char *argv[], const QString uniqueKey);

    bool isRunning();
    bool sendMessage(const QString &message);

    void createHttpServer(QString filename);

public slots:
    void checkForMessage();

private:
    bool _isRunning;
    QSharedMemory sharedMemory;

    quint16 _port;
    QSet<QString> _httpServers;

};

#endif // SINGLEAPPLICATION_H
