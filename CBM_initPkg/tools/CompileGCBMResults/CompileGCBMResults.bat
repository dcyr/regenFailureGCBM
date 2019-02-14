@echo off
python ..\queryrunner\src\queryrunner.py --config CompileGCBMResults.ini --results_path ..\..\gcbm_project\output\gcbm_output.db --output_db ..\..\processed_output\compiled_gcbm_output.db
pause