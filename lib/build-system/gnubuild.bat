@echo off

if exist %DYLAN_RELEASE_ROOT%\install\x86-win32\bin\gnubuild.exe goto BUILD

echo %DYLAN_RELEASE_ROOT%\install\x86-win32\bin\gnubuild.exe not found  -- aborting
goto END

:BUILD

REM How do you convince DOS to pass on more than 9 arguments?

%DYLAN_RELEASE_ROOT%\install\x86-win32\bin\gnubuild %1 %2 %3 %4 %5 %6 %7 %8 %9

:END
