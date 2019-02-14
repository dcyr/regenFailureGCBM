# QueryRunner
from util.SQLTemplate import SQLTemplate
from AbstractQueryFeature import AbstractQueryFeature

class NamedParameterQueryFeature(AbstractQueryFeature):
    '''
    Enables named parameter support in queries using familiar notation. Named
    parameters are included in SQL statements using a colon prefix followed by
    a variable name, i.e. ``:disturbance_type_ids``.
    
    :param params: a dictionary of named parameters to their actual values.
    :type params: dict of str to object
    '''
    
    def __init__(self, params):
        self.__params = params
        
    
    def prepareQuery(self, sql, featureProvider=None):
        return SQLTemplate(sql).safe_substitute(self.__params)
    