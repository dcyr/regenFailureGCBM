# QueryRunner
from DataImport import DataImport

class SQLDataImport(DataImport):
    '''
    Imports data from a database.
    
    :param name: the default name of the destination table
    :type name: str
    :param destination: the name of the table to import data into
    :type destination: str
    :param db: the database to import from
    :type db: :class:`.AbstractDatabase`
    :param query: the query to import data from, executed against the target db
    :type query: str
    :param titleColumn: the name of the identifier column if multiple data
        imports are being stored in the same table
    :type titleColumn: str
    :param nullValues: values that should be inserted into the database as null
    :type nullValues: list
    :param dbNull: value that represents null in the database (defaults to the
        native database null type)
    :type dbNull: object
    :param types: the column types - if not specified, they will be inferred
    :type types: list
    :param overwrite: overwrite the destination table if it exists (default: True)
    :type overwrite: boolean
    '''
    
    def __init__(self, name, destination, db, query, titleColumn=None,
                 nullValues=None, dbNull=None, types=None,
                 overwrite=True):
        self.__name = name
        self.__destination = destination
        self.__overwrite = overwrite
        self.__titleColumn = titleColumn
        self.__nullValues = nullValues or []
        self.__dbNull = dbNull
        self.__db = db
        self.__query = query
        self.__columns = None
        self.__types = types
        self.__cur = None
        
    
    def __getCursor(self):
        if not self.__cur:
            self.__cur = self.__db.query(self.__query)
        
        return self.__cur 
    
    
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
            cur = self.__getCursor()
            self.__columns = cur.getColumns()
            
        return self.__columns
    
    
    def getRows(self):
        '''
        See :meth:`.DataImport.getRows`.
        '''        cur = self.__getCursor()        for row in cur:
            yield [row[i]
                   if row[i] is not None and unicode(row[i]) not in self.__nullValues
                   else self.__dbNull
                   for i in range(len(self.getColumns()))]
        
        self.__cur = None


    def getTypes(self):
        '''
        See :meth:`.DataImport.getTypes`.
        '''
        if not self.__types:
            cur = self.__getCursor()
            self.__types = cur.getTypes()
        
        return self.__types
