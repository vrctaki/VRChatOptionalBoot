@echo off
rem Ref: (remove zone id) https://aquasoftware.net/blog/?p=1011

rem Remove ZoneID
powershell -Command "Remove-Item 'vrchat_optional_boot.ps1' -Stream Zone.Identifier" -ErrorAction SilentlyContinue

rem Create Shortcut
powershell -ExecutionPolicy RemoteSigned .\vrchat_optional_boot.ps1 -CreateShortcut
