@echo off
python ..\queryrunner\src\queryrunner.py --config compiled_results_to_mdb.ini --compiled_results_path ..\..\processed_output\compiled_gcbm_output.db --output_db ..\..\processed_output\compiled_gcbm_output.accdb
pause