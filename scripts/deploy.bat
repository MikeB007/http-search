@echo off
REM Windows deployment script for HTTP Search application

echo 🚀 HTTP Search - Build and Deploy Script (Windows)
echo ========================================

set IMAGE_NAME=http-search
set CONTAINER_NAME=http-search-server
set BUILD_TARGET=%1
if "%BUILD_TARGET%"=="" set BUILD_TARGET=production

echo 📋 Step 1: Setting up certificates...
if not exist ".\certs\localhost.p12" (
    call npm run setup:certs
    echo ✓ Certificates configured
) else (
    echo ✓ Certificates already exist
)

echo 📋 Step 2: Installing dependencies...
call npm ci
if %errorlevel% neq 0 goto :error
echo ✓ Dependencies installed

echo 📋 Step 3: Building Angular application...
set NODE_OPTIONS=--openssl-legacy-provider
if "%BUILD_TARGET%"=="production" (
    call npm run build:prod
) else (
    call npm run build
)
if %errorlevel% neq 0 goto :error
echo ✓ Angular application built

echo 📋 Step 4: Building Docker image...
docker build -t %IMAGE_NAME%:latest .
if %errorlevel% neq 0 goto :error
echo ✓ Docker image built successfully

echo 📋 Step 5: Stopping existing container...
docker stop %CONTAINER_NAME% 2>nul
docker rm %CONTAINER_NAME% 2>nul
echo ✓ Cleaned up existing container

echo 📋 Step 6: Starting new container...
docker run -d ^
    --name %CONTAINER_NAME% ^
    -p 8080:8080 ^
    -p 8443:8443 ^
    -v "%cd%\certs:/app/certs:ro" ^
    -e NODE_ENV=%BUILD_TARGET% ^
    -e PFX_PATH=/app/certs/localhost.p12 ^
    -e SSL_PASSPHRASE=dev123 ^
    %IMAGE_NAME%:latest

if %errorlevel% neq 0 goto :error
echo ✓ Container started successfully

echo 📋 Step 7: Checking application status...
timeout /t 5 /nobreak > nul

docker ps --filter "name=%CONTAINER_NAME%"
echo.
echo 🌐 Application URLs:
echo    HTTPS: https://localhost:8443
echo    HTTP:  http://localhost:8080 (redirects to HTTPS)
echo.
echo 📝 View logs with: docker logs %CONTAINER_NAME%
echo 🛑 Stop with: docker stop %CONTAINER_NAME%
echo.
echo 🎉 Deployment completed successfully!
goto :end

:error
echo ❌ Deployment failed!
exit /b 1

:end