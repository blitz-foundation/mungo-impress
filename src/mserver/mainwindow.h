#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#define MUNGOSERVER_VERSION "0.1.0"

#include <QMainWindow>
#include <QFileInfo>
#include <QDesktopServices>
#include <QUrl>
#include <QHash>

#include "ui_mainwindow.h"
#include "httpserver.h"

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();

    void createHttpServer(QString filename);

public slots:
    void receiveMessage(QString filename);

private:
    Ui::MainWindow *ui;

    quint16 port;
    QHash<QString, HttpServer*> httpServers;
};

#endif // MAINWINDOW_H
