# core
import os
import logging

# contrib
from springpython.aop import MethodInterceptor

class QueryInterceptor(MethodInterceptor):
    '''
    Logs every query executed by the system.

    :param enabled: flag turning on or off query logging
    :type enabled: boolean
    '''
    
    def __init__(self, enabled=True):
        super(QueryInterceptor, self).__init__()
        self.__enabled = enabled
        if enabled:
            self.__log = logging.getLogger("query_logger")
        
    
    def invoke(self, invocation):
        '''
        See springpython.aop.MethodInterceptor_\.
        
        .. _springpython.aop.MethodInterceptor:
            http://static.springsource.org/spring-python/1.2.x/pydoc/springpython.aop.html#MethodInterceptor
        '''
        if not self.__enabled:
            return invocation.proceed()
        
        # Query can come with or without a parameters array.
        if len(invocation.args) == 1:
            sql = invocation.args[0]
            formattedQueries = [sql]
        else:
            sql, args = invocation.args
            formattedQueries = self.__formatRecursive(sql, args)
        
        dbName = os.path.basename(str(invocation.instance))
        logEntry = "\n".join((dbName, "\n".join(formattedQueries), "---"))
        self.__log.debug(logEntry)
        
        return invocation.proceed()
    
    
    def __formatRecursive(self, sql, args):
        results = []
        
        logSql = sql
        if isinstance(args, (list, tuple)):
            for arg in args:
                if isinstance(arg, (list, tuple)):
                    results.extend(self.__formatRecursive(sql, arg))
                else:
                    logSql = self.__replaceParameter(logSql, arg)
        else:
            logSql = self.__replaceParameter(logSql, args)
            
        if logSql != sql:
            results.append(logSql)
            
        return results
    
    
    def __replaceParameter(self, sql, param):
        wrapped = self.__wrap(param)
        return sql.replace("?", wrapped if isinstance(wrapped, basestring)
                           else str(wrapped), 1)


    def __wrap(self, obj):
        '''
        Converts a python string to a SQL string.
        
        :param obj: object to attempt to wrap in single quotes
        :type obj: object
        :returns: the wrapped string or the original object if not a string
        :rtype: str or object
        '''
        if isinstance(obj, str):
            return "'{}'".format(obj)
        if isinstance(obj, unicode):
            return u"'{}'".format(obj)
        return obj
