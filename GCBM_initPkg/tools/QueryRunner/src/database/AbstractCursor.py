class AbstractCursor(object):
    '''
    Wraps a native database cursor to standardize the way QueryRunner modules
    interact with them.
    '''
    
    def __iter__(self):
        return self
    
    
    def next(self):
        raise NotImplementedError

    
    def getColumns(self):
        raise NotImplementedError
    
    
    def getTypes(self):
        raise NotImplementedError
