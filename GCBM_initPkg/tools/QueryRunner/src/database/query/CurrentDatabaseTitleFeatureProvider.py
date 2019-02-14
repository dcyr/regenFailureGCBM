# QueryRunner
from AbstractFeatureProvider import AbstractFeatureProvider
from MultiDatabaseNamedParameterQueryFeature import MultiDatabaseNamedParameterQueryFeature
from ReportingQueryFeature import ReportingQueryFeature

class CurrentDatabaseTitleFeatureProvider(AbstractFeatureProvider):
    '''
    Provides the title of the current database being processed to query features
    which require it.
    
    :param dbTitle: the configured title of the current :class:`.AccessDatabase`
        being processed
    :type dbTitle: str
    '''
    
    def __init__(self, dbTitle):
        self.__dbTitle = dbTitle
        
    
    def supports(self, cls):
        return cls == MultiDatabaseNamedParameterQueryFeature \
            or cls == ReportingQueryFeature
    
    
    def getDBTitle(self):
        return self.__dbTitle
