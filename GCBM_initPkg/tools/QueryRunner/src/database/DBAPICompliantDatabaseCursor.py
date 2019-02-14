# QueryRunner
from database.AbstractCursor import AbstractCursor

class DBAPICompliantDatabaseCursor(AbstractCursor):
    '''
    Wraps a Python database API-compliant cursor (i.e. pyodbc) to
    standardize the way QueryRunner modules interact with them.
    '''
    
    def __init__(self, cur, description):
        self.__cur = cur
        self.__columns = [col[0] for col in description] if description else []
        self.__types = [str(col[1]).split("'")[1] for col in description] \
            if description else []
        
    
    def next(self):
        row = self.__cur.fetchone()
        if row is None:
            self.__cur.close()
            raise StopIteration()
        
        return [row[i] for i in range(len(self.__columns))]
        
    
    def getColumns(self):
        return self.__columns
    
    
    def getTypes(self):
        return self.__types
