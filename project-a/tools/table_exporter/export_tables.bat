@echo off
setlocal

pushd "%~dp0\..\.." >nul
python tools\table_exporter\table_exporter.py --input-dir tables\excel --output-dir data\generated --clean
set EXIT_CODE=%ERRORLEVEL%
popd >nul

exit /b %EXIT_CODE%
