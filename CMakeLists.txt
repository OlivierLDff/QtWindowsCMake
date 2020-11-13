cmake_minimum_required(VERSION 3.11)

include(${CMAKE_CURRENT_LIST_DIR}/AddQtWindowsExe.cmake)

set(QT_WINDOWS_QT_ROOT ${QT_WINDOWS_QT_ROOT} CACHE STRING "qt sdk root folder")
set(QT_WINDOWS_SOURCE_DIR ${QT_WINDOWS_SOURCE_DIR} CACHE STRING "add_qt_windows_exe CMakeLists.txt folder")

set(QT_WINDOWS_CMAKE_FOUND ON CACHE BOOL "QtWindowsCMake have been found" FORCE)
set(QT_WINDOWS_CMAKE_VERSION "1.3.0" CACHE STRING "QtWindowsCMake version" FORCE)
