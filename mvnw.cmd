@echo off
setlocal enabledelayedexpansion

set "BASE_DIR=%~dp0"
set "PROPS=%BASE_DIR%.mvn\wrapper\maven-wrapper.properties"

if not exist "%PROPS%" (
  echo [ERROR] Missing %PROPS% 1>&2
  exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in ("%PROPS%") do (
  if "%%A"=="distributionUrl" set "DIST_URL=%%B"
  if "%%A"=="distributionSha512Sum" set "DIST_SHA512=%%B"
)

if "%DIST_URL%"=="" (
  echo [ERROR] distributionUrl is not configured. 1>&2
  exit /b 1
)

if "%MAVEN_USER_HOME%"=="" set "MAVEN_USER_HOME=%USERPROFILE%\.m2"
for %%F in ("%DIST_URL%") do set "ARCHIVE_NAME=%%~nxF"
set "DIST_NAME=%ARCHIVE_NAME:-bin.zip=%"

for /f "tokens=*" %%H in ('powershell -NoProfile -Command "$u='%DIST_URL%'; $sha=[System.Security.Cryptography.SHA256]::Create(); (($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($u)) | ForEach-Object ToString x2) -join '')"') do set "URL_HASH=%%H"

set "DIST_PARENT=%MAVEN_USER_HOME%\wrapper\dists\%DIST_NAME%\%URL_HASH%"
set "MAVEN_HOME=%DIST_PARENT%\%DIST_NAME%"
set "MAVEN_BIN=%MAVEN_HOME%\bin\mvn.cmd"

if not exist "%MAVEN_BIN%" (
  if not exist "%DIST_PARENT%" mkdir "%DIST_PARENT%"
  set "TMP_DIR=%TEMP%\mvnw-%RANDOM%-%RANDOM%"
  mkdir "!TMP_DIR!"
  set "ARCHIVE=!TMP_DIR!\%ARCHIVE_NAME%"

  echo [INFO] Downloading Maven from %DIST_URL%
  powershell -NoProfile -Command "Invoke-WebRequest -UseBasicParsing '%DIST_URL%' -OutFile '!ARCHIVE!'"
  if errorlevel 1 exit /b 1

  if not "%DIST_SHA512%"=="" (
    for /f "tokens=*" %%H in ('powershell -NoProfile -Command "(Get-FileHash '!ARCHIVE!' -Algorithm SHA512).Hash.ToLower()"') do set "ACTUAL_SHA512=%%H"
    if /I not "!ACTUAL_SHA512!"=="%DIST_SHA512%" (
      echo [ERROR] Maven distribution checksum validation failed. 1>&2
      exit /b 1
    )
  )

  powershell -NoProfile -Command "Expand-Archive '!ARCHIVE!' '%DIST_PARENT%' -Force"
  if errorlevel 1 exit /b 1
  rmdir /s /q "!TMP_DIR!"
)

call "%MAVEN_BIN%" %*
exit /b %ERRORLEVEL%
