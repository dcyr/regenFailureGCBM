class AbstractDatabase(object):
    '''
    Base class for database connections.
    '''

    def close(self):
        '''
        Closes the database connection.
        '''
        raise NotImplementedError
            
    
    def query(self, sql, params=None):
        '''
        Performs a read-only query.

        :param sql: SQL to execute
        :type sql: str
        :param params: SQL parameters
        :type params: list or None
        :rtype: :class:`.AbstractCursor`
        '''
        raise NotImplementedError
    
        
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
        raise NotImplementedError
    

    def executeMany(self, sql, params):
        ''' 
        Executes an SQL statement once per set of parameters.
        
        :param sql: SQL insert/update/delete statement to repeat
        :type sql: str
        :param params: SQL parameter lists
        :type params: list of lists
        '''
        raise NotImplementedError
        
    
    def hasTable(self, tableName):
        '''
        Checks if a table exists in the database.

        :param name: table name to find
        :type name: str
        :returns: True if found, False if not
        :rtype: boolean
        '''
        raise NotImplementedError()
    
    
    def importData(self, dataImport):
        '''
        Imports data into the database.
        
        :param dataImport: the DataImport to store data from
        :type dataImport: `.DataImport`
        '''
        raise NotImplementedError()
    