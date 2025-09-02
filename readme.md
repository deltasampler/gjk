# GJK
In this project I attempt to implement GJK and EPA collision detection algorithms

If you don't have Odin setup, then check [Odin Setup](#odin-setup) section.

If you want to setup Odin Language Server (OLS), then check [OLS Setup](#ols-setup) section.

## Table of Contents
- [Requirements](#requirements)
  - [Windows](#windows)
  - [Ubuntu](#ubuntu)
- [Usage](#usage)
- [Odin Setup](#odin-setup)
  - [Windows](#windows-1)
  - [Ubuntu](#ubuntu-1)
- [OLS Setup](#ols-setup)
  - [Windows](#windows-2)
  - [Ubuntu](#ubuntu-2)
- [OLS in VS Code](#ols-in-vs-code)
- [OLS in Sublime Text](#ols-in-sublime-text)
- [Debugging](#debugging)
## Requirements
Although SDL3 is included in Odin vendor, it might be missing library binaries for your platform, so you need to make sure you can build SDL3 yourself.
### Windows
* This guide assumes you have Visual Studio (Desktop development with C++) installed
* On Windows you can just copy SDL3 library binaries from Odin vendor directory into place where your executable is located, in this template that will be `build/output`
* Alternatively you can download SDL3 library binaries from Odin repo into `build/output` by running:

      .\build.bat get-sdl3
* If you want to build SDL3 library binaries yourself, then
  * Locate `VsDevCmd.bat` and set the `VSDEVCMD` variable in `build.bat` to its path
  * Run build script

        .\build.bat build-sdl3
### Ubuntu
* If SDL3 package is available through apt, then

      sudo apt update
      sudo apt install libsdl3-dev
* If SDL3 package is not available through apt, then build it yourself
  * Install dependencies

        sudo apt update
        sudo apt install build-essential cmake git gnome-desktop-testing libasound2-dev libaudio-dev libdbus-1-dev libdecor-0-dev libdrm-dev libegl1-mesa-dev libgbm-dev libgl1-mesa-dev libgles2-mesa-dev libibus-1.0-dev libjack-dev libpipewire-0.3-dev libpulse-dev libsndio-dev libudev-dev liburing-dev libwayland-dev libx11-dev libxcursor-dev libxext-dev libxfixes-dev libxi-dev libxkbcommon-dev libxrandr-dev libxss-dev libxtst-dev make ninja-build pkg-config
  * Run build script

        ./build.sh build-sdl3
## Usage
    # Build executable
    ./build.bat build

    # Build executable in debug mode
    ./build.bat build-debug

    # Build executable and run
    ./build.bat run

    # Build executable and run in debug mode
    ./build.bat run-debug
## Odin Setup
For more information check [official installation guide](https://odin-lang.org/docs/install/)
### Windows
* Download and install [Visual Studio](https://visualstudio.microsoft.com/) (Desktop development with C++)
* Clone Odin repository and run build script

      git clone https://github.com/odin-lang/Odin.git odin
      cd odin
      .\build.bat release
      del build.bat
* Add Odin directory to path in **Environment Variables**
### Ubuntu
* Install clang

      sudo apt install clang
* Clone Odin repository and run build script

      git clone https://github.com/odin-lang/Odin.git odin
      cd odin
      ./build_odin.sh release
* Add Odin directory to path in `.bashrc`

      echo 'export PATH="$PATH:<PATH_TO_ODIN>"' >> ~/.bashrc

      # if you have Odin in home directory
      echo 'export PATH="$PATH:$HOME/odin"' >> ~/.bashrc
## OLS Setup
OLS is Odin Language Server, for more information check [OLS repository](https://github.com/DanielGavin/ols)
### Windows
* Clone OLS repository and run build script

      git clone https://github.com/DanielGavin/ols.git
      cd ols
      .\build.bat
* Add OLS directory to path in **Environment Variables**
### Ubuntu
* Clone OLS repository and run build script

      git clone https://github.com/DanielGavin/ols.git
      cd ols
      ./build.sh
* Add OLS directory to path in `.bashrc`

      echo 'export PATH="$PATH:<PATH_TO_OLS>"' >> ~/.bashrc

      # if you have OLS in home directory
      echo 'export PATH="$PATH:$HOME/ols"' >> ~/.bashrc
## OLS in VS Code
* Install [OLS extension](https://marketplace.visualstudio.com/items?itemName=DanielGavin.ols)
* If you have OLS added to path, then set `ols.server.path` to `ols`
* If you don't have OLS added to path, then set `ols.server.path` to actual path of OLS executable
* Set `ODIN_ROOT` environment variable to path of Odin directory
* Optionally you can create `ols.json` file in project folder to configure OLS, check schema for more info

      {
          "$schema": "https://raw.githubusercontent.com/DanielGavin/ols/master/misc/ols.schema.json",
          "enable_semantic_tokens": false,
          "enable_document_symbols": true,
          "enable_hover": true,
          "enable_snippets": true,
          "profile": "default",
          "profiles": [
              {
                  "name": "default",
                  "checker_path": ["source"]
              },
          ]
      }
## OLS in Sublime Text
* First you need to have [Package Control](https://github.com/wbond/package_control) installed
* To install, open console by clicking `View > Show Console` in menu bar and run this command:

      from urllib.request import urlretrieve;urlretrieve(url="https://github.com/wbond/package_control/releases/latest/download/Package.Control.sublime-package", filename=sublime.installed_packages_path() + '/Package Control.sublime-package')
* Open Command Palette and search for `Install Package`, then install these packages: `Odin` and `LSP`
* To configure OLS, open LSP settings by clicking `Preferences > Package Settings > LSP > Settings`
* Paste this into settings
  * This assumes you have OLS executable in path, otherwise set full path yourself in `command` array
  * This has OLS enabled for all projects, set `enabled` to `false` if you don't want that

        {
            "clients": {
                "odin": {
                    "command": [
                        "ols"
                    ],
                    "enabled": true,
                    "selector": "source.odin",
                    "initializationOptions": {
                        "enable_semantic_tokens": true,
                        "enable_document_symbols": true,
                        "enable_hover": true,
                        "enable_snippets": true,
                        "enable_format": true,
                    }
                }
            }
        }
* To enable OLS for specific projects, you need to have `.sublime-project` file in your folder
* Open Command Palette and search for `LSP Enable in Project`, then select `odin`
## Debugging
For debugging you can use [RAD Debugger](https://github.com/EpicGamesExt/raddebugger)
* Build odin in debug mode and then attach executable to RAD Debugger
* After that you can put breakpoints and run it
