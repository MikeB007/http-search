@echo off
setlocal enabledelayedexpansion

rem Docker Refresh Script for http-search Production Container (Windows)
rem This script provides multiple options for updating the production Docker container
rem with the latest image from GitHub Container Registry

set CONTAINER_NAME=http-search-production
set IMAGE_NAME=ghcr.io/mikeb007/http-search:latest
set CERTS_PATH=C:\opt\http-search\certs
set LOGS_PATH=C:\opt\http-search\logs

echo 🐳 Docker Container Refresh Script for http-search (Windows)
echo ============================================================
echo.

:main_menu
call :show_status
call :show_menu

set /p choice="Choose an option (1-6): "
echo.

if "%choice%"=="1" call :quick_restart
if "%choice%"=="2" call :full_refresh
if "%choice%"=="3" call :create_new_container
if "%choice%"=="4" call :show_status
if "%choice%"=="5" call :show_logs
if "%choice%"=="6" goto :exit_script
if not "%choice%"=="1" if not "%choice%"=="2" if not "%choice%"=="3" if not "%choice%"=="4" if not "%choice%"=="5" if not "%choice%"=="6" (
    echo ❌ Invalid option. Please choose 1-6.
)

echo.
pause
echo.
goto :main_menu

:quick_restart
echo 🔄 Option 1: Quick restart with latest image
echo Pulling latest image...
docker pull %IMAGE_NAME%
if %errorlevel% neq 0 (
    echo ❌ Failed to pull latest image
    goto :eof
)

docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo Restarting existing container...
    docker restart %CONTAINER_NAME%
    if %errorlevel% equ 0 (
        echo ✅ Container restarted successfully!
    ) else (
        echo ❌ Failed to restart container
    )
) else (
    echo ❌ Container %CONTAINER_NAME% does not exist. Use option 3 to create it.
)
goto :eof

:full_refresh
echo 🔄 Option 2: Full refresh - stop, remove, and recreate container
echo Pulling latest image...
docker pull %IMAGE_NAME%
if %errorlevel% neq 0 (
    echo ❌ Failed to pull latest image
    goto :eof
)

docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    docker ps --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
    if %errorlevel% equ 0 (
        echo Stopping container...
        docker stop %CONTAINER_NAME%
    )
    echo Removing container...
    docker rm %CONTAINER_NAME%
)

echo Creating new container with latest image...
call :create_new_container_internal
goto :eof

:create_new_container
echo 🔄 Option 3: Creating new container with latest code

docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo ❌ Container %CONTAINER_NAME% already exists. Use option 2 for full refresh.
    goto :eof
)

echo Pulling latest image...
docker pull %IMAGE_NAME%
if %errorlevel% neq 0 (
    echo ❌ Failed to pull latest image
    goto :eof
)

call :create_new_container_internal
goto :eof

:create_new_container_internal
echo Starting new container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    --restart unless-stopped ^
    -p 80:8080 ^
    -p 8443:8443 ^
    -e NODE_ENV=production ^
    -e PFX_PATH=/app/certs/production.p12 ^
    -e SSL_PASSPHRASE=production123 ^
    -e NODE_OPTIONS=--openssl-legacy-provider ^
    -v "%CERTS_PATH%:/app/certs:ro" ^
    -v "%LOGS_PATH%:/app/logs" ^
    %IMAGE_NAME%

if %errorlevel% equ 0 (
    echo ✅ New container created and started successfully!
) else (
    echo ❌ Failed to create container
)
goto :eof

:show_status
echo 📊 Current container status:
echo ==============================

docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo Container exists: ✅
    docker ps --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
    if %errorlevel% equ 0 (
        echo Container running: ✅
        echo.
        echo Container details:
        docker ps --filter "name=%CONTAINER_NAME%" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    ) else (
        echo Container running: ❌ ^(stopped^)
    )
) else (
    echo Container exists: ❌
)
echo.
goto :eof

:show_logs
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /x "%CONTAINER_NAME%" >nul
if %errorlevel% equ 0 (
    echo 📋 Container logs ^(last 50 lines^):
    echo ==================================
    docker logs --tail 50 %CONTAINER_NAME%
) else (
    echo ❌ Container %CONTAINER_NAME% does not exist.
)
goto :eof

:show_menu
echo Available options:
echo 1^) Quick restart ^(pull latest + restart existing container^)
echo 2^) Full refresh ^(stop + remove + recreate with latest^)
echo 3^) Create new container ^(if none exists^)
echo 4^) Show container status
echo 5^) Show container logs
echo 6^) Exit
echo.
goto :eof

:exit_script
echo 👋 Goodbye!
exit /b 0