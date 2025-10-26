@echo off
REM Start the HTTPS server with the generated localhost certificate
set PFX_PATH=G:\GIT_REPOSITORY\REPO\http-search\localhost.p12
set SSL_PASSPHRASE=dev123
echo Starting HTTPS server with localhost certificate...
echo Server will be available at: https://localhost:8443
echo HTTP redirect server at: http://localhost:8080
node .\server.js