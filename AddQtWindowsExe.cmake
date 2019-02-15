cmake_minimum_required(VERSION 3.0)

# find the Qt root directory
if(NOT Qt5Core_DIR)
    find_package(Qt5Core REQUIRED)
endif(NOT Qt5Core_DIR)
get_filename_component(QT_WINDOWS_QT_ROOT "${Qt5Core_DIR}/../../.." ABSOLUTE)
message(STATUS "Found Qt for Windows: ${QT_WINDOWS_QT_ROOT}")

set(QT_WINDOWS_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH};${QT_WINDOWS_SOURCE_DIR}/cmake)

include(CMakeParseArguments)

# define a macro to create a Windows Exe target
#
# example:
# add_qt_windows_exe(my_app
#     NAME "My App"
#     VERSION "1.2.3"
#	  PUBLISHER "My Company"
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
	SET(QT_WINDOWS_OPTIONS 
		ALL
		NO_DEPLOY
		NO_INSTALLER
		NO_TRANSLATION
		VERBOSE_INSTALLER
		)
	SET(QT_WINDOWS_ONE_VALUE_ARG 
		NAME 
		DEPLOY_NAME 
		INSTALLER_NAME 
		VERSION PUBLISHER 
		PRODUCT_URL PACKAGE 
		FILE_EXTENSION
		ICON
		ICON_RC
		DEPENDS
		QML_DIR 
		VERBOSE_LEVEL_DEPLOY
		)
	 # parse the macro arguments
    cmake_parse_arguments(ARG "${QT_WINDOWS_OPTIONS}" "${QT_WINDOWS_ONE_VALUE_ARG}" ${ARGN})

    MESSAGE(STATUS "QtWindowsCMake Configuration")
    MESSAGE(STATUS "TARGET:                 ${TARGET}")
    MESSAGE(STATUS "NAME:                   ${ARG_NAME}")
    MESSAGE(STATUS "DEPLOY_NAME:            ${ARG_DEPLOY_NAME}")
    MESSAGE(STATUS "INSTALLER_NAME:         ${ARG_INSTALLER_NAME}")
    MESSAGE(STATUS "VERSION:                ${ARG_VERSION}")
    MESSAGE(STATUS "PUBLISHER:              ${ARG_PUBLISHER}")
    MESSAGE(STATUS "PRODUCT_URL:            ${ARG_PRODUCT_URL}")
    MESSAGE(STATUS "PACKAGE:                ${ARG_PACKAGE}")
    MESSAGE(STATUS "FILE_EXTENSION:         ${ARG_FILE_EXTENSION}")
    MESSAGE(STATUS "ICON:                   ${ARG_ICON}")
    MESSAGE(STATUS "ICON_RC:                ${ARG_ICON_RC}")
    MESSAGE(STATUS "DEPENDS:                ${ARG_DEPENDS}")
    MESSAGE(STATUS "QML_DIR:                ${ARG_QML_DIR}")
    MESSAGE(STATUS "ALL:                    ${ARG_ALL}")
    MESSAGE(STATUS "NO_DEPLOY:              ${ARG_NO_DEPLOY}")
    MESSAGE(STATUS "NO_INSTALLER:           ${ARG_NO_INSTALLER}")
    MESSAGE(STATUS "NO_TRANSLATION:         ${ARG_NO_TRANSLATION}")
    MESSAGE(STATUS "VERBOSE_LEVEL_DEPLOY:   ${ARG_VERBOSE_LEVEL_DEPLOY}")
    MESSAGE(STATUS "VERBOSE_INSTALLER:      ${ARG_VERBOSE_INSTALLER}")

    SET_TARGET_PROPERTIES(${TARGET} PROPERTIES WIN32_EXECUTABLE 1)
    IF(ARG_ICON_RC)
    TARGET_SOURCES(${TARGET} PUBLIC ${ARG_ICON_RC} )
	ELSE(ARG_ICON_RC)
		MESSAGE(WARNING "No icon rc file specified")
	ENDIF(ARG_ICON_RC)

    # define the application name
    if(ARG_NAME)
        set(QT_WINDOWS_APP_NAME ${ARG_NAME})
    else()
        set(QT_WINDOWS_APP_NAME ${TARGET})
    endif()

    # define the application version
    if(ARG_VERSION)
        set(QT_WINDOWS_APP_VERSION ${ARG_VERSION})
    else()
        set(QT_WINDOWS_APP_VERSION "1.0.0")
    endif()

    # define the application package name
    if(ARG_PACKAGE)
        set(QT_WINDOWS_APP_PACKAGE ${ARG_PACKAGE})
    else()
        set(QT_WINDOWS_APP_PACKAGE org.qtproject.${SOURCE_TARGET})
    endif()

    # define the application deploy target name
    if(ARG_DEPLOY_NAME)
        set(QT_WINDOWS_APP_DEPLOY_NAME ${ARG_DEPLOY_NAME})
    else()
        set(QT_WINDOWS_APP_DEPLOY_NAME ${TARGET}Deploy)
    endif()

	# ────────── DEPLOY ─────────────────────────

	IF(NOT ARG_NO_DEPLOY)

		# When not using msvc we need to use a dedicated build directory for the target
		# With msvc the executable is generated inside a Release/ or Debug/ folder
	    IF( NOT MSVC )
			SET_TARGET_PROPERTIES( ${TARGET}
				PROPERTIES
				ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib"
				LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib"
				RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin"
			)
		ENDIF( NOT MSVC )

	    # define the application qml dirs
	    if(ARG_QML_DIR)
	        set(QT_WINDOWS_APP_QML_DIR --qmldir ${ARG_QML_DIR})
	    endif()
	    # define the application package name

	    if(ARG_NO_TRANSLATION)
	        set(QT_WINDOWS_APP_NO_TRANSLATION --no-translations)
	    endif()

		# Create Custom Target
		ADD_CUSTOM_TARGET(${QT_WINDOWS_APP_DEPLOY_NAME}
			ALL
			DEPENDS ${TARGET} ${ARG_DEPENDS}
			COMMAND ${QT_WINDOWS_QT_ROOT}/bin/windeployqt 
			${QT_WINDOWS_APP_QML_DIR}
			${QT_WINDOWS_APP_NO_TRANSLATION}
			--$<$<CONFIG:Debug>:debug>$<$<NOT:$<CONFIG:Debug>>:release>
			$<TARGET_FILE_DIR:${TARGET}>
			)

		# DEPLOY MSVC RUNTIME
		IF( MSVC ) 
			INCLUDE(InstallRequiredSystemLibraries)
			ADD_CUSTOM_COMMAND(TARGET ${QT_WINDOWS_APP_DEPLOY_NAME} POST_BUILD
				COMMAND echo Deploy msvc runtime libraries : ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS}
				COMMAND ${CMAKE_COMMAND} -E copy_if_different ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS} $<TARGET_FILE_DIR:${TARGET}>)
		# DEPLOY MINGW C RUNTIME
		ELSE( MSVC )
			ADD_CUSTOM_COMMAND(TARGET ${QT_WINDOWS_APP_DEPLOY_NAME} POST_BUILD
				COMMAND echo Deploy mingw runtime libraries from ${QT_WINDOWS_QT_ROOT}/bin
				COMMAND ${CMAKE_COMMAND} -E copy_if_different ${QT_WINDOWS_QT_ROOT}/bin/libgcc_s_dw2-1.dll $<TARGET_FILE_DIR:${TARGET}>
				COMMAND ${CMAKE_COMMAND} -E copy_if_different ${QT_WINDOWS_QT_ROOT}/bin/libstdc++-6.dll $<TARGET_FILE_DIR:${TARGET}>
				COMMAND ${CMAKE_COMMAND} -E copy_if_different ${QT_WINDOWS_QT_ROOT}/bin/libwinpthread-1.dll $<TARGET_FILE_DIR:${TARGET}>)
		ENDIF( MSVC )

	ENDIF( NOT ARG_NO_DEPLOY )

	# ────────── QBC INSTALLER ─────────────────────────

	IF(NOT ARG_NO_INSTALLER)

		SET( QBC_DEPENDS_TARGET ${TARGET} )
		SET( QBC_NAME ${QT_WINDOWS_APP_NAME} CACHE STRING "Application Name" )
		SET( QBC_INSTALLER_TARGET_NAME ${ARG_INSTALLER_NAME} CACHE STRING "" )
		IF(ARG_NO_DEPLOY)
			SET( QBC_ADDITIONNAL_DEPENDS ${TARGET} )
		ELSE(ARG_NO_DEPLOY)
			SET( QBC_ADDITIONNAL_DEPENDS ${QT_WINDOWS_APP_DEPLOY_NAME} )
		ENDIF(ARG_NO_DEPLOY)
		SET( QBC_PUBLISHER ${ARG_PUBLISHER} CACHE STRING "Application Publisher" )
		SET( QBC_PRODUCT_URL ${ARG_PRODUCT_URL} CACHE STRING "Application product Url" )
		SET( QBC_VERSION ${QT_WINDOWS_APP_VERSION} CACHE STRING "Application Version" )
		SET( QBC_PACKAGE ${ARG_PACKAGE} CACHE STRING "Application Package" )
		SET( QBC_ICON_PATH ${ARG_ICON} CACHE STRING "Installer icon path" )
		SET( QBC_FILE_EXTENSION ${ARG_FILE_EXTENSION} CACHE STRING "File extension for file association (only supported on windows)" )
		IF(ARG_VERBOSE_INSTALLER)
			SET( QBC_VERBOSE ON CACHE BOOL "Installer Verbose" )
		ENDIF(ARG_VERBOSE_INSTALLER)

		INCLUDE(${QT_WINDOWS_SOURCE_DIR}/cmake/BuildQBCInstaller.cmake)

	ENDIF(NOT ARG_NO_INSTALLER)
endmacro(add_qt_windows_exe)