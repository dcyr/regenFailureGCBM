# QueryRunner
from database.AbstractCursor import AbstractCursor

class EmptyCursor(AbstractCursor):
    '''
    Returned when a query result is empty.
    '''
    
    def next(self):
        raise StopIteration()
        
    
    def getColumns(self):
        return []
    
    
    def getTypes(self):
        return []
