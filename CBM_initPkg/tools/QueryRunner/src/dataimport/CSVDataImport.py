# QueryRunner
from DataImport import DataImport

# core
import csv

class CSVDataImport(DataImport):
    '''
    Reads a delimited text file for import into a database table.
    
    :param name: the default name of the destination table
    :type name: str
    :param path: the absolute path to the file to import
    :type path: str
    :param destination: the name of the table to import data into
    :type destination: str
    :param startLine: the first line of data in the file (no column names)
    :type startLine: int
    :param columns: the column names - if not specified, the first row will be
        used as column names
    :type columns: list
    :param variableColumns: a tuple representing a contiguous range within the
        columns list that can optionally be present
    :type variableColumns: tuple
    :param types: the column types - if not specified, they will be inferred
    :type types: list
    :param delimiter: the delimiter (default comma)
    :type delimiter: str
    :param nullValues: values that should be inserted into the database as null
    :type nullValues: list
    :param dbNull: value that represents null in the database (defaults to the
        native database null type)
    :type dbNull: object
    :param titleColumn: the name of the identifier column if multiple data
        imports are being stored in the same table
    :type titleColumn: str
    :param overwrite: overwrite the destination table if it exists (default: True)
    :type overwrite: boolean
    '''
    
    WHITESPACE_DELIMITER = "whitespace"

    
    def __init__(self, name, path, destination, startLine=0, columns=None,
                 variableColumns=None, types=None, delimiter=None,
                 nullValues=None, dbNull=None, titleColumn=None,
                 overwrite=True):
        self.__name = name
        self.__path = path
        self.__destination = destination
        self.__overwrite = overwrite
        self.__startLine = startLine
        self.__columns = columns
        self.__variableColumns = variableColumns
        self.__types = types
        self.__delimiter = delimiter
        self.__nullValues = nullValues or []
        self.__dbNull = dbNull
        self.__titleColumn = titleColumn
        self.__useFirstLineAsHeader = columns is None
        self.__registerDialect()
            
            
    def __registerDialect(self):
        if self.__delimiter is None \
        or self.__delimiter == CSVDataImport.WHITESPACE_DELIMITER:
            return

        csv.register_dialect(self.__delimiter, delimiter=self.__delimiter)


    def __inferType(self, value):
        if type(value) == type(0):
            return "int"

        if type(value) == type(0.0):
            return "float"
        
        return "str"
    
    
    def __transformValue(self, value):
        if value is None or value in self.__nullValues:
            value = self.__dbNull
                
        try:
            return int(value)
        except ValueError:
            pass
        
        try:
            return float(value)
        except ValueError:
            pass

        return value
    
    
    def __processLine(self, line):
        if self.__delimiter == CSVDataImport.WHITESPACE_DELIMITER:
            return [self.__transformValue(value) for value in line.split()]
        
        return [self.__transformValue(value) for value in line]
    
    
    def __getReader(self, inFile, startLine):
        if self.__delimiter == CSVDataImport.WHITESPACE_DELIMITER:
            reader = inFile
        else:
            reader = csv.reader(inFile, dialect=self.__delimiter)
            
        for _ in xrange(startLine):
            reader.next()
            
        return reader

    
    def __readFile(self, startLine):
        with open(self.__path, "rb") as inFile:
            reader = self.__getReader(inFile, startLine)
            for line in reader:
                values = self.__processLine(line)
                if not self.__variableColumns:
                    yield values
                else:
                    valuesToFill = len(self.__columns) - len(values)
                    fillFromPosition = self.__variableColumns[1] - valuesToFill
                    for _ in xrange(valuesToFill):
                        values.insert(fillFromPosition, None)
                    
                    yield values
    
    
    def getName(self):
        '''
        See :meth:`.DataImport.getName`.
        '''
        return self.__name
    
    
    def getDestination(self):
        '''
        See :meth:`.DataImport.getDestination'.
        '''
        return self.__destination
    
    
    def overwrite(self):
        '''
        See :meth:`.DataImport.overwrite`.
        '''
        return self.__overwrite
        
        
    def getTitleColumn(self):
        '''
        See :meth:`.DataImport.getTitleColumn`.
        '''
        return self.__titleColumn


    def getColumns(self):
        '''
        See :meth:`.DataImport.getColumns`.
        '''
        if not self.__columns:
            self.__columns = self.__readFile(self.__startLine).next()
        
        return self.__columns
    
    
    def getRows(self):
        '''
        See :meth:`.DataImport.getRows`.
        '''
        startLine = self.__startLine
        if self.__useFirstLineAsHeader:
            startLine += 1
           
        return self.__readFile(startLine)


    def getTypes(self):
        '''
        See :meth:`.DataImport.getTypes`.
        '''
        if not self.__types:
            firstRow = self.getRows().next()
            self.__types = [self.__inferType(value) for value in firstRow]
            
        return self.__types
