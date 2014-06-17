#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "httpserver.h"
#include "singleapplication.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);    
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::createHttpServer(QString filename)
{
    QFileInfo f(filename);

    if (!httpServers.contains(f.absolutePath())) {
        if (httpServers.empty()) {
            port = 8080;
        } else {
            port += 1;
        }

        HttpServer *httpServer = new HttpServer(this);

        while(!httpServer->listen(QHostAddress::LocalHost, port) && port < 8180) {
            port += 1;
        }

        if (httpServer->isListening()) {
            qDebug() << "HttpServer active and listening on port" << port;
            httpServers.insert(f.absolutePath(), httpServer);
        } else {
            qDebug() << "HttpServer: server failed to bind socket to port";
        }
    } else {
        qDebug() << "HttpServer active and listening on port" << port;
    }

    QDesktopServices::openUrl(QUrl(QString("http://localhost:%1/%2").arg(QString::number(port), f.fileName())));
}

void MainWindow::receiveMessage(QString filename)
{
    this->createHttpServer(filename);
}
