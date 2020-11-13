# Qt Windows CMake

## What it is

This project provide a CMake macro to help you deploy Qt application on windows. It will generate a deploy target that:

* Deploy dynamic Qt library near your executable file to create a self-contain application folder.
* Deploy msvc or mingw c++ runtime library.

It will also generate an installer project that will:

* Create a win32 installer to install your application and share your application easily.

The macro will call program for the qt framework.

* `windeployqt` to deploy dynamic library and qml. Documentation is available [here](https://doc.qt.io/qt-5/windows-deployment.html).
* `qtinstallerframework` to create installer. Documentation is available [here](https://doc.qt.io/qtinstallerframework/ifw-tools.html).
  * Behind the scene, the macro will call QtBinaryCreatorCMake project.

This utility has been developed for my own needs. Don't hesitate to use / share / fork / modify / improve it freely :)

This project is conceptually based on the great [QtAndroidCMake of Laurent Gomila](https://github.com/LaurentGomila/qt-android-cmake).

## How to use it

### How to integrate it to your CMake configuration

All you have to do is to call the ```add_qt_windows_exe``` macro to create a new target that will create the Windows Deployment Targets.

```cmake
if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
    FetchContent_Declare(
            QtWindowsCMake
            GIT_REPOSITORY "https://github.com/OlivierLDff/QtWindowsCMake"
            GIT_TAG        master
        )
    FetchContent_MakeAvailable(QtWindowsCMake)
    add_qt_windows_exe(MyApp)
endif()
```

The you can simply run

```bash
make MyAppDeploy
make MyAppInstaller
```

Of course, ```add_qt_windows_exe``` accepts more options, see below for the detail.

### How to run CMake

To build the application for windows it is required to already be on a windows machine. It is recommended to export the path as global variable.

```bash
export QT_WIN_VERSION=5.12.0
export QT_DIR_MINGW32=C:/Qt/$QT_WIN_VERSION/mingw53_32
export QT_DIR_MINGW64=C:/Qt/$QT_WIN_VERSION/mingw53_64
export QT_DIR_MSVC32=C:/Qt/$QT_WIN_VERSION1/msvc2017_32
export QT_DIR_MSVC64=C:/Qt/$QT_WIN_VERSION/msvc2017_64
export QT_BUILD_TYPE=Release #  or export QT_BUILD_TYPE=Debug
```

**MinGw 32 bits - Make**

```bash
cmake -DCMAKE_PREFIX_PATH=$QT_DIR_MINGW32 \
-G "Unix Makefiles" -DCMAKE_BUILD_TYPE=$QT_BUILD_TYPE path/to/CMakeLists/
```

**MinGw 64 bits - Ninja**

```bash
cmake -DCMAKE_PREFIX_PATH=$QT_DIR_MINGW64 \
-G "Ninja" -DCMAKE_BUILD_TYPE=$QT_BUILD_TYPE path/to/CMakeLists/
```

**Msvc 32 bits *(Default)***

```bash
cmake -DCMAKE_PREFIX_PATH=$QT_DIR_MSVC32 \
-G "Visual Studio 15 2017" path/to/CMakeLists/
```

**Msvc 64 bits**

```bash
cmake -DCMAKE_PREFIX_PATH=$QT_DIR_MSVC64 \
-G "Visual Studio 15 2017 Win64" path/to/CMakeLists/
```

## Options of the ```add_qt_windows_exe``` macro

The first argument is the target the macro should deploy an app for. It will automatically generate 2 targets:

* `${MY_TARGET}Deploy` that deploy dynamic library and qmldir.
* `${MY_TARGET}Installer` that pack and generate an installer.

The macro also accepts optional named arguments. Any combination of these arguments is valid. Example:

```cmake
add_qt_windows_exe(my_app
    NAME "My App"
    VERSION "1.2.3"
    PUBLISHER "My Company"
    PRODUCT_URL "www.myapp.com"
    PACKAGE "org.mycompany.myapp"
    FILE_EXTENSION "appExtension"
    ICON "path/to.icon.rc"
    ICON_RC "path/to.icon.rc"
    QML_DIR "path/to/qmldir"
    NO_TRANSLATION
    NO_OPENGL_SW
    NO_ANGLE
    VERBOSE_LEVEL_DEPLOY 1
    VERBOSE_INSTALLER
    ALL
 )
```

Here is the full list of possible arguments:

**NAME**

The name of the application. If not given, the name of the source target is taken. The default is `${TARGET}`.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    NAME "My App"
)
```

**DEPLOY_NAME**

Name of the deploy target. The default is `${TARGET}Deploy`.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    DEPLOY_NAME "MyAppDeployName"
)
```

 You can then run this target with `make MyAppDeployName` .

**INSTALLER_NAME**

Name of the installer target. The default is `${TARGET}InstallerX64` or  `${TARGET}InstallerX32` depending is 32 bits or 64 bits is selected.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    INSTALLER_NAME "MyAppInstallerName"
)
```

 You can then run this target with `make MyAppInstallerName` .

**VERSION**

Literal version that will be displayed with the application. The default is `1.0.0`.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    VERSION "1.2.3"
)
```

**PUBLISHER**

Literal version that will be displayed with the application.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    PUBLISHER "My Company"
)
```

**PRODUCT_URL**

Literal version that will be displayed with the application.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    PRODUCT_URL "www.myapp.com"
)
```

**PACKAGE**

The name of the application package. If not given, `org.qtproject.${TARGET}` , where source_target is the name of the source target, is taken.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    PACKAGE "org.mycompany.myapp"
)
```

**RUN_PROGRAM**

The program to run with the generated shortcut on install. By default it is set to `${NAME}`.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    RUN_PROGRAM "MyApp"
)
```

**FILE_EXTENSION**

You can specify extension that will be associate with you app.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    FILE_EXTENSION "appExtension"
)
```

**ICON**

The icon that will be used for the generated installer executable

*Example:*

```cmake
add_qt_windows_exe(MyApp
    ICON "path/to/icon.ico"
)
```

**ICON_RC**

The icon rc file for the application. `icon.rc` might look like this *(More info about ressources files [here](https://docs.microsoft.com/en-us/cpp/ide/resource-files-cpp?view=vs-2017))*:

```
IDI_ICON1               ICON    DISCARDABLE     "icon.ico"
```

And the file structure:

```
windows
│ icon.rc
│ icon.ico
```

*Example:*

```cmake
add_qt_windows_exe(MyApp
    ICON_RC "path/to/icon.rc"
)
```

**QML_DIR**

Literal version that will be displayed with the application.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    QML_DIR "path/to/qml/to/deploy"
)
```

**DEPENDS**

Additional targets to depend on.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    DEPENDS additional_target
)
```

**ALL**

If the deploy and installer is run when typing `make all`

*Example:*

```cmake
add_qt_windows_exe(MyApp
    ALL
)
```

**NO_DEPLOY**

Don't create the deploy target.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    NO_DEPLOY
)
```

**NO_INSTALLER**

Don't create the installer target.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    NO_INSTALLER
)
```

**NO_TRANSLATION**

Skip deployment of translations.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    NO_TRANSLATION
)
```

**NO_OPENGL_SW**

Do not deploy the software rasterizer library.
Disable deployment of `opengl32sw.dll` (20Mo).

**NO_ANGLE**

Disable deployment of ANGLE. (`libEGL.dll` & `libGLESv2.dll`)

**VERBOSE_LEVEL_DEPLOY**

If you want to see all of the output of `qtwindeploy`. This can be really useful when debugging. The default is 1.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    VERBOSE_LEVEL_DEPLOY 1
)
```

**VERBOSE_INSTALLER**

If you want to see all of the output of `binarycreator`. This can be really useful when debugging.

*Example:*

```cmake
add_qt_windows_exe(MyApp
    VERBOSE_INSTALLER
)
```

## Contact

* Olivier Le Doeuff: olivier.ldff@gmail.com
