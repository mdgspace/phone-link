cmake_minimum_required(VERSION 3.16)

project(phone-link VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.10.1 COMPONENTS Quick REQUIRED)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(app-phone-link
        main.cpp
)

qt_add_qml_module(app-phone-link
        URI phone-link
        QML_FILES
            qml/main.qml
#        RESOURCES
#            img/world.png
)
target_link_libraries(app-phone-link PRIVATE Qt6::Quick)