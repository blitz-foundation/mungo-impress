@echo off

echo. Updating main:
git pull

echo. Updating android:
cd targets/android
git pull
cd ../..

echo. Updating android_ouya:
cd targets/android_ouya
git pull
cd ../..

echo. Updating cpptool:
cd targets/cpptool
git pull
cd ../..

echo. Updating flash:
cd targets/flash
git pull
cd ../..

echo. Updating glfw:
cd targets/glfw
git pull
cd ../..

echo. Updating glfw_steam:
cd targets/glfw_steam
git pull
cd ../..

echo. Updating glfw3:
cd targets/glfw3
git pull
cd ../..

echo. Updating html5:
cd targets/html5
git pull
cd ../..

echo. Updating ios:
cd targets/ios
git pull
cd ../..

echo. Updating javatool:
cd targets/javatool
git pull
cd ../..

echo. Updating ps4:
cd targets/ps4
git pull
cd ../..

echo. Updating psm:
cd targets/psm
git pull
cd ../..

echo. Updating winrt_win8:
cd targets/winrt_win8
git pull
cd ../..

echo. Updating winrt_winphone8:
cd targets/winrt_winphone8
git pull
cd ../..

echo. Updating xboxone:
cd targets/xboxone
git pull
cd ../..

echo. Updating xna:
cd targets/xna
git pull
cd ../..

echo. Updating brl:
cd modules/brl
git pull
cd ../..

echo. Updating dom:
cd modules/dom
git pull
cd ../..

echo. Updating harmony:
cd modules/harmony
git pull
cd ../..

echo. Updating mojo:
cd modules/mojo
git pull
cd ../..

echo. Updating monkey:
cd modules/monkey
git pull
cd ../..

echo. Updating opengl:
cd modules/opengl
git pull
cd ../..

echo. Updating os:
cd modules/os
git pull
cd ../..

echo. Updating reflection:
cd modules/reflection
git pull
cd ../..

echo. Updating trans:
cd modules/trans
git pull
