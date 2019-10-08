# find the Qt root directory
if(NOT Qt5Core_DIR)
    find_package(Qt5Core REQUIRED)
endif() # NOT Qt5Core_DIR
get_filename_component(QT_WINDOWS_QT_ROOT "${Qt5Core_DIR}/../../.." ABSOLUTE)
message(STATUS "Found Qt for Windows: ${QT_WINDOWS_QT_ROOT}")

set(QT_WINDOWS_QT_ROOT ${QT_WINDOWS_QT_ROOT} CACHE STRING "qt sdk root folder")
set(QT_WINDOWS_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE STRING "add_qt_windows_exe CMakeLists.txt folder")

set(QBC_REPOSITORY "https://github.com/OlivierLDff/QbcInstaller.git" CACHE STRING "Repository of Qbc")
set(QBC_TAG "master" CACHE STRING "Git Tag of Qbc")

include(FetchContent)

# Qbc
FetchContent_Declare(
    Qbc
    GIT_REPOSITORY ${QBC_REPOSITORY}
    GIT_TAG        ${QBC_TAG}
)
FetchContent_MakeAvailable(Qbc)

set(QT_WINDOWS_CMAKE_FOUND ON CACHE BOOL "QtWindowsCMake have been found" FORCE)
set(QT_WINDOWS_CMAKE_VERSION "1.0.1" CACHE STRING "QtWindowsCMake version" FORCE)

include(CMakeParseArguments)

# define a macro to create a Windows Exe target
#
# example:
# add_qt_windows_exe(my_app
#     NAME "My App"
#     VERSION "1.2.3"
#     PUBLISHER "My Company"
#     PRODUCT_URL "www.myapp.com"
#     PACKAGE "org.mycompany.myapp"
#     FILE_EXTENSION "appExtension"
#     ICON "path/to.icon.ico"
#     ICON_RC "path/to.icon.rc"
#     QML_DIR "path/to/qmldir"
#     NO_TRANSATION
#     VERBOSE
#     ALL
#)

macro(add_qt_windows_exe TARGET)

    set(QT_WINDOWS_OPTIONS ALL
        NO_DEPLOY
        NO_INSTALLER
        NO_TRANSLATION
        VERBOSE_INSTALLER
        )
    set(QT_WINDOWS_ONE_VALUE_ARG NAME
        DEPLOY_NAME
        INSTALLER_NAME
        VERSION
        PUBLISHER
        PRODUCT_URL
        PACKAGE
        RUN_PROGRAM
        FILE_EXTENSION
        ICON
        ICON_RC
        DEPENDS
        QML_DIR
        VERBOSE_LEVEL_DEPLOY
        )
    set(QT_WINDOWS_MULTI_VALUE_ARG)
     # parse the macro arguments
    cmake_parse_arguments(ARGWIN "${QT_WINDOWS_OPTIONS}" "${QT_WINDOWS_ONE_VALUE_ARG}" "${QT_WINDOWS_MULTI_VALUE_ARG}" ${ARGN})

    if(ARGWIN_VERBOSE_LEVEL_DEPLOY)
        message(STATUS "---- QtWindowsCMake Configuration ----")
        message(STATUS "TARGET                : ${TARGET}")
        message(STATUS "APP_NAME              : ${ARGWIN_NAME}")
        message(STATUS "DEPLOY_NAME           : ${ARGWIN_DEPLOY_NAME}")
        message(STATUS "INSTALLER_NAME        : ${ARGWIN_INSTALLER_NAME}")
        message(STATUS "VERSION               : ${ARGWIN_VERSION}")
        message(STATUS "PUBLISHER             : ${ARGWIN_PUBLISHER}")
        message(STATUS "PRODUCT_URL           : ${ARGWIN_PRODUCT_URL}")
        message(STATUS "PACKAGE               : ${ARGWIN_PACKAGE}")
        message(STATUS "RUN_PROGRAM           : ${ARGWIN_RUN_PROGRAM}")
        message(STATUS "FILE_EXTENSION        : ${ARGWIN_FILE_EXTENSION}")
        message(STATUS "ICON                  : ${ARGWIN_ICON}")
        message(STATUS "ICON_RC               : ${ARGWIN_ICON_RC}")
        message(STATUS "DEPENDS               : ${ARGWIN_DEPENDS}")
        message(STATUS "QML_DIR               : ${ARGWIN_QML_DIR}")
        message(STATUS "ALL                   : ${ARGWIN_ALL}")
        message(STATUS "NO_DEPLOY             : ${ARGWIN_NO_DEPLOY}")
        message(STATUS "NO_INSTALLER          : ${ARGWIN_NO_INSTALLER}")
        message(STATUS "NO_TRANSLATION        : ${ARGWIN_NO_TRANSLATION}")
        message(STATUS "VERBOSE_LEVEL_DEPLOY  : ${ARGWIN_VERBOSE_LEVEL_DEPLOY}")
        message(STATUS "VERBOSE_INSTALLER     : ${ARGWIN_VERBOSE_INSTALLER}")
        message(STATUS "---- End QtWindowsCMake Configuration ----")
    endif() # ARGWIN_VERBOSE_LEVEL_DEPLOY

    set_target_properties(${TARGET} PROPERTIES WIN32_EXECUTABLE 1)
    if(ARGWIN_ICON_RC)
        target_sources(${TARGET} PUBLIC ${ARGWIN_ICON_RC})
    else(ARGWIN_ICON_RC)
        message(WARNING "No icon rc file specified")
    endif(ARGWIN_ICON_RC)

    # define the application name
    if(ARGWIN_NAME)
        set(QT_WINDOWS_APP_NAME ${ARGWIN_NAME})
    else()
        set(QT_WINDOWS_APP_NAME ${TARGET})
    endif()

    # define the application version
    if(ARGWIN_VERSION)
        set(QT_WINDOWS_APP_VERSION ${ARGWIN_VERSION})
    else()
        set(QT_WINDOWS_APP_VERSION "1.0.0")
    endif()

    # define the application package name
    if(ARGWIN_PACKAGE)
        set(QT_WINDOWS_APP_PACKAGE ${ARGWIN_PACKAGE})
    else()
        set(QT_WINDOWS_APP_PACKAGE org.qtproject.${SOURCE_TARGET})
    endif()

    # define the application deploy target name
    if(ARGWIN_DEPLOY_NAME)
        set(QT_WINDOWS_APP_DEPLOY_NAME ${ARGWIN_DEPLOY_NAME})
    else()
        set(QT_WINDOWS_APP_DEPLOY_NAME ${TARGET}Deploy)
    endif()

    # ────────── DEPLOY ─────────────────────────

    if(NOT ARGWIN_NO_DEPLOY)

        # When not using msvc we need to use a dedicated build directory for the target
        # With msvc the executable is generated inside a Release/ or Debug/ folder
        if(NOT MSVC_IDE)
            set_target_properties(${TARGET}
                PROPERTIES
                ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib"
                LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib"
                RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
           )
        endif() # NOT MSVC_IDE

        # define the application qml dirs
        if(ARGWIN_QML_DIR)
            set(QT_WINDOWS_APP_QML_DIR --qmldir ${ARGWIN_QML_DIR})
        endif()
        # define the application package name

        if(ARGWIN_NO_TRANSLATION)
            set(QT_WINDOWS_APP_NO_TRANSLATION --no-translations)
        endif()

        if(ARGWIN_ALL)
            set(QT_WINDOWS_ALL ALL)
        endif()

        # Create Custom Target
        add_custom_target(${QT_WINDOWS_APP_DEPLOY_NAME}
            ${QT_WINDOWS_ALL}
            DEPENDS ${TARGET} ${ARGWIN_DEPENDS}
            COMMAND ${QT_WINDOWS_QT_ROOT}/bin/windeployqt
            ${QT_WINDOWS_APP_QML_DIR}
            ${QT_WINDOWS_APP_NO_TRANSLATION}
            --$<$<CONFIG:Debug>:debug>$<$<NOT:$<CONFIG:Debug>>:release>
            $<TARGET_FILE_DIR:${TARGET}>
            COMMENT "call ${QT_WINDOWS_QT_ROOT}/bin/windeployqt"
           )

        # DEPLOY MSVC RUNTIME
        if(MSVC)
            INCLUDE(InstallRequiredSystemLibraries)
            add_custom_command(TARGET ${QT_WINDOWS_APP_DEPLOY_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS} $<TARGET_FILE_DIR:${TARGET}>
                COMMENT "Deploy msvc runtime libraries : ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}"

            )
        # DEPLOY MINGW C RUNTIME
        else() # MSVC
            add_custom_command(TARGET ${QT_WINDOWS_APP_DEPLOY_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${QT_WINDOWS_QT_ROOT}/bin/libgcc_s_dw2-1.dll $<TARGET_FILE_DIR:${TARGET}>
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${QT_WINDOWS_QT_ROOT}/bin/libstdc++-6.dll $<TARGET_FILE_DIR:${TARGET}>
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${QT_WINDOWS_QT_ROOT}/bin/libwinpthread-1.dll $<TARGET_FILE_DIR:${TARGET}>
                COMMENT "Deploy mingw runtime libraries from ${QT_WINDOWS_QT_ROOT}/bin"
            )

        endif() # MSVC

    endif() # NOT ARGWIN_NO_DEPLOY

    # ────────── QBC INSTALLER ─────────────────────────

    if(NOT ARGWIN_NO_INSTALLER)

        if(ARGWIN_INSTALLER_NAME)
            set(QT_WINDOWS_INSTALLER_NAME INSTALLER_NAME ${ARGWIN_INSTALLER_NAME})
        endif() # ARGWIN_INSTALLER_NAME

        if(NOT ARGWIN_NO_DEPLOY)
            set( QT_WINDOWS_INSTALLER_ADD_DEPLOY ${QT_WINDOWS_APP_DEPLOY_NAME})
        endif() # NOT ARGWIN_NO_DEPLOY

        if(ARGWIN_VERBOSE_INSTALLER)
            set( QT_WINDOWS_VERBOSE_INSTALLER VERBOSE_INSTALLER)
        endif() # ARGWIN_VERBOSE_INSTALLER

        if(ARGWIN_RUN_PROGRAM)
            set( QT_WINDOWS_RUN_PROGRAM RUN_PROGRAM ${ARGWIN_RUN_PROGRAM})

        endif() # ARGWIN_RUN_PROGRAM

        message(STATUS "Add Qt Binary Creator Target for ${TARGET}")
        add_qt_binary_creator( ${TARGET}
            ${QT_WINDOWS_ALL}
            DEPENDS ${QT_WINDOWS_INSTALLER_ADD_DEPLOY} ${ARGWIN_DEPENDS}
            NAME ${QT_WINDOWS_APP_NAME}
            VERSION ${QT_WINDOWS_APP_VERSION}
            PRODUCT_URL ${ARGWIN_PRODUCT_URL}
            ${QT_WINDOWS_INSTALLER_NAME}
            PUBLISHER ${ARGWIN_PUBLISHER}
            ${QT_WINDOWS_RUN_PROGRAM}
            ICON ${ARGWIN_ICON}
            PACKAGE ${ARGWIN_PACKAGE}
            ${QT_WINDOWS_VERBOSE_INSTALLER}
            FILE_EXTENSION ${ARGWIN_FILE_EXTENSION}
           )

    endif() # NOT ARGWIN_NO_INSTALLER
endmacro() # add_qt_windows_exe
