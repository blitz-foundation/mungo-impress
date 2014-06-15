#-------------------------------------------------
#
# Project created by QtCreator 2014-06-15T19:08:57
#
#-------------------------------------------------

QT       += core
QT       += network

QT       -= gui

TARGET = MServer
CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = app


SOURCES += main.cpp \
    serverthread.cpp \
    mungoserver.cpp

HEADERS += \
    serverthread.h \
    mungoserver.h
