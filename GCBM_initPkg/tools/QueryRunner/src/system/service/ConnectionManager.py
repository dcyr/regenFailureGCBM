# core
import logging

class ConnectionManager(object):
    '''
    Manages opening, closing, and pooling database connections.
    
    :param connectionFactory: factory for creating database connections
    :type connectionFactory: object
    '''

    def __init__(self, connectionFactory):
        self.__connectionFactory = connectionFactory
        self.__log = logging.getLogger("%s.%s"
                                       % (__name__, self.__class__.__name__))
        self.__connections = {}
        
    
    def __createConnectionKey(self, **kwargs):
        return ";".join((":".join((k, v)) for k, v in kwargs.iteritems()))
        
        
    def __close(self, connectionKey):
        '''
        Closes a database connection and removes it from the pool.
        
        :param connectionKey: the unique internal identifier for the connection
        '''
        if connectionKey in self.__connections:
            self.__connections[connectionKey].close()
            del self.__connections[connectionKey]
            self.__log.debug("Closed connection to %s", connectionKey)
    
    
    def open(self, **kwargs):
        '''
        Opens a database connection.  Attempts to retrieve an existing
        connection from the pool before creating a new connection.
        
        :param kwargs: the connection parameters to use
        :rtype: :class:`.AbstractDatabase`
        '''
        connectionKey = self.__createConnectionKey(**kwargs)
        if not connectionKey in self.__connections:
            connection = self.__connectionFactory.getConnection(**kwargs)
            self.__connections[connectionKey] = connection
            self.__log.debug("Opened new connection to %s", connectionKey)

        return self.__connections[connectionKey]
    
    
    def close(self, **kwargs):
        '''
        Closes a database connection and removes it from the pool.
        
        :param kwargs: the connection parameters
        '''
        connectionKey = self.__createConnectionKey(**kwargs)
        self.__close(connectionKey)
    
    
    def closeAll(self):
        '''
        Closes all open database connections.
        '''
        for key in self.__connections.keys():
            self.__close(key)
