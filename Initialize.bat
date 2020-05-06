@echo off
rem Ref: (remove zone id) https://aquasoftware.net/blog/?p=1011

echo Start setup...

rem Remove ZoneID
powershell -Command "Remove-Item 'vrchat_optional_boot.ps1' -Stream Zone.Identifier" -ErrorAction SilentlyContinue

rem Create Shortcut
powershell -ExecutionPolicy RemoteSigned .\vrchat_optional_boot.ps1 -CreateShortcut

echo Setup finished.
echo.
echo You can close this window.
pause