cmake_minimum_required(VERSION 3.16)

project(phone_link VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.10.1 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(app_phone_link
    main.cpp
)

qt_add_qml_module(app_phone_link
    URI com.phonelink
    QML_FILES
        qml/App.qml

        qml/layout/MainContent.qml
        qml/layout/NavigationBar.qml

        qml/pages/connection/ConnectedPage.qml
        qml/pages/connection/DiscoveryPage.qml
        qml/pages/connection/RegistrationPage.qml

        qml/pages/shared/ClipboardItemsPage.qml
        qml/pages/shared/SharedFilesPage.qml

        qml/widgets/ClipboardWidget.qml
        qml/widgets/FileWidget.qml
        qml/widgets/MessageWidget.qml
)

target_link_libraries(app_phone_link
    PRIVATE Qt6::Quick
)
