rem Generate Lua files from Lau sources
@echo off
setlocal
pushd "%~dp0"

rem LuaJIT interpreter and the lauzy compiler (bin/lau.zy is dependency free bytecode)
if not defined LUAJIT set "LUAJIT=luajit"
if not defined LAUZY set "LAUZY=%~dp0..\lauzy\bin\lau.zy"

rem -f overwrites existing .lua, -d ngx declares the OpenResty global
rem add -t to enable the optional type checker
set "LAUFLAGS=-f -d ngx"

%LUAJIT% "%LAUZY%" %LAUFLAGS% stripe lib\resty\stripe.lua
if errorlevel 1 goto :fail
%LUAJIT% "%LAUZY%" %LAUFLAGS% stripe_webhook lib\resty\stripe_webhook.lua
if errorlevel 1 goto :fail
%LUAJIT% "%LAUZY%" %LAUFLAGS% sample\credential sample\credential.lua
if errorlevel 1 goto :fail
%LUAJIT% "%LAUZY%" %LAUFLAGS% sample\helper sample\helper.lua
if errorlevel 1 goto :fail
%LUAJIT% "%LAUZY%" %LAUFLAGS% sample\sample sample\sample.lua
if errorlevel 1 goto :fail

popd
endlocal
exit /b 0

:fail
popd
endlocal
exit /b 1
