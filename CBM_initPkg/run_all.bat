@echo off

REM Clean up log and output directories.
if exist logs rd /s /q logs
if exist processed_output rd /s /q processed_output
if exist gcbm_project\output rd /s /q gcbm_project\output
if exist layers\tiled rd /s /q layers\tiled
md logs
md processed_output
md gcbm_project\output
md layers\tiled

pushd layers\tiled
  echo Tiling spatial layers...
  python ..\..\tools\tiler\tiler.py
  echo Updating GCBM configuration...
  python ..\..\tools\tiler\update_gcbm_config.py --layer_root . --template_path ..\..\gcbm_project\templates --output_path ..\..\gcbm_project
popd

echo Generating GCBM input database...
tools\recliner2gcbm-x64\recliner2gcbm.exe -c input_database\recliner2gcbm_config.json

pushd gcbm_project
  echo Running GCBM...
..\tools\GCBM\moja.cli.exe --config_file gcbm_config.cfg --config_provider provider_config.json
popd

echo Compiling spatial output...
python tools\compilegcbmspatialoutput\create_tiffs.py --indicator_root gcbm_project\output --start_year 2016 --output_path processed_output\spatial

echo Compiling results database...
python tools\queryrunner\src\queryrunner.py --config tools\compilegcbmresults\compilegcbmresults.ini --results_path gcbm_project\output\gcbm_output.db --output_db processed_output\compiled_gcbm_output.db

REM echo Creating animations...
REM python tools\animation\create_animations.py --indicator_root processed_output --output_path processed_output\animations

echo Done!
pause
