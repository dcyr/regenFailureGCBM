@ECHO OFF

REM Command file for Sphinx documentation

if "%SPHINXBUILD%" == "" (
	set SPHINXBUILD=sphinx-build
)
set BUILDDIR=build
set SOURCEDIR=source
set ALLSPHINXOPTS=-d %BUILDDIR%/doctrees %SPHINXOPTS% source
if NOT "%PAPER%" == "" (
	set ALLSPHINXOPTS=-D latex_paper_size=%PAPER% %ALLSPHINXOPTS%
)

if "%3" == "" goto help

set SPHINX_PYTHON_PATH=%1
set PATH=%SPHINX_PYTHON_PATH%;%SPHINX_PYTHON_PATH%\scripts

set SPHINX_PROJECT_PATH=%2
set PYTHONPATH=%SPHINX_PROJECT_PATH%

if "%3" == "help" (
	:help
	echo.Please use `make ^<pythonpath^> ^<srcpath^> ^<target^>`
        echo.where ^<pythonpath^> is the path to the Python installation directory,
        echo.^<srcpath^> is the path to the Python project's 'src' directory,
        echo.and ^<target^> is one of
	echo.  html       to make standalone HTML files
	echo.  dirhtml    to make HTML files named index.html in directories
	echo.  singlehtml to make a single large HTML file
	echo.  pickle     to make pickle files
	echo.  json       to make JSON files
	echo.  htmlhelp   to make HTML files and a HTML help project
	echo.  qthelp     to make HTML files and a qthelp project
	echo.  devhelp    to make HTML files and a Devhelp project
	echo.  epub       to make an epub
	echo.  latex      to make LaTeX files, you can set PAPER=a4 or PAPER=letter
	echo.  text       to make text files
	echo.  man        to make manual pages
	echo.  changes    to make an overview over all changed/added/deprecated items
	echo.  linkcheck  to check all external links for integrity
	echo.  doctest    to run all doctests embedded in the documentation if enabled
	echo.  regen      to regenerate TOC files using generate_modules.py
	goto end
)

if "%3" == "regen" (
	del /q /s %SOURCEDIR%\*.rst
	for /d %%i in (%BUILDDIR%\*) do rmdir /q /s %%i
	del /q /s %BUILDDIR%\*
	python generate_modules.py -d source -s rst -f %SPHINX_PROJECT_PATH%
	goto end
)

if "%3" == "clean" (
	for /d %%i in (%BUILDDIR%\*) do rmdir /q /s %%i
	del /q /s %BUILDDIR%\*
	goto end
)

if "%3" == "html" (
	%SPHINXBUILD% -b html %ALLSPHINXOPTS% %BUILDDIR%/html
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished. The HTML pages are in %BUILDDIR%/html.
	goto end
)

if "%3" == "dirhtml" (
	%SPHINXBUILD% -b dirhtml %ALLSPHINXOPTS% %BUILDDIR%/dirhtml
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished. The HTML pages are in %BUILDDIR%/dirhtml.
	goto end
)

if "%3" == "singlehtml" (
	%SPHINXBUILD% -b singlehtml %ALLSPHINXOPTS% %BUILDDIR%/singlehtml
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished. The HTML pages are in %BUILDDIR%/singlehtml.
	goto end
)

if "%3" == "pickle" (
	%SPHINXBUILD% -b pickle %ALLSPHINXOPTS% %BUILDDIR%/pickle
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished; now you can process the pickle files.
	goto end
)

if "%3" == "json" (
	%SPHINXBUILD% -b json %ALLSPHINXOPTS% %BUILDDIR%/json
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished; now you can process the JSON files.
	goto end
)

if "%3" == "htmlhelp" (
	%SPHINXBUILD% -b htmlhelp %ALLSPHINXOPTS% %BUILDDIR%/htmlhelp
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished; now you can run HTML Help Workshop with the ^
.hhp project file in %BUILDDIR%/htmlhelp.
	goto end
)

if "%3" == "qthelp" (
	%SPHINXBUILD% -b qthelp %ALLSPHINXOPTS% %BUILDDIR%/qthelp
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished; now you can run "qcollectiongenerator" with the ^
.qhcp project file in %BUILDDIR%/qthelp, like this:
	echo.^> qcollectiongenerator %BUILDDIR%\qthelp\Sancho.qhcp
	echo.To view the help file:
	echo.^> assistant -collectionFile %BUILDDIR%\qthelp\Sancho.ghc
	goto end
)

if "%3" == "devhelp" (
	%SPHINXBUILD% -b devhelp %ALLSPHINXOPTS% %BUILDDIR%/devhelp
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished.
	goto end
)

if "%1" == "epub" (
	%SPHINXBUILD% -b epub %ALLSPHINXOPTS% %BUILDDIR%/epub
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished. The epub file is in %BUILDDIR%/epub.
	goto end
)

if "%3" == "latex" (
	%SPHINXBUILD% -b latex %ALLSPHINXOPTS% %BUILDDIR%/latex
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished; the LaTeX files are in %BUILDDIR%/latex.
	goto end
)

if "%3" == "text" (
	%SPHINXBUILD% -b text %ALLSPHINXOPTS% %BUILDDIR%/text
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished. The text files are in %BUILDDIR%/text.
	goto end
)

if "%3" == "man" (
	%SPHINXBUILD% -b man %ALLSPHINXOPTS% %BUILDDIR%/man
	if errorlevel 1 exit /b 1
	echo.
	echo.Build finished. The manual pages are in %BUILDDIR%/man.
	goto end
)

if "%3" == "changes" (
	%SPHINXBUILD% -b changes %ALLSPHINXOPTS% %BUILDDIR%/changes
	if errorlevel 1 exit /b 1
	echo.
	echo.The overview file is in %BUILDDIR%/changes.
	goto end
)

if "%3" == "linkcheck" (
	%SPHINXBUILD% -b linkcheck %ALLSPHINXOPTS% %BUILDDIR%/linkcheck
	if errorlevel 1 exit /b 1
	echo.
	echo.Link check complete; look for any errors in the above output ^
or in %BUILDDIR%/linkcheck/output.txt.
	goto end
)

if "%3" == "doctest" (
	%SPHINXBUILD% -b doctest %ALLSPHINXOPTS% %BUILDDIR%/doctest
	if errorlevel 1 exit /b 1
	echo.
	echo.Testing of doctests in the sources finished, look at the ^
results in %BUILDDIR%/doctest/output.txt.
	goto end
)

:end
