# QueryRunner
from AbstractQueryFeature import AbstractQueryFeature
from UnsupportedQueryFeatureError import UnsupportedQueryFeatureError
from IncompleteTemplateError import IncompleteTemplateError

class TemplatedQueryFeature(AbstractQueryFeature):
    '''
    Enables string interpolation support in queries. An external script is used
    to construct the dictionary used for interpolation; this can be treated as
    a configuration step outside the scope of the QueryRunner project. The
    external script, or "template provider," must contain the following method
    which returns a dictionary of string substitutions:
        
        getStrings(db)
        
    :param templateProvider: the template provider, imported as a module
    :type templateProvider: Python module
    '''
    
    def __init__(self, templateProvider):
        self.__templateProvider = templateProvider
        
    
    def __prepareInternal(self, sql, stringSubs):
        try:
            return sql % stringSubs
        except KeyError as e:
            raise IncompleteTemplateError(self.__templateProvider, str(e), sql)
        
        
    def prepareQuery(self, sql, featureProvider):
        if not featureProvider:
            raise UnsupportedQueryFeatureError(self)
        
        db = featureProvider.getDBConnection()
        providerOutput = self.__templateProvider.getStrings(db)
        if isinstance(providerOutput, dict):
            return self.__prepareInternal(sql, providerOutput)
        
        return [self.__prepareInternal(sql, stringSubs)
                for stringSubs in providerOutput]
