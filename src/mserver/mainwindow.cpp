#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "httpserver.h"

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);    
    port = 8079;
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::createHttpServer(QString filename)
{
    QFileInfo f(filename);

    if (!httpServers.contains(f.absolutePath())) {
        port += 1;

        HttpServer *httpServer = new HttpServer(this);

        if (httpServer->listen(QHostAddress::LocalHost, port)) {
            qDebug() << "HttpServer active and listening on port" << port;
            httpServers.insert(f.absolutePath(), httpServer);
        } else {
            qDebug() << "HttpServer: server failed to bind socket to port";
        }
    }

    QDesktopServices::openUrl(QUrl(QString("http://localhost:%1/%2").arg(QString::number(port), f.fileName())));
}
