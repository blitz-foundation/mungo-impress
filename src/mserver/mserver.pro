#-------------------------------------------------
#
# Project created by QtCreator 2014-06-15T19:08:57
#
#-------------------------------------------------

QT       += core
QT       += network
QT       += gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = mserver
TEMPLATE = app


SOURCES += main.cpp \
    serverthread.cpp \
    singleapplication.cpp \
    httpserver.cpp \
    mainwindow.cpp

HEADERS += \
    serverthread.h \
    singleapplication.h \
    httpserver.h \
    mainwindow.h

FORMS += \
    mainwindow.ui

OTHER_FILES +=

RESOURCES += \
    resources.qrc
