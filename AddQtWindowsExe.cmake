cmake_minimum_required(VERSION 3.0)

# find the Qt root directory
if(NOT Qt5Core_DIR)
    find_package(Qt5Core REQUIRED)
endif(NOT Qt5Core_DIR)
get_filename_component(QT_WINDOWS_QT_ROOT "${Qt5Core_DIR}/../../.." ABSOLUTE)
message(STATUS "Found Qt for Windows: ${QT_WINDOWS_QT_ROOT}")

set(QT_WINDOWS_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH};${QT_WINDOWS_SOURCE_DIR}/cmake)

IF(QBC_FOUND AND NOT QT_WINDOWS_CMAKE_DOWNLOAD_QBC)
	MESSAGE( STATUS "Found QBC" )
ELSE(QBC_FOUND AND NOT QT_WINDOWS_CMAKE_DOWNLOAD_QBC)
	SET(QT_WINDOWS_CMAKE_DOWNLOAD_QBC ON CACHE BOOL "The Qbc library have been downloaded")
	INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/cmake/BuildQBCInstaller.cmake)
	IF(NOT QBC_FOUND)
		MESSAGE( FATAL_ERROR "Fail to configure Qbc Library" )
	ENDIF(NOT QBC_FOUND)
ENDIF(QBC_FOUND AND NOT QT_WINDOWS_CMAKE_DOWNLOAD_QBC)

SET(QT_WINDOWS_CMAKE_FOUND ON CACHE BOOL "QtWindowsCMake have been found" FORCE)

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

	SET(QT_WINDOWS_OPTIONS ALL
		NO_DEPLOY
		NO_INSTALLER
		NO_TRANSLATION
		VERBOSE_INSTALLER
		)
	SET(QT_WINDOWS_ONE_VALUE_ARG APP_NAME 
		DEPLOY_NAME 
		INSTALLER_NAME 
		VERSION 
		PUBLISHER 
		PRODUCT_URL 
		PACKAGE 
		FILE_EXTENSION
		ICON
		ICON_RC
		DEPENDS
		QML_DIR 
		VERBOSE_LEVEL_DEPLOY
		)
	 # parse the macro arguments
    cmake_parse_arguments(ARGWIN "${QT_WINDOWS_OPTIONS}" "${QT_WINDOWS_ONE_VALUE_ARG}" ${ARGN})

    MESSAGE(STATUS QT_WINDOWS_OPTIONS : ${QT_WINDOWS_OPTIONS})
    MESSAGE(STATUS QT_WINDOWS_ONE_VALUE_ARG : ${QT_WINDOWS_ONE_VALUE_ARG})

    MESSAGE(STATUS "QtWindowsCMake Configuration")
    MESSAGE(STATUS "TARGET:                 ${TARGET}")
    MESSAGE(STATUS "APP_NAME:               ${ARGWIN_APP_NAME}")
    MESSAGE(STATUS "DEPLOY_NAME:            ${ARGWIN_DEPLOY_NAME}")
    MESSAGE(STATUS "INSTALLER_NAME:         ${ARGWIN_INSTALLER_NAME}")
    MESSAGE(STATUS "VERSION:                ${ARGWIN_VERSION}")
    MESSAGE(STATUS "PUBLISHER:              ${ARGWIN_PUBLISHER}")
    MESSAGE(STATUS "PRODUCT_URL:            ${ARGWIN_PRODUCT_URL}")
    MESSAGE(STATUS "PACKAGE:                ${ARGWIN_PACKAGE}")
    MESSAGE(STATUS "FILE_EXTENSION:         ${ARGWIN_FILE_EXTENSION}")
    MESSAGE(STATUS "ICON:                   ${ARGWIN_ICON}")
    MESSAGE(STATUS "ICON_RC:                ${ARGWIN_ICON_RC}")
    MESSAGE(STATUS "DEPENDS:                ${ARGWIN_DEPENDS}")
    MESSAGE(STATUS "QML_DIR:                ${ARGWIN_QML_DIR}")
    MESSAGE(STATUS "ALL:                    ${ARGWIN_ALL}")
    MESSAGE(STATUS "NO_DEPLOY:              ${ARGWIN_NO_DEPLOY}")
    MESSAGE(STATUS "NO_INSTALLER:           ${ARGWIN_NO_INSTALLER}")
    MESSAGE(STATUS "NO_TRANSLATION:         ${ARGWIN_NO_TRANSLATION}")
    MESSAGE(STATUS "VERBOSE_LEVEL_DEPLOY:   ${ARGWIN_VERBOSE_LEVEL_DEPLOY}")
    MESSAGE(STATUS "VERBOSE_INSTALLER:      ${ARGWIN_VERBOSE_INSTALLER}")

    SET_TARGET_PROPERTIES(${TARGET} PROPERTIES WIN32_EXECUTABLE 1)
    IF(ARGWIN_ICON_RC)
    TARGET_SOURCES(${TARGET} PUBLIC ${ARGWIN_ICON_RC} )
	ELSE(ARGWIN_ICON_RC)
		MESSAGE(WARNING "No icon rc file specified")
	ENDIF(ARGWIN_ICON_RC)

    # define the application name
    if(ARGWIN_APP_NAME)
        set(QT_WINDOWS_APP_NAME ${ARGWIN_APP_NAME})
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

	IF(NOT ARGWIN_NO_DEPLOY)

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
	    if(ARGWIN_QML_DIR)
	        set(QT_WINDOWS_APP_QML_DIR --qmldir ${ARGWIN_QML_DIR})
	    endif()
	    # define the application package name

	    if(ARGWIN_NO_TRANSLATION)
	        set(QT_WINDOWS_APP_NO_TRANSLATION --no-translations)
	    endif()

	    if(ARGWIN_ALL)
	    	SET(QT_WINDOWS_ALL ALL)
	    endif()

		# Create Custom Target
		ADD_CUSTOM_TARGET(${QT_WINDOWS_APP_DEPLOY_NAME}
			${QT_WINDOWS_ALL}
			DEPENDS ${TARGET} ${ARGWIN_DEPENDS}
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

	ENDIF( NOT ARGWIN_NO_DEPLOY )

	# ────────── QBC INSTALLER ─────────────────────────

	IF(NOT ARGWIN_NO_INSTALLER)

		#INCLUDE(${QT_WINDOWS_SOURCE_DIR}/cmake/BuildQBCInstaller.cmake)

		IF(ARGWIN_INSTALLER_NAME)
			SET(QT_WINDOWS_INSTALLER_NAME INSTALLER_NAME ${ARGWIN_INSTALLER_NAME})
		ENDIF(ARGWIN_INSTALLER_NAME)

		IF(NOT ARGWIN_NO_DEPLOY)
			SET( QT_WINDOWS_INSTALLER_ADD_DEPLOY ${QT_WINDOWS_APP_DEPLOY_NAME} )
		ENDIF(NOT ARGWIN_NO_DEPLOY)

		IF(ARGWIN_VERBOSE_INSTALLER)
			SET( QT_WINDOWS_VERBOSE_INSTALLER VERBOSE_INSTALLER)
		ENDIF(ARGWIN_VERBOSE_INSTALLER)

		add_qt_binary_creator( ${TARGET} 
			DEPENDS ${QT_WINDOWS_INSTALLER_ADD_DEPLOY} ${ARGWIN_DEPENDS}
			NAME ${QT_WINDOWS_APP_NAME}
			VERSION ${QT_WINDOWS_APP_VERSION}
			PRODUCT_URL ${ARGWIN_PRODUCT_URL}
			${QT_WINDOWS_INSTALLER_NAME}
			PUBLISHER ${ARGWIN_PUBLISHER}
			ICON ${ARGWIN_ICON}
			PACKAGE ${ARGWIN_PACKAGE}
			${QT_WINDOWS_VERBOSE_INSTALLER}
			FILE_EXTENSION ${ARGWIN_FILE_EXTENSION}
			)

	ENDIF(NOT ARGWIN_NO_INSTALLER)
endmacro(add_qt_windows_exe)