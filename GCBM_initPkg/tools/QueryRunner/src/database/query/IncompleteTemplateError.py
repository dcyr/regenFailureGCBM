# QueryRunner
from QueryError import QueryError

class IncompleteTemplateError(QueryError):
    '''
    Raised when a template provider script does not supply all the string
    substitutions for a query which uses the :class:`.TemplatedQueryFeature`.
    
    :param templateProvider: the template provider module
    :type templateProvider: object
    :param key: the string interpolation key in the query which was not supplied
        a value
    :type key: str
    :param sql: the query text
    '''
    
    def __init__(self, templateProvider, key, sql):
        self.templateProvider = templateProvider
        self.key = key
        self.sql = sql
        
    
    def __str__(self):
        return "Template provider %(provider)s did not supply a string for " \
               "key: %(key)s in query:\n%(sql)s" % {
                   "provider": repr(self.templateProvider),
                   "key"     : self.key,
                   "sql"     : self.sql}
