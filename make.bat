@echo off
REM make
REM Assembles and links the 32-bit ASM program into .exe which can be used by WinDmain
REM Uses MicroSoft Macro Assembler version 6.11 and 32-bit Incremental Linker version 5.10.7303
REM Created by Huang 

REM delete related files
del main.lst	REM main可以替換成.asm檔的檔名
del main.obj
del main.ilk
del main.pdb
del main.exe

setlocal 
set INCLUDE=C:\WINdmainFolder\;	REM 這裡要設成WINdmainFolder的路徑
set LIB=C:\WINdmainFolder\;
set PATH=C:\WINdmainFolder\;

REM /c          assemble without linking
REM /coff       generate object code to be linked into flat memory model 
REM /Zi         generate symbolic debugging information for WinDmain
REM /Fl		Generate a listing file
 

ML /c /coff /Zi   main.asm
if errorlevel 1 goto terminate

REM /debug              generate symbolic debugging information
REM /subsystem:console  generate console application code
REM /entry:start        entry point from WinDmain to the program 
REM                           the entry point of the program must be _start

REM /out:%1.exe         output %1.exe code
REM %1.obj              input %1.obj
REM Kernel32.lib        library procedures to be invoked from the program
REM irvine32.lib
REM user32.lib

LINK /INCREMENTAL:no /debug /subsystem:console /entry:start /out:main.exe main.obj Kernel32.lib irvine32.lib user32.lib
if errorlevel 1 goto terminate

REM Display all files related to this program:
DIR main.*

:terminate
pause
endlocal