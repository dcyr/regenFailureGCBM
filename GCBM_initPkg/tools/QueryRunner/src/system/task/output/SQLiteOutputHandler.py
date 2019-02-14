# core
import os

# contrib
import tempfile
import csv

# QueryRunner
from AbstractOutputHandler import AbstractOutputHandler

class SQLiteOutputHandler(AbstractOutputHandler):
    '''
    Writes query output to an SQLite database
    
    :param connectionManager: connection manager service
    :type connectionManager: :class:`.ConnectionManager`
    :param outputDBPath: path to the output database
    :type outputDBPath: str 
    :param outputTable: table to append query results to 
    :type outputTable: str
    '''
    
    pyToSqlTypes = {"unicode"        : "TEXT",
                    "str"            : "TEXT",
                    "memo"           : "TEXT",
                    "float"          : "REAL",
                    "decimal.Decimal": "REAL",
                    "int"            : "INTEGER",
                    "bool"           : "INTEGER",
                    "None"           : "NONE"}
    
    
    def __init__(self, connectionManager, outputDBPath, outputTable,
                 dbTitleColumn=None):
        self.__connectionManager = connectionManager
        self.__outputDBPath = outputDBPath
        self.__outputTable = outputTable
        self.__dbTitleColumn = dbTitleColumn
        

    def __unicodeCsvReader(self, utf8Data, dialect=csv.excel, **kwargs):
        '''
        Credit http://stackoverflow.com/questions/904041/reading-a-utf8-csv-file-with-python
        '''
        reader = csv.reader(utf8Data, dialect=dialect, **kwargs)
        for row in reader:
            yield [unicode(cell, "utf-8") for cell in row]
        
        
    def handle(self, dbTitle, output):
        ''' 
        See :meth:`.AbstractOutputHandler.handle`.
        '''
        db = self.__connectionManager.open(path=self.__outputDBPath)
        
        names = [col for col in output.getColumns()]
        if self.__dbTitleColumn:
                names.insert(0, self.__dbTitleColumn)

        if not db.hasTable(self.__outputTable):
            types = list(output.getTypes())
            if self.__dbTitleColumn:
                types.insert(0, "str")
                
            columns = []
            for colName, colType in zip(names, types):
                s = " ".join((colName, SQLiteOutputHandler.pyToSqlTypes[colType]))
                columns.append(s)
            columnDef = ",".join(columns)
            
            sql = "CREATE TABLE {} ({})".format(self.__outputTable, columnDef)
            db.execute(sql)

        sql = "INSERT INTO {} ({}) VALUES ({})".format(
                self.__outputTable,
                ",".join(names),
                ",".join("?" * len(names)))
        
        # Copy output database to a temporary csv file because cursor (output)
        # gets reset when execute is called.
        with tempfile.NamedTemporaryFile(
                suffix=".csv", 
                dir=os.path.dirname(self.__outputDBPath)) as temp:
            
            writer = csv.writer(temp)
            for row in output:
                if self.__dbTitleColumn:
                    row.insert(0, dbTitle)
                writer.writerow(row)
            temp.seek(0)
            
            batch = []
            for i, row in enumerate(self.__unicodeCsvReader(temp)):
                # maintain nulls through csv conversion
                batch.append([item if item else None for item in row])
                if i % 10000 == 0:
                    if batch:
                        db.executeMany(sql, batch)
                        batch = []
            
            if batch:
                db.executeMany(sql, batch)
