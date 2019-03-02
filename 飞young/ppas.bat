@echo off
SET THEFILE=E:\MyCode\lazarus\령young\FeiYoung.exe
echo Linking %THEFILE%
D:\lazarus\fpc\3.0.4\bin\x86_64-win64\ld.exe -b pei-i386 -m i386pe  --gc-sections  -s --subsystem windows --entry=_WinMainCRTStartup    -o "E:\MyCode\lazarus\령young\FeiYoung.exe" "E:\MyCode\lazarus\령young\link.res"
if errorlevel 1 goto linkend
D:\lazarus\fpc\3.0.4\bin\x86_64-win64\postw32.exe --subsystem gui --input "E:\MyCode\lazarus\령young\FeiYoung.exe" --stack 16777216
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
