class AbstractFeatureProvider(object):
    '''
    Subclasses of this provide runtime data to concrete instances of
    :class:`.AbstractQueryFeature`, i.e. the current :class:`.AccessDatabase`
    being processed for a feature which performs database-specific actions.
    '''
    
    def supports(self, cls):
        '''
        Checks if this feature provider supports a specific
        :class:`.AbstractQueryFeature` subclass.
        
        :param cls: the class of the :class:`.AbstractQueryFeature`
            implementation to check
        :type cls: class
        '''
        raise NotImplementedError
    