class AbstractQueryConfigurer(object):
    '''
    Base class for factories responsible for creating query features from
    configuration dictionaries.
    
    :param system: reference to the QueryRunner system object
    :type system: :class:`.System`
    :param configHelper: reference to the configuration file helper
    :type configHelper: :class:`.ConfigHelper`
    '''
    
    def __init__(self, system, configHelper):
        self.__system = system
        self.__configHelper = configHelper
        
    
    def getSystem(self):
        '''
        :returns: reference to the QueryRunner system instance
        :rtype: :class:`.System`
        '''
        return self.__system
    
    
    def getConfigHelper(self):
        '''
        :returns: reference to the QueryRunner configuration helper instance
        :rtype: :class:`.ConfigHelper`
        '''
        return self.__configHelper


    def configure(self, query, featureConfig):
        '''
        Creates a query feature from configuration.

        :param query: the query to configure
        :type query: :class:`.Query`
        :param featureConfig: the query feature's configuration dictionary
        :type featureConfig: dict
        '''
        raise NotImplementedError
    