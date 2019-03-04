import os
import logging
import sys
from glob import glob
from collections import OrderedDict
from mojadata.boundingbox import BoundingBox
from mojadata.cleanup import cleanup
from mojadata.compressingtiler2d import CompressingTiler2D
from mojadata.compressingtiler3d import CompressingTiler3D
from mojadata.layer.vectorlayer import VectorLayer
from mojadata.layer.rasterlayer import RasterLayer
from mojadata.layer.gcbm.disturbancelayer import DisturbanceLayer
from mojadata.layer.regularstacklayer import RegularStackLayer
from mojadata.layer.attribute import Attribute
from mojadata.layer.gcbm.transitionrule import TransitionRule
from mojadata.layer.gcbm.transitionrulemanager import SharedTransitionRuleManager
from mojadata.layer.filter.valuefilter import ValueFilter
from mojadata.util import gdal
from mojadata.util.gdalhelper import GDALHelper

# -------------------------------------------------------
# Scans for layers in a directory matching a particular pattern, i.e. "fire*.tif".
# Returns a list of filenames in natural sort order: if the filenames are consistent
# and contain a year, they will generally be returned in chronological order.
# 
# :param path: the path to scan
# :param filter: the filter to apply, i.e. "fire*.tif"
# -------------------------------------------------------
from glob import glob
def scan_for_layers(path, filter):
    return sorted(glob(os.path.join(path, filter)),
                  key=os.path.basename)
				  
# -------------------------------------------------------
# Reads a UTF8-encoded CSV file and converts it to a dictionary using a specified
# key column and one or more value columns. Use this for reading in external lookup
# tables containing non-ASCII / international characters. Python 2.7 only.

# :param csv_file: path to the CSV file to read
# :param key_col: column name to use as dictionary key
# :param value_cols: column name or list of column names for dictionary values
# -------------------------------------------------------
import csv
def csv_to_dict(csv_file, key_col, value_cols):
    attribute_table = open(csv_file, "rb")
    reader = csv.DictReader(attribute_table)
    
    if isinstance(value_cols, list):
        return {unicode(row[key_col], "utf-8"): [unicode(row[value_col], "utf-8")
                                                 for value_col in value_cols]
                for row in reader}
        
    return {unicode(row[key_col], "utf-8"): unicode(row[value_cols], "utf-8")
            for row in reader}
# -------------------------------------------------------

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, filename=r"..\..\logs\tiler_log.txt", filemode="w",
                        format="%(asctime)s %(message)s", datefmt="%m/%d %H:%M:%S")

    mgr = SharedTransitionRuleManager()
    mgr.start()
    rule_manager = mgr.TransitionRuleManager("transition_rules.csv")
   
    with cleanup():
        # Input layer path relative to where the script is being run from; assuming layers\tiled.
        layer_root = os.path.join("..", "raw")

        '''
        Define the bounding box of the simulation - all layers will be reprojected, cropped, and
        resampled to the bounding box area. The bounding box layer can be filtered by an attribute
        value to simulate a specific area.
        '''
        bbox = BoundingBox(
            RasterLayer(
                #"bbox",
                os.path.join(layer_root, "inventory", "coverTypes.tif")),
            pixel_size=0.01)
            
		# =============================================================================
		#         bbox = BoundingBox(
		#             VectorLayer(
		#                 "bbox",
		#                 os.path.join(layer_root, "inventory", "inventory.shp"),
		#                 Attribute("PolyID")),
		#             pixel_size=0.00025)
		# =============================================================================

        tiler = CompressingTiler2D(bbox, use_bounding_box_resolution=True)

        '''
        Classifier layers link pixels to yield curves.
          - the names of the classifier layers must match the classifier names in the GCBM input database
          - tags=[classifier_tag] ensures that classifier layers are automatically added to the GCBM
            configuration file
        '''
        classifier_tag = "classifier"
        reporting_classifier_tag = "reporting_classifier"
        
        classifier_layers = [
            RasterLayer(os.path.join(layer_root, "inventory", "coverTypes.tif"), name="coverType",  tags=[classifier_tag]),
            RasterLayer(os.path.join(layer_root, "inventory", "fertility.tif"), name="fertility", tags=[classifier_tag]),
            RasterLayer(os.path.join(layer_root, "inventory", "relDensity.tif"), name="relDensity", tags=[classifier_tag])
        ]
        
        # Set up default transition rule for disturbance events: preserve existing stand classifiers.
        no_classifier_transition = OrderedDict(zip((c.name for c in classifier_layers), "?" * len(classifier_layers)))

        layers = [
            # Age - layer name must be "initial_age" so that the script can update the GCBM configuration file.
            RasterLayer(os.path.join(layer_root, "inventory", "ageInit.tif"),
                        name="initial_age"),
            
            # Temperature - layer name must be "mean_annual_temperature" so that the scripts can
            # update the GCBM configuration file.
            RasterLayer(os.path.join(layer_root, "environment", "tempAnnualMean_C.tif"),
                        name = "mean_annual_temperature"),
			
			# Last oas
            RasterLayer(os.path.join(layer_root, "last_pass_disturbance", "last_pass_disturbance_type.tif"),
                        attributes=["value"],
                        attribute_table=csv_to_dict(os.path.join(layer_root, "last_pass_disturbance", "last_pass_disturbance_type_AT.csv"),
                                                    "ID", ["value"]))
        ] + classifier_layers

		# Disturbances
        dist = ['fire', 'cc', 'salv']
        distName = ["Wild Fire", "97% clearcut", "Fire with salvage logging"]
        
        for i in range(0, len(dist)):
            d = dist[i]
            dName = distName[i]
            
            if d == "fire":
                for layer_path in scan_for_layers(os.path.join(layer_root, "disturbances"), d + "_*.tif"):
    				# Extract the year from the filename.
    				layer_name = os.path.basename(os.path.splitext(layer_path)[0])
    				year = layer_name[-4:]
    				
    				layers.append(DisturbanceLayer(
    					rule_manager,
    					RasterLayer(
    						os.path.abspath(layer_path),
    						attributes=["type","disturbanceType","relDensityUpdate", "fertilityUpdate", "coverTypeUpdate"],
                            attribute_table=csv_to_dict(os.path.join(layer_root, "disturbances", "fire_AT.csv"),
                                                    "ID", ["type", "disturbanceType", "relDensityUpdate", "fertilityUpdate", "coverTypeUpdate"])),
                        year=year,
    					disturbance_type=Attribute("disturbanceType"),
                        transition=TransitionRule(
                                regen_delay=0,
                                age_after=0,
                        classifiers=["type", "disturbanceType", "coverTypeUpdate","fertilityUpdate", "relDensityUpdate"])))
                        
            else:
                for layer_path in scan_for_layers(os.path.join(layer_root, "disturbances"), d + "_*.tif"):
    				# Extract the year from the filename.
    				layer_name = os.path.basename(os.path.splitext(layer_path)[0])
    				year = layer_name[-4:]
    				
    				layers.append(DisturbanceLayer(
    					rule_manager,
    					RasterLayer(
    						os.path.abspath(layer_path),
    						attributes=["disturbed"],
    						attribute_table={
    							1: [1]
    						}),
    					year=year,
    					disturbance_type=dName))
				
        tiler.tile(layers)
        rule_manager.write_rules()
