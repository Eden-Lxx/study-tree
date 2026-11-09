@echo off
chcp 65001 >nul
title Tech Tree - public tunnel, close this window to stop
cd /d "%~dp0"

if not exist "cloudflared.exe" (
  echo.
  echo   cloudflared not found, downloading...
  curl -L --fail -o cloudflared.exe https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe
)

if not exist "cloudflared.exe" (
  echo.
  echo   Download failed.
  echo   1. Open https://github.com/cloudflare/cloudflared/releases
  echo   2. Download cloudflared-windows-amd64.exe
  echo   3. Rename it to cloudflared.exe and put it in this folder
  echo   4. Run this file again
  echo.
  pause
  exit /b 1
)

echo.
echo   Make sure 启动.bat is already running, local server on port 5173.
echo   The public https address will appear below, share it with anyone.
echo.
cloudflared.exe tunnel --url http://127.0.0.1:5173

echo.
echo   Tunnel closed. Press any key to exit.
pause >nul
