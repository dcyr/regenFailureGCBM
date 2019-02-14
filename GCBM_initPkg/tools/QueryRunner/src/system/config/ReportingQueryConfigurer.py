# core
import os
import shutil
import re

# QueryRunner
from AbstractQueryConfigurer import AbstractQueryConfigurer
from database.query.ReportingQueryFeature import ReportingQueryFeature
from system.task.output.XlsOutputHandler import XlsOutputHandler
from system.task.output.PptxOutputHandler import PptxOutputHandler
from system.task.output.MdbOutputHandler import MdbOutputHandler
from system.task.output.SQLiteOutputHandler import SQLiteOutputHandler
from system.task.output.CsvOutputHandler import CsvOutputHandler

class ReportingQueryConfigurer(AbstractQueryConfigurer):
    '''
    Creates instances of :class:`.ReportingQueryFeature` from configuration.
    
    :param system: reference to the QueryRunner system object
    :type system: :class:`.System`
    :param configHelper: reference to the configuration file helper
    :type configHelper: :class:`.ConfigHelper`
    :param overwrite: flag indicating whether or not to overwrite tables
        in reporting databases when the script is run:
        True:  the table pointed to by the reporting feature is dropped
        False: the table pointed to by the reporting feature is appended to
    '''
    
    def __init__(self, system, configHelper, overwrite):
        super(ReportingQueryConfigurer, self).__init__(system, configHelper)
        self.__overwrite = overwrite
        self.__queryConfigurers = {
            ".mdb"  : self.__configureMdbReport,
            ".accdb": self.__configureMdbReport,
            ".xlsx" : self.__configureXlsOutputHandler,
            ".xls"  : self.__configureXlsOutputHandler,
            ".pptx" : self.__configurePptxOutputHandler,
			".db"   : self.__configureSQLiteOutputHandler,
            ".csv"  : self.__configureCsvOutputHandler
        }
    
    
    def configure(self, query, featureConfig):
        path = featureConfig.get("output_database") or featureConfig.get("file")
        _, ext = os.path.splitext(path)
        self.__queryConfigurers[ext](query, featureConfig)
        
        
    def __deleteSimilar(self, outputPath):
        # Delete the output file and any rotation-format output files.
        if os.path.exists(outputPath):
            os.unlink(outputPath)
            
        outputDir, outFile = os.path.split(outputPath)
        name, ext = os.path.splitext(outFile)
        reg = "{}_[0-9]*{}".format(name, ext)
        for fn in os.listdir(outputDir):
            if re.search(reg, fn):
                outPath = os.path.join(outputDir, fn)
                os.unlink(outPath)


    def __configureMdbReport(self, query, featureConfig):
        reportingDBPath = featureConfig.get("output_database") \
            or featureConfig.get("file")
            
        if reportingDBPath:
            reportingDBPath = os.path.abspath(reportingDBPath)

        if not os.path.exists(reportingDBPath):
            self.getSystem().getDatabaseService().create(reportingDBPath)
        
        reportingTable = featureConfig.get("output_table")
        reportingDB = self.getSystem().getConnectionManager().open(path=reportingDBPath)
        if self.__overwrite and reportingDB.hasTable(reportingTable):
            reportingDB.execute("DROP TABLE [%s]" % reportingTable)
            
        dbTitleColumn = featureConfig.get("db_title_column")
        mode = featureConfig.get("mode")
        if mode == "native":
            self.__configureStandardReportingFeature(
                    query, reportingDBPath, reportingTable, dbTitleColumn)
        else:
            self.__configureMdbOutputHandler(
                    query, reportingDBPath, reportingTable, dbTitleColumn)
        
        
    def __configureStandardReportingFeature(
            self, query, dbPath, table, dbTitleColumn):

        feature = ReportingQueryFeature(
                self.getSystem().getConnectionManager(),
                dbPath,
                table,
                dbTitleColumn)
        
        query.addFeature(feature)
    
    
    def __configureMdbOutputHandler(self, query, dbPath, table, dbTitleColumn):
        handler = MdbOutputHandler(
                self.getSystem().getConnectionManager(),
                dbPath,
                table,
                dbTitleColumn)
        
        query.setOutputHandler(handler)
    
        
    def __configureXlsOutputHandler(self, query, featureConfig):
        outputPath = os.path.abspath(featureConfig["file"])
        outputDir = os.path.dirname(outputPath)
        if not os.path.exists(outputDir):
            os.makedirs(outputDir)
        
        if self.__overwrite:
            self.__deleteSimilar(outputPath)
        
        template = featureConfig.get("template")
        if template:
            template = self.getConfigHelper().getAbsolutePath(template)
            if not os.path.exists(outputPath):
                shutil.copyfile(template, outputPath)
        
        worksheet = featureConfig["worksheet"]
        cell = featureConfig.get("cell") or "A1"
        header = featureConfig.get("header") or False
        rotate = featureConfig.get("rotate") or False
        append = featureConfig.get("append") or False
        
        handler = XlsOutputHandler(outputPath, worksheet, template, cell,
                                   header, rotate, append)
        
        query.setOutputHandler(handler)
        
        
    def __configureCsvOutputHandler(self, query, featureConfig):
        outputPath = os.path.abspath(featureConfig["file"])
        outputDir = os.path.dirname(outputPath)
        if not os.path.exists(outputDir):
            os.makedirs(outputDir)
        
        if self.__overwrite:
            self.__deleteSimilar(outputPath)
        
        delimiter = featureConfig.get("delimiter") or ","
        header = featureConfig.get("header") or False
        rotate = featureConfig.get("rotate") or False
        
        handler = CsvOutputHandler(outputPath, delimiter, header, rotate)
        query.setOutputHandler(handler)
        
        
    def __configurePptxOutputHandler(self, query, featureConfig):
        outputPath = os.path.abspath(featureConfig["file"])
        outputDir, _ = os.path.split(outputPath)
        if not os.path.exists(outputDir):
            os.makedirs(outputDir)
        
        if self.__overwrite and os.path.exists(outputPath):
            os.unlink(outputPath)
        
        template = featureConfig.get("template")
        if template:
            template = self.getConfigHelper().getAbsolutePath(template)
            if not os.path.exists(outputPath):
                shutil.copyfile(template, outputPath)
        
        slideNum = int(featureConfig["slide"])
        shapeName = featureConfig["shape"]
        
        handler = PptxOutputHandler(outputPath, slideNum, shapeName)
        query.setOutputHandler(handler)


    def __configureSQLiteOutputHandler(self, query, featureConfig):
        reportingDBPath = os.path.abspath(featureConfig["file"])
        reportingTable = featureConfig["output_table"]
        
        if os.path.exists(reportingDBPath):
            db = self.getSystem().getConnectionManager().open(path=reportingDBPath)
            if self.__overwrite and db.hasTable(reportingTable):
                db.execute("DROP TABLE [%s]" % reportingTable)
        
        dbTitleColumn = featureConfig.get("db_title_column")
        handler = SQLiteOutputHandler(self.getSystem().getConnectionManager(),
                                      reportingDBPath, reportingTable,
                                      dbTitleColumn)
        
        query.setOutputHandler(handler)
