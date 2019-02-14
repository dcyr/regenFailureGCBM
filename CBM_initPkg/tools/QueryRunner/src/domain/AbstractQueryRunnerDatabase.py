class AbstractQueryRunnerDatabase(object):
    '''
    Encapsulates information about a database.
    
    :param title: database title
    :type title: str
    :param originalDBPath: path to the target database
    :type originalDBPath: str
    :param workingDBPath: path to the working copy of the target database
    :type workingDBPath: str
    '''

    def getTitle(self):
        '''
        :returns: database title
        :rtype: str
        '''
        raise NotImplementedError
    
    
    def getConnectionParameters(self):
        '''
        :returns: a dictionary of connection parameters for this database
        :rtype: dict
        '''
        raise NotImplementedError
    
    
    def initialize(self, overwrite=False):
        '''
        Performs any initialization needed for the database.
        
        :param overwrite: overwrite the old working database, if it exists
        :type overwrite: boolean
        '''
        raise NotImplementedError
        