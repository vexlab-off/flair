QT += core gui quick quickcontrols2 network testlib dbus
CONFIG += c++17 testcase
TARGET = flair_tests
TEMPLATE = app

INCLUDEPATH += ../src

HEADERS += ../src/ai.h ../src/backend.h ../src/filemodel.h ../src/github.h ../src/gitinfo.h ../src/indexer.h ../src/launcher.h \
           ../src/plan.h ../src/settings.h ../src/textextract.h ../src/theme.h
SOURCES += flair_tests.cpp ../src/ai.cpp ../src/actions.cpp ../src/backend.cpp ../src/filemodel.cpp ../src/github.cpp ../src/gitinfo.cpp \
           ../src/indexer.cpp ../src/launcher.cpp ../src/plan.cpp ../src/settings.cpp ../src/textextract.cpp ../src/theme.cpp
