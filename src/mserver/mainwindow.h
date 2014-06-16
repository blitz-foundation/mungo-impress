#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QFileInfo>
#include <QDesktopServices>
#include <QUrl>
#include <QHash>
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

private:
    Ui::MainWindow *ui;

    quint16 port;
    QHash<QString, HttpServer*> httpServers;
};

#endif // MAINWINDOW_H
