#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.loadFromModule("com.phonelink", "App");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
