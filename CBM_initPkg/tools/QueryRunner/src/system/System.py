class System(object):
    '''
    Holds references to system services.
    
    .. attribute:: shutdownRequested
    
        Boolean flag indicating whether a module has requested the application
        to terminate.  Well-behaved task modules should poll this flag and
        handle it appropriately.
    '''
    
    def __init__(self):
        self.__shutdownRequested = False


    def getConfig(self):
        '''
        :rtype: :class:`Config`
        '''
        return self.__config
    
    
    def setConfig(self, config):
        '''
        :param config: the QueryRunner system configuration
        :type config: :class:`Config`
        '''
        self.__config = config
    
    
    def getConnectionManager(self):
        '''
        :rtype: :class:`.ConnectionManager`
        '''
        return self.__connectionManager
    
    
    def setConnectionManager(self, connectionManager):
        '''
        :param connectionManager: service for managing database connections
        :type connectionManager: :class:`.ConnectionManager`
        '''
        self.__connectionManager = connectionManager
    
    
    def getDatabaseService(self):
        '''
        :rtype: :class:`.DatabaseService`
        '''
        return self.__databaseService
    
    
    def setDatabaseService(self, databaseService):
        '''
        :param databaseService: service for common database operations
        :type databaseService: :class:`.DatabaseService`
        '''
        self.__databaseService = databaseService
    

    def isShutdownRequested(self):
        '''
        :returns: the flag indicating whether or not the system has been
            requested to shut down
        :rtype: boolean
        '''
        return self.__shutdownRequested
    
    
    def shutdown(self):
        '''
        Callable by any QueryRunner module with access to the System object. Used
        to request a clean shutdown of the application: joins all of the threads
        being tracked by the system and closes any open database connections.
        '''
        self.__shutdownRequested = True
        self.__connectionManager.closeAll()
        