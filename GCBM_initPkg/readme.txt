Description of contents
---
tools\
    CompileGCBMResults - Python script for turning raw SQLite output database from
        the model into a more user-friendly format that includes most of the
        indicators from CBM3 (NPP, NEP, pools, etc.).
        
        Usage:
        python path\to\tools\queryrunner\src\queryrunner.py
		--config compilegcbmresults.ini
		--results_path path\to\gcbm_output.db
		--output_db path\to\compiled_output.db

    CompileGCBMSpatialOutput - Python script for turning GCBM spatial output
        (.grd/.hdr files) into TIFF layers.
        
        Usage:
        python path\to\tools\compilegcbmspatialoutput\create_tiffs.py
            --indicator_root G:\GCBM\18_ParksCanadaAtlas\05_working_Parks
            --no-cleanup
            --start_year 1989
            --output_path .
        
    GCBM - The GCBM model.
        Usage:
        moja-cli.exe --config some_project.json --config_provider some_provider.json

    python_27_installer - Install script for the complete Python environment
        required to run the various GCBM-related scripts. If you already have
        an existing Python installation, you can upgrade it using this script
        as long as you match the bit-ness of the existing version, or install
        into a new location, or use the batch file as a guide for installing
        required modules into your existing environment.
        
        It is strongly recommended to use 64-bit Python.
        
        Usage:
        install_py27.bat (x86/x64) [optional: python install path]
        
    Recliner2GCBM-[x86/x64] - Tool for preparing the SQLite input database for
        GCBM, which holds non-spatial (or coarse spatially-referenced) model
        parameters. Use the x64 version and fall back to the x86 version if you
        don't have the 64-bit MS Access driver installed.
        
        The tool has both a GUI version to guide you through the process the
        first time, and a command-line version to update a database from a saved
        configuration, provided that the columns in the input data have not
        changed.
        
    release-1911-x64-gdal-2-2-mapserver-7-0 - Version of GDAL that is known to
        work with all of the GCBM-related scripts.
        
        System environment variables should be set up as:
        GDAL_BIN=path\to\release-1911-x64-gdal-2-2-mapserver-7-0\bin
        GDAL_DATA=%GDAL_BIN%\gdal-data
        GDAL_APPS=%GDAL_BIN%\gdal\apps
	PYTHONHOME=c:\python27 <-- or custom path used in python_27_installer
        PYTHONPATH=%GDAL_BIN%\gdal\python;%GDAL_BIN%\ms\python
        PATH=%GDAL_BIN%;%GDAL_DATA%;%GDAL_APPS%;%PYTHONHOME%;<the other original PATH items>
        
    Tiler - Converts raster and vector layers into the format required by GCBM.
        Usage:
        python tiler.py

input_database\
    The GCBM input database for the project which contains all of the non-
    spatial model parameters, plus the files needed to generate the input
    database using the Recliner2GCBM tool.

layers\
    The spatial layers for the project, both the originals and the output of
    the tiler script which processes the original layers into the format used
    by GCBM.
    
gcbm_project\
    The files needed to run GCBM - config files, SQL for retrieving parameters
    from the input database.
---

To run the project (the short version):

If Python and GDAL were set up as noted earlier in this readme, run_all.bat
should run the example project from start to finish with no modifications -
with the possible exception of having to change the batch file to run
Recliner2GCBM-x86 instead of Recliner2GCBM-x64, if there is a 32-bit version
of the MS Access driver installed.

---

To run the project (the detailed version):
    
    Edit run_all.bat - find the call to recliner2gcbm.exe; the correct version of
    this tool must be called depending on the version of MS Access installed on
    the system: use recliner2gcbm-x86\recliner2gcbm.exe for 32-bit Access, or -x64
    for 64-bit Access.

    Run run_all.bat, which performs the following preprocessing, simulation, and
    postprocessing steps:
    
    1) Run the tiler script
        - batch file runs \tools\Tiler\tiler.py
            - define all spatial layers needed for the simulation - can be
                raster or shapefile:
                - bounding box
                - age
                - classifiers
                - disturbance events (optional)
            - crops all layers to a bounding box and reprojects to WGS84
            - processes layers into GCBM tile/block/cell format
            - output is a number of zip files containing GCBM-format data plus
                a json file containing metadata and an optional attribute table
        - batch file calls \tools\Tiler\update_gcbm_config.py which updates the
            GCBM configuration files based on the tiled layers:
            - scans for all of the tiled layers and adds them to the provider
                configuration file
            - sets the tile, block, and cell size in the config files so that
                the model knows the overall resolution of the simulation (the
                lowest common denominator of all the tiled layer resolutions)
            - updates the list of disturbance layers in the simulation based on
                the DisturbanceLayer items in tiler.py
            - updates the initial classifier set with the classifier layers tagged
                in tiler.py

    2) Prepare the input database using Recliner2GCBM
        - runs the command-line version of Recliner2GCBM
            (\tools\Recliner2GCBM-[x86\x64]\Recliner2GCBM.exe) on the saved project
            configuration made by running the GUI tool (Recliner2GCBM-GUI.exe)
        - note: the paths in the saved recliner2gcbm_config.json file are relative
            to the location of the json file, so Recliner2GCBM should be run from
            that location using either run_recliner2gcbm.bat or run_recliner2gcbm_gui.bat
        - output is a SQLite database: gcbm_input.db which contains all of the
            non-spatial data required to run the project - parameters taken from
            a CBM3 ArchiveIndex database: disturbance matrices, default climate
            data, etc.

    3) Run the GCBM model: gcbm_project\run_gcbm.bat
        - project configuration is in gcbm_project\templates\gcbm_config.json
        - data source configuration (spatial layers + SQLite) is in
            gcbm_project\templates\provider_config.json
        - most important parts of project config:
            - start_date
            - end_date
            - num_threads - set to the number of cores available on your machine
                10, whichever is lower; after 10, performance is harmed instead of
                improved

    4) Run the compile results script:
        \tools\compilegcbmresults\compilegcbmresults.bat
        - turns the raw GCBM output database into a more user-friendly format
            containing most of the familiar indicators from the CBM3 Toolbox
        - produces processed_output\compiled_gcbm_output.db

    5) Run the compile spatial output script:
        \tools\compilegcbmspatialoutput\create_tiffs.bat
        - generates tiff layers from raw GCBM spatial output
        - output is a tiff layer per indicator and timestep in processed_output\spatial
