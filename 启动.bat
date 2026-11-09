@echo off
chcp 65001 >nul
REM study-tree - local start script
REM Finds Node.js and runs server.js (listens on 0.0.0.0:5173).
REM Double-click to start; close this window to stop the server.
title study-tree - local server (close this window to stop)
cd /d "%~dp0"

set "NODE_EXE="
where node >nul 2>nul && set "NODE_EXE=node"
if not defined NODE_EXE if exist "%ProgramFiles%\nodejs\node.exe" set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
if not defined NODE_EXE if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" set "NODE_EXE=%LOCALAPPDATA%\Programs\nodejs\node.exe"

if not defined NODE_EXE (
  echo.
  echo   Node.js not found. Install the LTS build from https://nodejs.org/ then double-click this file again.
  echo.
  pause
  exit /b 1
)

set HOST=0.0.0.0
"%NODE_EXE%" "%~dp0server.js"

echo.
echo   Server stopped. Press any key to close.
pause >nul
