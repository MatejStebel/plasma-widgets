cmake_minimum_required(VERSION 3.20)

project(
    BakalariWalletPlugin
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)

find_package(
    Qt6 REQUIRED
    COMPONENTS
        Core
        Qml
)

find_package(
    KF6Wallet REQUIRED
)

add_library(
    bakalarwalletplugin
    SHARED

    wallet/walletbackend.cpp
    wallet/walletbackend.h
    wallet/walletplugin.cpp
)

target_link_libraries(
    bakalarwalletplugin
    PRIVATE
        Qt6::Core
        Qt6::Qml
        KF6::Wallet
)

set_target_properties(
    bakalarwalletplugin
    PROPERTIES
        PREFIX "lib"
)