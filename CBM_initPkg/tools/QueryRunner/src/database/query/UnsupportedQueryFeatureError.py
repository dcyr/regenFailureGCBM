# QueryRunner
from QueryError import QueryError

class UnsupportedQueryFeatureError(QueryError):
    '''
    Raised when a query feature used by a query was not supplied with its
    required feature provider by the caller of :meth:`.Query.getPreparedQuery`.
    
    :param feature: the concrete :class:`.AbstractQueryFeature` instance for
        which the corresponding concrete :class:`.AbstractFeatureProvider`
        instance was not provided
    '''
    
    def __init__(self, feature):
        self.feature = feature
        
    
    def __str__(self):
        return "Attempted to use %(feature)s without passing an instance of a " \
               "concrete AbstractFeatureProvider." % {
                    "feature" : self.feature.__class__.__name__}
    