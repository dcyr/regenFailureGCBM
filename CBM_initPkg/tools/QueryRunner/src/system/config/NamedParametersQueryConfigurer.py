# QueryRunner
from AbstractQueryConfigurer import AbstractQueryConfigurer
from database.query.NamedParameterQueryFeature import NamedParameterQueryFeature

class NamedParametersQueryConfigurer(AbstractQueryConfigurer):
    
    def configure(self, query, featureConfig):
        params = {}

        for param, value in featureConfig.iteritems():
            # Named-parameter substitution uses strings for simplicity;
            # this builds a single string for named parameter values
            # which are lists.
            if isinstance(value, str):
                params[param] = value
            else:
                params[param] = ", ".join(value)
        
        feature = NamedParameterQueryFeature(params)
        query.addFeature(feature)
