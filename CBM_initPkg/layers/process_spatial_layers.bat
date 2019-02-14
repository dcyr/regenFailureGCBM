@echo off

REM Clean up any existing tiled layers.
if exist tiled rd /s /q tiled
md tiled
if not exist ..\logs md ..\logs

pushd tiled
  echo Tiling spatial layers...
  python ..\..\tools\tiler\tiler.py
  echo Updating GCBM configuration...
  python ..\..\tools\tiler\update_gcbm_config.py --layer_root . --template_path ..\..\gcbm_project\templates --output_path ..\..\gcbm_project
popd

echo Done!
pause
