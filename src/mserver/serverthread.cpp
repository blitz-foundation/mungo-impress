#include "serverthread.h"

ServerThread::ServerThread(qintptr clientId, QObject *parent) :
    QThread(parent), clientId(clientId)
{
}

void ServerThread::run()
{
    socket = new QTcpSocket();

    if(!socket->setSocketDescriptor(this->clientId))
    {
        emit error(socket->error());
        return;
    }

    connect(socket, SIGNAL(readyRead()), this, SLOT(readyRead()), Qt::DirectConnection);
    connect(socket, SIGNAL(disconnected()), this, SLOT(disconnected()), Qt::DirectConnection);

    exec();
}

void ServerThread::readyRead()
{
    QStringList tokens;

    if (socket->canReadLine())
    {
        tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));

        if (QString::compare("GET", tokens[0], Qt::CaseInsensitive) != 0 || tokens.length() < 2)
        {
            abort(400, "400 Bad Request");
            return;
        }
    }
    else
    {
        abort(400, "400 Bad Request");
        return;
    }

    HttpServer *server = (HttpServer*)this->parent();
    QFileInfo fileInfo = QFileInfo(server->documentRoot + tokens[1]);

    if (!fileInfo.exists())
    {
        abort(404, "404 Not Found");
        return;
    }

    while (socket->canReadLine())
    {
        tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));
    }

    QFile file(fileInfo.absoluteFilePath());
    file.open(QIODevice::ReadOnly);

    QTextStream headers(socket);
    headers.setAutoDetectUnicode(true);

    headers << "HTTP/1.1 200 OK\r\n"
        "Content-Type:" << server->getMimeType(fileInfo.absoluteFilePath()) << "\r\n"
        "Content-Length:" << QString::number(file.size()) << "\r\n"
        "\r\n";

    headers.flush();
    socket->write(file.readAll());

    file.close();
    socket->disconnectFromHost();
}

void ServerThread::abort(quint16 code, const QString &message)
{
    QTextStream os(socket);
    os.setAutoDetectUnicode(true);

    QString status;

    switch (code)
    {
    case 404:
        status = "Not Found";
        break;
    case 400:
        status = "Bad Request";
        break;
    default:
        status = "OK";
        break;
    }

    QString body = "<h1>" + message + "</h1>";

    os << "HTTP/1.1" << QString::number(code) <<  status << "\r\n"
        "Content-Type: text/html; charset=\"utf-8\"\r\n"
        "Content-Length:" << QString::number(body.length()) << "\r\n"
        "\r\n";

    os << body;

    os.flush();
    socket->disconnectFromHost();
}

void ServerThread::disconnected()
{
    socket->close();
    quit();
}
