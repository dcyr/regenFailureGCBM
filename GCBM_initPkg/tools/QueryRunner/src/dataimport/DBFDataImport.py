# QueryRunner
from DataImport import DataImport
from DataImportError import DataImportError

# contrib
from dbfpy.dbf import Dbf

# core
from contextlib import contextmanager

class DBFDataImport(DataImport):
    '''
    Imports data from a DBF database (usually a shapefile).
    
    :param name: the default name of the destination table
    :type name: str
    :param path: the absolute path to the file to import
    :type path: str
    :param destination: the name of the table to import data into
    :type destination: str
    :param columns: the column names - if not specified, the first row will be
        used as column names
    :type columns: list
    :param types: the column types - if not specified, they will be inferred
    :type types: list
    :param titleColumn: the name of the identifier column if multiple data
        imports are being stored in the same table
    :type titleColumn: str
    :param overwrite: overwrite the destination table if it exists (default: True)
    :type overwrite: boolean
    '''
    
    dbfToPythonTypes = {
        "C": "unicode",
        "D": "unicode",
        "N": "int",
        "F": "float"
    }
    
    
    def __init__(self, name, path, destination, columns=None, types=None,
                 titleColumn=None, overwrite=True):
        self.__name = name
        self.__path = path
        self.__destination = destination
        self.__overwrite = overwrite
        self.__titleColumn = titleColumn
        self.__columns = columns
        self.__types = types
    
    
    @contextmanager
    def __openFile(self):
        try:
            db = Dbf(self.__path)
            yield db
        finally:
            db.close()
    
    
    def getName(self):
        '''
        See :meth:`.DataImport.getName`.
        '''
        return self.__name
    
    
    def getDestination(self):
        '''
        See :meth:`.DataImport.getDestination`.
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
            with self.__openFile() as db:
                self.__columns = [field.name for field in db.header.fields]

        return self.__columns
    
    
    def getRows(self):
        '''
        See :meth:`.DataImport.getRows`.
        '''        with self.__openFile() as db:
            for row in db:
                yield row.asList()


    def getTypes(self):
        '''
        See :meth:`.DataImport.getTypes`.
        '''
        if not self.__types:
            self.__types = []
            with self.__openFile() as db:
                for field in db.header.fields:
                    fieldType = DBFDataImport.dbfToPythonTypes.get(field.typeCode)
                    if not fieldType:
                        raise DataImportError("Unrecognized field type in DBF: {}"
                                              .format(field.typeCode))
                        
                    self.__types.append(fieldType)

        return self.__types
