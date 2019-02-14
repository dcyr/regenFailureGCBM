# QueryRunner
from UnrecognizedQueryFeatureError import UnrecognizedQueryFeatureError
from database.query.Query import Query
from ConfigError import ConfigError

class QueryFactory(object):
    '''
    Factory for creating :class:`.Query` objects from configuration.
    
    :param system: reference to the QueryRunner system instance
    :type system: :class:`.System`
    :param queryConfigurers: list of query configurers for modifying base queries
    :type queryConfigurers: list of :class:`.AbstractFeatureFactory`
    :param configHelper: reference to the QueryRunner configuration helper
    :type configHelper: :class:`.ConfigHelper`
    '''
    
    COMMENT_START = "--"
    
    
    def __init__(self, system, queryConfigurers, configHelper):
        self.__system = system
        self.__queryConfigurers = queryConfigurers
        self.__configHelper = configHelper
    
    
    def createQueriesFromConfig(self, queryConfigSection):
        '''
        Creates a list of :class:`.Query` objects from a configuration section.
        
        :param queryConfigSection: a standard queries configuration section
        :type queryConfigSection: dict
        :returns: the constructed queries
        :rtype: list of :class:`.Query`
        '''
        queries = []
        for queryTitle in sorted(
                queryConfigSection,
                key=lambda queryTitle: int(queryConfigSection[queryTitle]["order"])):
            
            queryInfo = queryConfigSection[queryTitle]
            
            try:
                sql = self.__configHelper.readFile(
                        queryInfo["sql"],
                        lambda line: line.split(QueryFactory.COMMENT_START)[0])
                sql = [query.strip() for query in sql.strip().split(';') if query]
            except IOError as e:
                raise ConfigError(str(e))
            for sqlQuery in sql:
                query = Query(queryTitle, sqlQuery)
                queryFeaturesSection = queryInfo.get("features")
                if queryFeaturesSection:
                    for featureName, featureConfig in queryFeaturesSection.iteritems():
    
                        factory = self.__queryConfigurers.get(featureName)
                        if not factory:
                            raise UnrecognizedQueryFeatureError(featureName)
                        
                        factory.configure(query, featureConfig)
                    
                queries.append(query)
         
        return queries
