class AbstractQueryFeature(object):
    '''
    Abstract base class for all query features, which modify the base query in
    some way. Subclasses must override :meth:`.prepareQuery`, which should
    return the modified query.
    '''
    
    def prepareQuery(self, sql, featureProvider=None):
        '''
        Modifies an SQL statement in some way in order to provide a particular
        feature, i.e. named parameters.
    
        :param sql: the SQL statement to use as input
        :type sql: str
        :param featureProvider: a :class:`.FeatureProvider` subclass which
            provides any runtime data required by a concrete
            :class:`.AbstractQueryFeature` implementation. This argument is
            optional, as some features only require static data which is known
            ahead of time.
        '''
        raise NotImplementedError
