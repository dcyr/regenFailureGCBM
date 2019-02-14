# QueryRunner
from AbstractQueryConfigurer import AbstractQueryConfigurer
from database.query.MultiNamedParameterQueryFeature import MultiNamedParameterQueryFeature

class MultiNamedParametersQueryConfigurer(AbstractQueryConfigurer):
    '''
    Factory for creating :class:`MultiNamedParameterQueryFeature`s from configuration.
    '''
    
    def configure(self, query, featureConfig):
        '''
        Creates a :class:`.MultiNamedParameterQueryFeature` from a dictionary of
        configuration options. Expects a dictionary with the following schema,
        where the key ``keys`` is an ordered list of named parameters in the
        query, and ``value_sets`` is a list of lists of values to fill in the
        keys with:

            {
                "keys": ["key1", "key2"]
                "value_sets": [
                    ["key1value1", "key2value1"],
                    ["key1value2", "key2value2"]
                ]
            }
        
        See :meth:`.AbstractQueryConfigurer.configure`.
        
        :param featureConfig: configuration dictionary for query feature
        :type featureConfig: dict
        :returns: the requested feature
        :rtype: :class:`.NamedParameterQueryFeature`
        '''
        keys = featureConfig["keys"]
        if not isinstance(keys, list):
            keys = [keys]
        
        valueSets = []

        for rawValueSet in eval(featureConfig["value_sets"]):
            valueSet = []
            for value in rawValueSet:
                # Named-parameter substitution uses strings for simplicity;
                # this builds a single string for named parameter values
                # which are lists.
                if isinstance(value, list):
                    valueSet.append(", ".join([str(val) for val in value]))
                else:
                    valueSet.append(str(value))

            valueSets.append(valueSet)
            
        feature = MultiNamedParameterQueryFeature(keys, valueSets)
        query.addFeature(feature)
        