# QueryRunner
from database.AbstractCursor import AbstractCursor

class SQLiteDatabaseCursor(AbstractCursor):
    '''
    Wraps a SQLite cursor to standardize the way QueryRunner modules interact
    with them.
    '''
    
    def __init__(self, cursor, cols, types):
        self.__columns = cols
        self.__types = types
        self.__cur = cursor
        
    
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
