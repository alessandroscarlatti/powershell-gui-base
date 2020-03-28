@if "%DEBUG%"=="" @echo off
powershell -sta ./src/main/Application.ps1
exit /b %ERRORLEVEL%