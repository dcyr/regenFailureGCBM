@echo off
copy /y c:\dev\projects\moja.canada\source\bin\release\*.* .
copy /y c:\dev\projects\moja.global\source\bin\release\*.* .
del *.pdb
del *d.dll
