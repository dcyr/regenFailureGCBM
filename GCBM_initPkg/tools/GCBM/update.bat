@echo off
copy /y c:\dev\projects\moja.canada\source\bin\release\*.* .
copy /y c:\dev\projects\moja.global\source\bin\release\*.* .
copy /y "C:\Program Files\PostgreSQL\9.6\bin\*.dll" .
del *.pdb
del *d.dll
