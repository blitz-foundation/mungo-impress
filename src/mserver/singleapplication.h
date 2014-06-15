#ifndef SINGLEAPPLICATION_H
#define SINGLEAPPLICATION_H

#include <QCoreApplication>
#include <QSharedMemory>

class SingleApplication : public QCoreApplication
{
    Q_OBJECT
public:
    explicit SingleApplication(int &argc, char *argv[], const QString uniqueKey);

    bool isRunning();
    bool sendMessage(const QString &message);

signals:
    void messageAvailable(QString message);

public slots:
    void checkForMessage();

private:
    bool _isRunning;
    QSharedMemory sharedMemory;

};

#endif // SINGLEAPPLICATION_H
