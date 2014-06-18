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

    QString if_none_match;
    bool keep_alive = false;

    while (socket->canReadLine())
    {
        tokens = QString(socket->readLine()).split(QRegExp("[ \r\n][ \r\n]*"));

        if (QString::compare("if-none-match:", tokens[0], Qt::CaseInsensitive) == 0)
        {
            if_none_match = tokens[1].trimmed();
        }
        else if (QString::compare("connection:", tokens[0], Qt::CaseInsensitive) == 0)
        {
            keep_alive = (QString::compare("keep-alive", tokens[1].trimmed(), Qt::CaseInsensitive) == 0);
        }
    }

    QString etag = QString("\"%1\"").arg(QString::number(fileInfo.lastModified().toTime_t()));

    QTextStream headers(socket);
    headers.setAutoDetectUnicode(true);

    if (etag == if_none_match)
    {
        headers << "HTTP/1.1 304 Not Modified\r\n\r\n";

        headers.flush();

        if (!keep_alive)
           socket->disconnectFromHost();

        return;
    }
    else
    {
       headers << "HTTP/1.1 200 OK\r\n"
                  "Content-Type:" << server->getMimeType(fileInfo.absoluteFilePath()) << "\r\n"
                  "Content-Length:" << QString::number(fileInfo.size()) << "\r\n";
    }

    headers << "ETag:" << etag << "\r\n\r\n";

    headers.flush();

    QFile file(fileInfo.absoluteFilePath());
    file.open(QIODevice::ReadOnly);

    socket->write(file.readAll());

    file.close();

    if (!keep_alive)
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
