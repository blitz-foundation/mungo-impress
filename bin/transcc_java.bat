@echo off

set PATH=%PATH%;C:\Program Files (x86)\Java\jre8\bin
set PATH=%PATH%;C:\Program Files\Java\jre8\bin
set PATH=%PATH%;C:\Program Files (x86)\Java\jre7\bin
set PATH=%PATH%;C:\Program Files\Java\jre7\bin
set PATH=%PATH%;C:\Program Files (x86)\Java\jre6\bin
set PATH=%PATH%;C:\Program Files\Java\jre6\bin

set MONKEY_APP_DIR=%~dp0
set MONKEY_APP_PATH=%~0

java -jar "%MONKEY_APP_DIR%\transcc_java.jar" %*
