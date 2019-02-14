# QueryRunner
from util.SQLTemplate import SQLTemplate
from AbstractQueryFeature import AbstractQueryFeature

class MultiNamedParameterQueryFeature(AbstractQueryFeature):
    '''
    Enables named parameter support in queries using familiar notation. Named
    parameters are included in SQL statements using a colon prefix followed by
    a variable name, i.e. ``:disturbance_type_ids``.
    
    :param keys: a list of the named parameters in the query
    :type keys: list of str
    :param paramSets: a list of lists of values for the named parameters. Each
        list of values must match the order of the named parameters in
        :param:`keys`
    '''
    
    def __init__(self, keys, paramSets):
        self.__keys = keys
        self.__paramSets = paramSets
        
    
    def prepareQuery(self, sql, featureProvider=None):
        queries = []
        for params in self.__paramSets:
            # Handles specific case where a parameter is a UNC file path, in
            # which case the leading \\ needs to be double-escaped.
            paramMap = dict(zip(self.__keys,
                                [p.replace("\\", "\\\\", 1) for p in params]))
            
            queries.append(SQLTemplate(sql).safe_substitute(paramMap))
        
        return queries
