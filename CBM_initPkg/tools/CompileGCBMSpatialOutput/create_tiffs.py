import os
import logging
import gdal
import argparse
import psutil
from glob import glob
from future.utils import viewitems
from argparse import ArgumentParser
from collections import defaultdict
from multiprocessing import Pool
from multiprocessing import cpu_count

def create_tiff(name, grd_files, cleanup=True):
    '''
    Creates a single tiff file from a list of .grd files.
    '''
    vrt_filename = ".".join((name, "vrt"))
    gdal.BuildVRT(vrt_filename, grd_files)
    
    tiff_filename = ".".join((name, "tiff"))
    gdal.Translate(tiff_filename, vrt_filename, creationOptions=["TILED=YES", "COMPRESS=DEFLATE"])

    os.remove(vrt_filename)
    if cleanup:
        for grd_file in grd_files:
            # Each .grd file is normally paired with a .hdr file - clean up both.
            for raw_output_file in glob("{}.*".format(os.path.splitext(grd_file)[0])):
                os.remove(raw_output_file)
            
            grd_file_dir = os.path.dirname(grd_file)
            indicator_dir = os.path.abspath(os.path.join(grd_file_dir, ".."))
            for grd_dir in (grd_file_dir, indicator_dir):
                if not os.listdir(grd_dir):
                    os.rmdir(grd_dir)

    return name
    
def extract_scenario_from_path(path):
    '''
    Tries to find the scenario name in the path to a spatial output file when
    processing a multi-scenario project.
    '''
    for segment in path.split(os.path.sep):
        if "scen" in segment.lower():
            return segment
    
    return ""
    
def find_spatial_output(root_path):
    '''
    Gathers up all spatial output rooted in root_path by indicator and timestep.
    '''
    spatial_output = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    for dir, subdirs, files in os.walk(root_path):
        for file in filter(lambda f: f.endswith(".grd"), files):
            scenario = extract_scenario_from_path(dir)
            indicator = dir.split(os.path.sep)[-2]
            timestep = os.path.splitext(file)[0].split("_")[-1].zfill(3)
            file_path = os.path.abspath(os.path.join(dir, file))
            spatial_output[scenario][indicator][timestep].append(file_path)
    
    return spatial_output
    
def process_spatial_output(spatial_output, cleanup=True, start_year=None, output_path="."):
    '''
    Generates a tiff file for each indicator at each timestep from a dictionary
    of {indicator: {timestep: [.grd files]}}
    '''
    if not os.path.exists(output_path):
        os.makedirs(output_path)
    
    num_workers = cpu_count()
    available_mem = psutil.virtual_memory().available
    worker_mem = int(available_mem * 0.8 / num_workers)
    pool = Pool(num_workers, init_pool, (worker_mem,))
    
    for scenario, raw_output in viewitems(spatial_output):
        for indicator, timesteps in viewitems(raw_output):
            for timestep, grd_files in viewitems(timesteps):
                time_part = str(start_year + int(timestep) - 1) if start_year else timestep
                name_parts = (scenario, indicator, time_part) if scenario else (indicator, time_part)
                name = os.path.join(output_path, "_".join(name_parts))
                pool.apply_async(create_tiff, (name, grd_files, cleanup), callback=logging.info)

    pool.close()
    pool.join()
    
def init_pool(worker_mem):
    gdal.SetCacheMax(worker_mem)
    
if __name__ == "__main__":
    gdal.PushErrorHandler("CPLQuietErrorHandler")

    logging.basicConfig(filename=r"logs\create_tiffs.log", filemode="w", level=logging.DEBUG,
						format="%(asctime)s %(message)s", datefmt="%m/%d %H:%M:%S")

    parser = ArgumentParser(description="Generate tiffs from raw spatial output. "
        "If this tool is pointed at a directory level above multiple runs that "
        "together cover a larger geographical area, the outputs will be combined.")
        
    parser.add_argument("--indicator_root", required=False, default=".",
                        help="path to the spatial output root directory")

    parser.add_argument("--no-cleanup", dest="cleanup", action="store_false",
                        help="keep VRT/GRD/HDR files when finished")
                        
    parser.add_argument("--start_year", required=False, type=int,
                        help="the timestep 1 year, to use years instead of timesteps in filenames")
                        
    parser.add_argument("--output_path", required=False, default=".",
                        help="path to store generated tiffs in - will be created if it doesn't exist")

    parser.set_defaults(cleanup=True)
   
    args = parser.parse_args()
    spatial_output = find_spatial_output(args.indicator_root)
    if spatial_output:
        logging.info("Found {} scenarios with {} total spatial outputs.".format(
            len(spatial_output), sum(len(indicators) for indicators in spatial_output.values())))
            
        process_spatial_output(spatial_output, args.cleanup, args.start_year, args.output_path)
        logging.info("Done")
    else:
        logging.info("No spatial output found.")
