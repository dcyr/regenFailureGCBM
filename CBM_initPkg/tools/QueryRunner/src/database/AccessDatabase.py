# core
import os
import re
import textwrap
import pywintypes
import logging

# contrib
import pyodbc
import win32com.client

# QueryRunner
from database.AbstractDatabase import AbstractDatabase
from database.DBAPICompliantDatabaseCursor import DBAPICompliantDatabaseCursor
from database.query.QueryError import QueryError
from dataimport.DataImportError import DataImportError

class AccessDatabase(AbstractDatabase):
    '''
    Holds a connection to a MS Access database.

    :param dbPath: full path to .mdb file, ex: ``r"c:\sdms\mydb.mdb"``
    :type dbPath: str
    :param connectParams: optional connection parameters
    :type connectParams: dict or None
    '''

    driver = "Microsoft Access Driver (*.mdb, *.accdb)"
    pyToSqlTypes = {"unicode"        : 10,
                    "float"          : 7,
                    "decimal.Decimal": 7,
                    "int"            : 4,
                    "str"            : 10,
                    "bool"           : 1,
                    "memo"           : 12}


    def __init__(self, path, **connectParams):
        self.__connection = None
        self.__dbPath = os.path.abspath(path)
        self.__connectParams = connectParams
        self.__importedTables = []
        self.__log = logging.getLogger("app.%s" % self.__class__.__name__)
        
        
    def __str__(self):
        return self.__dbPath
        

    def __connect(self, dbPath, connectParams):
        '''
        Connects to a database.

        :param dbPath: full path to .mdb file, ex: ``r"c:\sdms\mydb.mdb"``
        :type dbPath: str
        :param connectParams: optional connection parameters
        :type connectParams: dict or None
        :rtype: connection
        '''
        connectString = "DRIVER={%s};DBQ=%s" % (AccessDatabase.driver, dbPath)
        
        if connectParams is not None:
            for param, value in connectParams.iteritems():
                connectString += ";%s=%s" % (param, value)
            
        connection = None
        
        try:
            connection = pyodbc.connect(connectString)
        except pyodbc.Error as detail:
            raise Exception("Error connecting to %s: %s" % (dbPath, detail))
            
        return connection
    
    
    def __getConnection(self):
        '''
        Gets the active connection for this instance, opening a new one if
        necessary.

        :rtype: connection
        '''
        if self.__connection is None:
            self.__connection = self.__connect(self.__dbPath,
                                               self.__connectParams)
            
        return self.__connection
    
    
    def close(self):
        '''
        Closes the database connection.
        '''
        if self.__connection is not None:
            self.__connection.close()
            self.__connection = None
            
    
    def query(self, sql, params=None):
        '''
        Performs a read-only query.

        :param sql: SQL to execute
        :type sql: str
        :param params: SQL parameters
        :type params: list or None
        :rtype: list of Row_\s
        
        .. _Row: http://code.google.com/p/pyodbc/wiki/Rows
        '''
        try:
            if params is not None:
                cur = self.__getConnection().cursor().execute(sql, params)
            else:
                cur = self.__getConnection().cursor().execute(sql)
        except pyodbc.Error as e:
            raise QueryError(e)
        
        return DBAPICompliantDatabaseCursor(cur, cur.description)
    
        
    def execute(self, sql, params=None):
        ''' 
        Executes and commits an SQL statement.
        
        :param sql: SQL to execute
        :type sql: str
        :param params: SQL parameters
        :type params: list or None
        :returns: the number of rows affected
        :rtype: int
        '''
        try:
            if params is not None:
                rowCount = self.__getConnection().cursor().execute(
                        sql, params).rowcount
            else:
                rowCount = self.__getConnection().cursor().execute(sql).rowcount
        except pyodbc.Error as e:
            raise QueryError(e)
            
        self.__getConnection().commit()
        self.close()
        
        return rowCount
    

    def executeMany(self, sql, params):
        ''' 
        Executes an SQL statement once per set of parameters.
        
        :param sql: SQL insert/update/delete statement to repeat
        :type sql: str
        :param params: SQL parameter lists
        :type params: list of lists
        '''
        try:
            self.__getConnection().cursor().executemany(sql, params)
        except pyodbc.Error as e:
            raise QueryError(e)
        
        self.__getConnection().commit()
        self.close()
        
    
    def hasTable(self, tableName):
        '''
        Checks if a table exists in the database.

        :param name: table name to find
        :type name: str
        :returns: True if found, False if not
        :rtype: boolean
        '''
        try:
            hasTable = self.__getConnection().cursor().tables(
                    table = tableName).fetchone() is not None
        except pyodbc.Error as e:
            raise QueryError(e)

        self.close()

        return hasTable


    def importData(self, dataImport):
        '''
        Imports data into the database.
        
        :param dataImport: the DataImport to store data from
        :type dataImport: `.DataImport`
        '''
        columnNames = list(dataImport.getColumns())
        if not columnNames:
            raise DataImportError(
                    "Error processing data import '{0}': No column names "
                    "specified. Either configure the column names explicitly or "
                    "ensure that the input data contains a header row.".format(
                            dataImport.getName()))
        
        titleColumn = dataImport.getTitleColumn()
        if titleColumn:
            columnNames.insert(0, titleColumn)
        columnNames = self.__cleanColumnNames(columnNames)
        
        columnTypes = dataImport.getTypes()
        if titleColumn:
            columnTypes.insert(0, "str")

        dbEngine = win32com.client.Dispatch("DAO.DBEngine.120")
        db = dbEngine.OpenDatabase(self.__dbPath)
        recordSet = None
        try:
            tableName = dataImport.getDestination()
            self.__initializeTable(db, tableName, columnNames, columnTypes,
                                   dataImport.overwrite())
    
            recordSet = db.OpenRecordset(tableName)
            fields = self.__extractFields(recordSet, columnNames)
            count = 0
            for count, row in enumerate(dataImport.getRows(), 1):
                if titleColumn:
                    row.insert(0, dataImport.getName())
                    
                if len(row) > len(fields):
                    raise DataImportError(
                            "Error processing data import '{0}': {1} columns "
                            "expected, but data contains {2}. Check configured "
                            "column names.".format(dataImport.getName(),
                                                   len(fields), len(row)))
                
                recordSet.AddNew()
                for i, value in enumerate(row):
                    if value is None or self.__isSpace(value):
                        continue
                    fields[i].Value = value
                
                recordSet.Update()
                if count % 10000 == 0:
                    self.__log.info("Imported {} rows.".format(count))
            
            self.__log.info("Imported {} rows.".format(count))
        finally:
            if recordSet:
                recordSet.Close()
            db.Close()
        

    def __cleanColumnNames(self, columnNames):
        # Non-alphanumeric characters are not allowed in database column names.
        return [re.sub("[^0-9a-zA-Z\*\-\ \(\)']+", "_", str(col))
                for col in columnNames]
    
    
    def __isSpace(self, value):
        if isinstance(value, str):
            return str(value).isspace() or str(value) == ""
        if isinstance(value, unicode):
            return unicode(value).isspace() or unicode(value) == ""
        return False
    
    
    def __initializeTable(self, db, tableName, columnNames, columnTypes,
                          overwrite=True):
        if tableName not in self.__importedTables:
            tableExists = False
            for tableDef in db.TableDefs:
                if tableDef.Name == tableName:
                    if overwrite:
                        db.TableDefs.Delete(tableName)
                    else:
                        tableExists = True

            if not tableExists:
                table = db.CreateTableDef(tableName)
                for name, pyType in zip(columnNames, columnTypes):
                    table.Fields.Append(table.CreateField(
                            name, AccessDatabase.pyToSqlTypes[pyType]))
                
                try:
                    db.TableDefs.Append(table)
                except pywintypes.com_error as e:
                    raise DataImportError(textwrap.dedent("""
                        Error adding table '{table}': {error}
                        Column names: {columns}
                        Column types: {types}
                        """.format(table=tableName, error=e.excepinfo[2],
                                   columns=", ".join(columnNames),
                                   types=", ".join(columnTypes))))
                
            self.__importedTables.append(tableName)
    
    
    def __extractFields(self, recordSet, columnNames):
        fields = []
        for name in columnNames:
            try:
                fields.append(recordSet.Fields[name])
            except:
                raise DataImportError(textwrap.dedent("""
                    No field named '{0}' found in input data.
                    Input data fields: {1}""".format(
                            name,
                            ", ".join((f.Name for f in recordSet.Fields)))))
        return fields
