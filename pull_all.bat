@echo off

echo. Updating main:
git pull

echo. Updating android:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/android
git pull

echo. Updating android_ouya:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/android_ouya
git pull

echo. Updating cpptool:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/cpptool
git pull

echo. Updating flash:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/flash
git pull

echo. Updating glfw:
cd targets/glfw
git pull

echo. Updating glfw_steam:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/glfw_steam
git pull

echo. Updating glfw3:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/glfw3
git pull

echo. Updating html5:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/html5
git pull

echo. Updating ios:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/ios
git pull

echo. Updating javatool:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/javatool
git pull

echo. Updating ps4:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/ps4
git pull

echo. Updating psm:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/psm
git pull

echo. Updating winrt_win8:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/winrt_win8
git pull

echo. Updating winrt_winphone8:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/winrt_winphone8
git pull

echo. Updating xboxone:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/xboxone
git pull

echo. Updating xna:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/targets/xna
git pull

echo. Updating brl:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/brl
git pull

echo. Updating dom:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/dom
git pull

echo. Updating harmony:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/harmony
git pull

echo. Updating mojo:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/mojo
git pull

echo. Updating monkey:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/monkey
git pull

echo. Updating opengl:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/opengl
git pull

echo. Updating os:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/os
git pull

echo. Updating reflection:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/reflection
git pull

echo. Updating trans:
cd %GLOOMYWOOD_DEV%/Dependencies/mungo/modules/trans
git pull
