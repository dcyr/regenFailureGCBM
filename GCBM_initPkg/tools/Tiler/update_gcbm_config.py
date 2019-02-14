import os
import simplejson as json
import argparse
import logging
import shutil
import sys
from future.utils import viewitems
from argparse import ArgumentParser
from glob import glob
from contextlib import contextmanager

def scan_for_layers(layer_root):
    provider_layers = []
    layers = {fn for fn in os.listdir(layer_root)
              if os.path.isdir(fn)
              or fn.endswith(".zip")}
    
    for layer in layers:
        logging.info("Found layer: {}".format(layer))
        layer_prefix, _ = os.path.splitext(os.path.basename(layer))
        layer_path = os.path.join(layer_root, layer_prefix)
        layer_name, _ = layer_prefix.split("_moja")
        provider_layers.append({
            "name"  : layer_name,
            "type"  : None,
            "path"  : layer_path,
            "prefix": layer_prefix
        })
        
    return provider_layers
    
def find_config_file(config_path, *search_path):
    for config_file in (fn for fn in glob(os.path.join(config_path, "*.json"))
                        if "internal" not in fn.lower()):
        # Drill down through the config file contents to see if the whole search path
        # is present; if it is, then this is the right file to modify.
        config = json.load(open(config_file, "r"))
        for entry in search_path:
            config = config.get(entry)
            if config is None:
                break
        
        if config is not None:
            return config_file
    
    return None

@contextmanager
def update_json_file(path):
    with open(path, "r") as json_file:
        contents = json.load(json_file)
        
    yield contents
    
    with open(path, "w") as json_file:
        json_file.write(json.dumps(contents, indent=4, ensure_ascii=False))
    
def update_provider_config(study_area, layer_root, config_path):
    provider_config_path = find_config_file(config_path, "Providers")
    if not provider_config_path:
        logging.fatal("No provider configuration file found in {}".format(config_path))
        return
    
    with update_json_file(provider_config_path) as provider_config:
        provider_section = provider_config["Providers"]
        layer_config = None
        for provider, config in viewitems(provider_section):
            if "layers" in config:
                spatial_provider_config = config
                break

        spatial_provider_config["tileLatSize"]  = study_area["tile_size"]
        spatial_provider_config["tileLonSize"]  = study_area["tile_size"]
        spatial_provider_config["blockLatSize"] = study_area["block_size"]
        spatial_provider_config["blockLonSize"] = study_area["block_size"]
        spatial_provider_config["cellLatSize"]  = study_area["pixel_size"]
        spatial_provider_config["cellLonSize"]  = study_area["pixel_size"]
                
        provider_layers = []
        relative_layer_root = os.path.relpath(layer_root, config_path)
        for layer in study_area["layers"]:
            logging.debug("Added {} to provider configuration".format(layer))
            provider_layers.append({
                "name"        : layer["name"],
                "layer_path"  : os.path.join(relative_layer_root, os.path.relpath(layer["path"], layer_root)),
                "layer_prefix": layer["prefix"]
            })
            
        layer_config = spatial_provider_config["layers"] = provider_layers
        logging.info("Updated provider configuration: {} with layers in: {}".format(
            provider_config_path, os.path.abspath(layer_root)))

def update_simulation_study_area(study_area, config_path):
    config_file_path = find_config_file(config_path, "LocalDomain", "landscape")
    with update_json_file(config_file_path) as study_area_config:
        tile_size    = study_area["tile_size"]
        pixel_size   = study_area["pixel_size"]
        tile_size_px = int(tile_size / pixel_size)
        
        landscape_config = study_area_config["LocalDomain"]["landscape"]
        landscape_config["tile_size_x"] = tile_size
        landscape_config["tile_size_y"] = tile_size
        landscape_config["x_pixels"]    = tile_size_px
        landscape_config["y_pixels"]    = tile_size_px
        landscape_config["tiles"]       = study_area["tiles"]
        logging.info("Study area configuration updated: {}".format(config_file_path))

def update_simulation_disturbances(study_area, config_path):
    config_file_path = find_config_file(config_path, "Modules", "CBMDisturbanceListener")
    with update_json_file(config_file_path) as module_config:
        disturbance_listener_config = module_config["Modules"]["CBMDisturbanceListener"]
        if "settings" not in disturbance_listener_config:
            disturbance_listener_config["settings"] = {}

        disturbance_listener_config["settings"]["vars"] = []
        disturbance_layers = disturbance_listener_config["settings"]["vars"]
        
        for layer in study_area["layers"]:
            layer_tags = layer.get("tags") or []
            if "disturbance" in layer_tags:
                disturbance_layers.append(layer["name"])
                
        if not disturbance_layers:
            disturbance_listener_config["enabled"] = False
            
        logging.info("Disturbance configuration updated: {}".format(config_file_path))
        
def add_simulation_data_variables(study_area, config_path):
    config_file_path = find_config_file(config_path, "Variables")
    with update_json_file(config_file_path) as variable_config:
        variables = variable_config["Variables"]
        classifier_layers = variables["initial_classifier_set"]["transform"]["vars"]
        reporting_classifier_layers = variables["reporting_classifiers"]["transform"]["vars"]
        
        for layer in study_area["layers"]:
            layer_name = layer["name"]
            layer_type = layer["type"]

            layer_tags = layer.get("tags") or []
            if "classifier" in layer_tags:
                classifier_layers.append(layer_name)
            elif "reporting_classifier" in layer_tags:
                reporting_classifier_layers.append(layer_name)
                
            variables[layer_name] = {
                "transform": {
                    "library"      : "internal.flint",
                    "type"         : "TimeSeriesIdxFromFlintDataTransform",
                    "provider"     : "RasterTiled",
                    "data_id"      : layer_name,
                    "sub_same"     : "true",
                    "start_year"   : 0,
                    "data_per_year": layer["nStepsPerYear"],
                    "n_years"      : layer["nLayers"]
                }
            } if layer_type == "RegularStackLayer" else {
                "transform": {
                    "library" : "internal.flint",
                    "type"    : "LocationIdxFromFlintDataTransform",
                    "provider": "RasterTiled",
                    "data_id" : layer_name
                }
            }
            
        logging.info("Variable configuration updated: {}".format(config_file_path))
    
def get_study_area(layer_root):
    study_area = {
        "tile_size" : 1.0,
        "block_size": 0.1,
        "pixel_size": 0.00025,
        "tiles"     : [],
        "layers"    : []
    }
    
    study_area_path = os.path.join(layer_root, "study_area.json")
    if os.path.exists(study_area_path):
        with open(study_area_path, "r") as study_area_file:
            study_area.update(json.load(study_area_file))

    # Find all of the layers for the simulation physically present on disk, then
    # add any extra metadata available from the tiler's study area output.
    layers = scan_for_layers(layer_root)
    study_area_layers = study_area.get("layers")
    if study_area_layers:
        for layer in layers:
            for layer_metadata \
            in filter(lambda l: l.get("name") == layer.get("name"), study_area_layers):
                layer.update(layer_metadata)
    
    study_area["layers"] = layers
   
    return study_area

if __name__ == "__main__":
    logging.basicConfig(filename=r"..\..\logs\update_gcbm_config.log", filemode="w",
						level=logging.INFO, format="%(message)s")

    parser = ArgumentParser(description="Update GCBM spatial provider configuration.")
    parser.add_argument("--layer_root", help="path to the spatial output root directory", required=True)
    parser.add_argument("--template_path", help="path containing the GCBM config file templates", required=True)
    parser.add_argument("--output_path", help="path to write updated GCBM config files", required=False, default=".")
    args = parser.parse_args()
    
    output_path = os.path.abspath(args.output_path)
    for template in glob(os.path.join(args.template_path, "*.json")):
        shutil.copy(template, output_path)
    
    study_area = get_study_area(args.layer_root)
    update_simulation_study_area(study_area, output_path)
    update_simulation_disturbances(study_area, output_path)
    add_simulation_data_variables(study_area, output_path)
    update_provider_config(study_area, args.layer_root, output_path)
