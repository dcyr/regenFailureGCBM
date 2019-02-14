# QueryRunner
from ConfigError import ConfigError

class UnrecognizedQueryFeatureError(ConfigError):
    '''
    Raised when the QueryRunner configuration file specifies a query feature
    that isn't recognized by the system -- more specifically, that there is no
    feature-creation factory registered for the feature's configuration key.
    
    :param featureName: the name of the unrecognized feature
    :type featureName: str
    '''
    
    def __init__(self, featureName):
        self.featureName = featureName
        
    
    def __str__(self):
        return "Configuration file specified an unknown query feature: %(name)s" % {
                   "name" : self.featureName}
    