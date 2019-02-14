# core
import os
import requests
import logging
import textwrap

# contrib
from paramiko import Transport
from paramiko import SFTPClient

# QueryRunner
from dataimport.CSVDataImport import CSVDataImport
from dataimport.XLSDataImport import XLSDataImport
from dataimport.SQLDataImport import SQLDataImport
from dataimport.DBFDataImport import DBFDataImport
from dataimport.Cell import Cell
from dataimport.CellRange import CellRange
from dataimport.DataImportError import DataImportError
from system.config.ConfigError import ConfigError

class DataImportFactory(object):
    '''
    Factory for creating :class:`.DataImport` objects from configuration.
    
    :param system: reference to the QueryRunner system instance
    :type system: :class:`.System`
    :param configHelper: reference to the QueryRunner configuration helper
    :type configHelper: :class:`.ConfigHelper`
    '''

    remoteProtocols = ["http://", "ftp://", "sftp://"]
   
    
    def __init__(self, system, configHelper):
        self.__system = system
        self.__configHelper = configHelper
        self.__importFactoryMethods = {".xls"  : self.__createXlsDataImport,
                                       ".xlsx" : self.__createXlsDataImport,
                                       ".xlsm" : self.__createXlsDataImport,
                                       ".csv"  : self.__createCsvDataImport,
                                       ".mdb"  : self.__createFileDbDataImport,
                                       ".accdb": self.__createFileDbDataImport,
                                       ".pg"   : self.__createPgDataImport,
                                       ".db"   : self.__createFileDbDataImport,
                                       ".dbf"  : self.__createDbfDataImport}


    def __getQuery(self, sqlFile=None, table=None):
        if sqlFile:
            return self.__configHelper.readFile(sqlFile)
        elif table:
            return "SELECT * FROM {0}".format(table)

        raise DataImportError("No query or table specified.")

    
    def __createFileDbDataImport(self, importTitle, importInfo):
        path = importInfo["file"]
        if not os.path.exists(path):
            raise DataImportError("File not found: {0}".format(
                    os.path.realpath(path)))
        
        table = importInfo.get("table")
        sql = importInfo.get("sql")
        query = self.__getQuery(sql, table)
        destination = importInfo.get("destination_table") or importTitle
        overwrite = self.__system.getConfig().isOverwrite()
        titleColumn = importInfo.get("import_title_column")
        nullValues = importInfo.get("null_values")
        dbNull = importInfo.get("db_null")
        types = importInfo.get("types")
        
        conn = self.__system.getConnectionManager().open(path=path)

        return SQLDataImport(name=importTitle,
                             destination=destination,
                             overwrite=overwrite,
                             db=conn,
                             query=query,
                             titleColumn=titleColumn,
                             nullValues=nullValues,
                             dbNull=dbNull,
                             types=types)

    
    def __createDbfDataImport(self, importTitle, importInfo):
        path = importInfo["file"]
        if not os.path.exists(path):
            raise DataImportError("File not found: {0}".format(
                    os.path.realpath(path)))
        
        destination = importInfo.get("destination_table") or importTitle
        overwrite = self.__system.getConfig().isOverwrite()
        titleColumn = importInfo.get("import_title_column")
        columns = importInfo.get("columns")
        types = importInfo.get("types")

        return DBFDataImport(name=importTitle,
                             path=path,
                             destination=destination,
                             overwrite=overwrite,
                             columns=columns,
                             types=types,
                             titleColumn=titleColumn)

    
    def __createPgDataImport(self, importTitle, importInfo):
        destination = importInfo.get("destination_table") or importTitle
        overwrite = self.__system.getConfig().isOverwrite()
        host = importInfo["host"]
        db = importInfo["db"]
        user = importInfo["user"]
        pwd = importInfo["pwd"]
        schema = importInfo.get("schema")
        table = importInfo.get("table")
        sql = importInfo.get("sql")
        query = self.__getQuery(sql, table)
        titleColumn = importInfo.get("import_title_column")
        conn = self.__system.getConnectionManager().open(
                host=host, db=db, user=user, pwd=pwd, schema=schema)

        return SQLDataImport(name=importTitle,
                             destination=destination,
                             overwrite=overwrite,
                             db=conn,
                             query=query,
                             titleColumn=titleColumn)

    
    def __createCsvDataImport(self, importTitle, importInfo):
        path = importInfo["file"]
        startLine = importInfo.get("start_line") or 1
        columns = importInfo.get("columns")
        variableColumns = None
        types = importInfo.get("types")
        nullValues = importInfo.get("null_values")
        dbNull = importInfo.get("db_null")
        destination = importInfo.get("destination_table") or importTitle
        overwrite = self.__system.getConfig().isOverwrite()
        titleColumn = importInfo.get("import_title_column")

        delimiter = importInfo.get("delimiter")
        if delimiter:
            delimiter = delimiter.decode("string_escape")
        
        if columns:
            expandedColumns = []
            for i, col in enumerate(columns):
                if "(" in col:
                    # Allow one "variable" column - a collection of columns
                    # which may not be entirely present in the file to import.
                    varCols = [varCol.strip() for varCol
                               in col[col.find("(") + 1:col.find(")")].split(",")]
                    variableColumns = (i, i + len(varCols))
                    for varCol in varCols:
                        expandedColumns.append(varCol)
                        
                    if types:
                        for _ in range(len(varCols) - 1):
                            types.insert(types[i])
                else:
                    expandedColumns.append(col)
            
            columns = expandedColumns
        
        return CSVDataImport(name=importTitle,
                             path=path,
                             destination=destination,
                             overwrite=overwrite,
                             startLine=int(startLine) - 1,
                             columns=columns,
                             variableColumns=variableColumns,
                             types=types,
                             delimiter=delimiter,
                             nullValues=nullValues,
                             dbNull=dbNull,
                             titleColumn=titleColumn)


    def __createXlsDataImport(self, importTitle, importInfo):
        path = importInfo["file"]
        worksheet = importInfo.get("worksheet")
        columns = importInfo.get("columns")
        types = importInfo.get("types")
        trimWhitespace = importInfo.get("trim_whitespace")
        nullValues = importInfo.get("null_values")
        dbNull = importInfo.get("db_null")
        destination = importInfo.get("destination_table") or importTitle
        overwrite = self.__system.getConfig().isOverwrite()
        titleColumn = importInfo.get("import_title_column")
        
        startCell = None
        startCellLabel = importInfo.get("start_cell")
        if startCellLabel:
            startCell = Cell.FromString(startCellLabel)

        endCell = None
        endCellLabel = importInfo.get("end_cell")
        if endCellLabel:
            endCell = Cell.FromString(endCellLabel)
        
        cellRange = None
        if startCell:
            cellRange = CellRange(startCell, endCell)
        
        return XLSDataImport(name=importTitle,
                             path=path,
                             destination=destination,
                             overwrite=overwrite,
                             worksheet=worksheet,
                             cellRange=cellRange,
                             columns=columns,
                             types=types,
                             trimWhitespace=trimWhitespace,
                             nullValues=nullValues,
                             dbNull=dbNull,
                             titleColumn=titleColumn)
        
    
    def __cacheIfRemote(self, importTitle, path):
        protocol = None
        for prefix in DataImportFactory.remoteProtocols:
            if path.startswith(prefix):
                protocol = prefix
                
        if not protocol:
            return path
        
        fileName = path.split("/").pop()
        outPath = os.path.join(self.__system.getConfig().getOutputPath(),
                               "imports",
                               "{0}_{1}".format(importTitle, fileName))
        
        if not os.path.exists(os.path.dirname(outPath)):
            os.makedirs(os.path.dirname(outPath))
        
        if not os.path.exists(outPath):
            self.__getLog().info("Downloading {0} to {1}".format(path, outPath))
            if protocol == "sftp://":
                loginInfo, hostPath = path.split("@")
                userName, password = loginInfo.rsplit(":", 1)
                userName = userName.split(protocol).pop()
                hostName, remotePath = hostPath.split("/", 1)
                transport = Transport((hostName, 22))
                transport.connect(username=userName, password=password)
                sftp = SFTPClient.from_transport(transport)
                sftp.get("/{0}".format(remotePath), outPath)
                transport.close()
            else:
                r = requests.get(path, stream=True)
                with open(outPath, "wb") as outFile:
                    for chunk in r.iter_content():
                        outFile.write(chunk)
        else:
            self.__getLog().info("Using existing {0} for {1}".format(outPath, path))
        
        return outPath
    
    
    def __getLog(self):
        return logging.getLogger("app.%s" % self.__class__.__name__)
    
    
    def createDataImportsFromConfig(self, importConfigSection):
        '''
        Creates a list of :class:`.DataImport` objects from a configuration
        section.
        
        :param importConfigSection: the data_import configuration section
        :type importConfigSection: dict
        :returns: the constructed data import tasks
        :rtype: list of :class:`.DataImport`
        '''
        dataImports = []
        for importTitle in sorted(
                importConfigSection,
                key=lambda importTitle: int(importConfigSection[importTitle]["order"])):

            importInfo = importConfigSection[importTitle]
            
            files = []
            if "file" in importInfo:
                importFile = importInfo["file"]
                if isinstance(importFile, list): 
                    files = [dataImport.strip() for dataImport in importFile]
                elif isinstance(importFile, (str, unicode)):
                    files = [dataImport.strip() for dataImport in importFile.split(",")]
            elif importInfo.get("type") == "pg":
                fileType = importInfo.get("type")
                ext = ".{0}".format(fileType)
                dataImport = self.__importFactoryMethods[ext](importTitle, importInfo)
                dataImports.append(dataImport)
            else:
                raise ConfigError(textwrap.dedent("""
                        Missing file path for data import {0}: '{1}'.""".format(
                        importInfo['order'], importTitle)))
            
            for dataImport in files:
                importInfo["file"] = self.__cacheIfRemote(importTitle, dataImport)
                fileType = importInfo.get("type")
                if fileType:
                    # User-specified file format.
                    ext = ".{0}".format(fileType)
                else:
                    # Format not specified - use file extension.
                    importFile = importInfo["file"]
                    _, ext = os.path.splitext(importFile)

                if ext not in self.__importFactoryMethods:
                    raise ConfigError(textwrap.dedent("""
                            Unrecognized file type '{0}' for import '{1}'.
                            Please specify file type using 'type = '.""".format(
                                    ext, importTitle)))
                
                dataImport = self.__importFactoryMethods[ext](importTitle, importInfo)
                dataImports.append(dataImport)
         
        return dataImports
