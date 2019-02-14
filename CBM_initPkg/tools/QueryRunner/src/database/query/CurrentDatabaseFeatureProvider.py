# QueryRunner
from AbstractFeatureProvider import AbstractFeatureProvider
from TemplatedQueryFeature import TemplatedQueryFeature

class CurrentDatabaseFeatureProvider(AbstractFeatureProvider):
    '''
    Provides a connection to the current working :class:`.AbstractDatabase`
    being processed to query features which require it.
    
    :param dbConnection: connection to the current working database.
    :type dbConnection: :class:`.AbstractDatabase`
    '''
    
    def __init__(self, dbConnection):
        self.__dbConnection = dbConnection
        
    
    def supports(self, cls):
        return cls == TemplatedQueryFeature
    
    
    def getDBConnection(self):
        return self.__dbConnection
    