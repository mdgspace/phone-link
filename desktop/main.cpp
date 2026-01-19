#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDBusConnection>
#include <QDBusError>
#include <QDebug>
#include <QThread>
#include <qqmlcontext.h>

#include "core/backend.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    Backend backend;

    QDBusConnection bus = QDBusConnection::sessionBus();

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("Backend", &backend);
    engine.loadFromModule("com.phonelink", "App");

    qDebug() << "[MAIN THREAD]" << QThread::currentThread();

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
