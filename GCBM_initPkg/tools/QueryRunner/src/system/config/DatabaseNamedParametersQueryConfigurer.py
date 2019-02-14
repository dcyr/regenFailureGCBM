# QueryRunner
from AbstractQueryConfigurer import AbstractQueryConfigurer
from database.query.MultiDatabaseNamedParameterQueryFeature import MultiDatabaseNamedParameterQueryFeature

class DatabaseNamedParametersQueryConfigurer(AbstractQueryConfigurer):
    
    def configure(self, query, featureConfig):
        multiDatabaseParams = {}
        
        for dbTitle, dbParams in featureConfig.iteritems():
            multiDatabaseParams[dbTitle] = self.__parseParams(dbParams)
            
        feature = MultiDatabaseNamedParameterQueryFeature(multiDatabaseParams)
        query.addFeature(feature)


    def __parseParams(self, paramDict):
        parsedParams = {}

        for param, value in paramDict.iteritems():
            # Named-parameter substitution uses strings for simplicity;
            # this builds a single string for named parameter values
            # which are lists.
            if isinstance(value, str):
                parsedParams[param] = value
            else:
                parsedParams[param] = ", ".join(value)

        return parsedParams
