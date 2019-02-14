# contrib
from springpython.aop import ProxyFactoryObject

# QueryRunner
from AccessDatabase import AccessDatabase
from PostgresDatabase import PostgresDatabase
from SQLiteDatabase import SQLiteDatabase

class ConnectionFactory(object):
    '''
    Spring-python factory for database connections.

    :param interceptors: interceptor(s) to apply to returned connections
    :type interceptors: one or a list of springpython.aop.MethodInterceptor_\s
    
    .. _springpython.aop.MethodInterceptor:
        http://static.springsource.org/spring-python/1.2.x/pydoc/springpython.aop.html#MethodInterceptor
    '''
       
    def __init__(self, interceptors):
        self.__interceptors = interceptors
        
    
    def getConnection(self, **kwargs):
        '''
        Gets an aop proxy wrapping a database connection, applying any
        interceptors passed into the factory's constructor.

        :param kwargs: connection parameters
        :type kwargs: dict or None
        :returns: a proxy wrapping a database connection
        :rtype: springpython.aop.ProxyFactoryObject_
        
        .. _springpython.aop.ProxyFactoryObject:
            http://static.springsource.org/spring-python/1.2.x/pydoc/springpython.aop.html#ProxyFactoryObject
        '''
        path = kwargs.get("path")
        if path:
            if path.endswith(".db"):
                return ProxyFactoryObject(target=SQLiteDatabase(**kwargs),
                                          interceptors=self.__interceptors)
                
            return ProxyFactoryObject(target=AccessDatabase(**kwargs),
                                      interceptors=self.__interceptors)
        
        return ProxyFactoryObject(target=PostgresDatabase(**kwargs),
                                  interceptors=self.__interceptors)
