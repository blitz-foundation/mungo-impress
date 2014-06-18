#include "mainwindow.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    ui->console->appendPlainText("MungoServer v0.0.0");
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::createHttpServer(QString filename)
{
    QFileInfo f(filename);

    if (!f.exists())
        return;

    if (!httpServers.contains(f.absolutePath()))
    {
        port = httpServers.empty() ? 8080 : port + 1;

        HttpServer *httpServer = new HttpServer(f.absolutePath(), this);

        while(!httpServer->listen(QHostAddress::LocalHost, port) && port < 8180)
            port++;

        if (httpServer->isListening())
        {
            ui->console->appendPlainText("HttpServer active and listening on port " + QString::number(port));
            httpServers.insert(f.absolutePath(), httpServer);
        }
        else
        {
            ui->console->appendPlainText("HttpServer server failed to bind socket to port " + QString::number(port));
        }

    }
    else
    {
        ui->console->appendPlainText("HttpServer active and listening on port " + QString::number(port));
    }

    QDesktopServices::openUrl(QUrl(QString("http://localhost:%1/%2").arg(QString::number(port), f.fileName())));
}

void MainWindow::receiveMessage(QString filename)
{
    if (filename.length())
        this->createHttpServer(filename);
}
