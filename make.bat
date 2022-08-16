rem Generate Lua file
@echo off
set LUAJIT=\app\lua\luajit.exe
set LTFLAGS=\luaty\lt.lua -f -t -d ngx
set PACKAGE="package.path=package.path .. '/luaty/?.lua'"
%LUAJIT% -e %PACKAGE% %LTFLAGS% stripe .\lib\resty\
%LUAJIT% -e %PACKAGE% %LTFLAGS% stripe_webhook .\lib\resty\
pushd sample
%LUAJIT% -e %PACKAGE% %LTFLAGS% credential credential.lua
%LUAJIT% -e %PACKAGE% %LTFLAGS% helper helper.lua
%LUAJIT% -e %PACKAGE% %LTFLAGS% sample sample.lua
popd
