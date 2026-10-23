@echo off
rem Builds PluginLegionTemp\LegionTemp.dll (x64 Release). Needs VS 2022 Build Tools with C++.
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul || exit /b 1
cd /d %~dp0
cl /nologo /LD /O2 /EHsc /MT /W3 /DUNICODE /D_UNICODE /I ..\include LegionTemp.cpp /Fe:LegionTemp.dll
