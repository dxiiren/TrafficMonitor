@echo off
rem Builds and runs the threshold harness.
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
cd /d %~dp0
cl /nologo /utf-8 /EHsc /std:c++17 TestThresholds.cpp /Fe:TestThresholds.exe || exit /b 1
"%~dp0TestThresholds.exe"
