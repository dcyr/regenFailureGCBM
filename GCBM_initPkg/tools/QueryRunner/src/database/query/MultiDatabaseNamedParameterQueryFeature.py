# QueryRunner
from system.config.ConfigError import ConfigError
from util.SQLTemplate import SQLTemplate
from AbstractQueryFeature import AbstractQueryFeature
from UnsupportedQueryFeatureError import UnsupportedQueryFeatureError

class MultiDatabaseNamedParameterQueryFeature(AbstractQueryFeature):
    '''
    Enables named parameter support in queries using familiar notation. Named
    parameters are included in SQL statements using a colon prefix followed by
    a variable name, i.e. ``:disturbance_type_ids``.
    
    This differs from :class:`.NamedParameterQueryFeature` in that the value for
    each named parameter can vary by the current :class:`.AccessDatabase` being
    processed.
    
    :param databaseParams: a dictionary of database title to a dictionary of
        named parameters to their values.
    :type databaseParams: dict of str to dict of str to object
    '''
    
    def __init__(self, databaseParams):
        self.__databaseParams = databaseParams
        
        
    def prepareQuery(self, sql, featureProvider):
        if not featureProvider:
            raise UnsupportedQueryFeatureError(self)
            
        dbTitle = featureProvider.getDBTitle()
        dbParams = self.__databaseParams.get(dbTitle)
        if not dbParams:
            raise ConfigError(
                  "Missing entry for {} in database named parameters feature."
                  .format(dbTitle))
        
        return SQLTemplate(sql).safe_substitute(dbParams)
    