QT += core gui qml quick quickcontrols2 network webenginequick dbus multimedia

CONFIG += c++17 release
TARGET = flair
TEMPLATE = app

HEADERS += \
    src/ai.h \
    src/backend.h \
    src/filemanager1.h \
    src/filemodel.h \
    src/github.h \
    src/gitinfo.h \
    src/indexer.h \
    src/plan.h \
    src/settings.h \
    src/textextract.h \
    src/theme.h

SOURCES += \
    src/main.cpp \
    src/ai.cpp \
    src/actions.cpp \
    src/backend.cpp \
    src/filemanager1.cpp \
    src/filemodel.cpp \
    src/github.cpp \
    src/gitinfo.cpp \
    src/indexer.cpp \
    src/plan.cpp \
    src/settings.cpp \
    src/textextract.cpp \
    src/theme.cpp

RESOURCES += src/resources.qrc
