# core
import logging

# QueryRunner
from QueryError import QueryError

class Query(object):
    '''
    Represents a database query. Queries consist of a title and an SQL statement,
    and optionally support features such as named parameters for composing the
    final query to be run.
    
    :param title: the title of the query
    :type title: str
    :param sql: the SQL comprising the query
    :type sql: str
    '''
    
    def __init__(self, title, sql):
        self.__title = title
        self.__sql = sql
        self.__features = []
        self.__outputHandler = None


    def addFeature(self, feature):
        '''
        Adds a feature to the query. Query features modify the query at run-time to
        provide functionality like named parameters, parameter sets, etc.
        
        :param feature: a feature used to modify the query
        :type feature: :class:`.AbstractQueryFeature`
        '''
        self.__features.append(feature)
    
    
    def setOutputHandler(self, outputHandler):
        '''
        Sets the optional output handler for the query. The output handler captures
        the output of the query and does something with it -- usually writing to a
        file.
        
        :param outputHandler: the output handler to attach to the query
        :type outputHandler: :class:`.AbstractOutputHandler`
        '''
        self.__outputHandler = outputHandler
        
        
    def getOutputHandler(self):
        '''
        :returns: the output handler for this query, if applicable.
        :rtype: :class:`.AbstractOutputHandler`
        '''
        return self.__outputHandler
        
    
    def getTitle(self):
        '''
        :returns: the title of this query
        :rtype: str
        '''
        return self.__title
    
    
    def getPreparedQueries(self, featureProviders=[]):
        '''
        :param featureProviders: the :class:`.AbstractFeatureProvider`
            corresponding to the feature to provide data for; for example, a
            feature which alters the SQL depending on the current
            :class:`.AccessDatabase` being processed might have a feature
            provider which contains the current :class:`.AccessDatabase`, which
            is then passed at runtime via this method
        :type featureProviders: list of :class:`.AbstractFeatureProvider`
        :returns: one or more executable queries which have been fully modified
            by the associated features
        :rtype: list of str
        '''
        queries = [self.__sql]
        
        for feature in self.__features:
            provider = self.__getProviderForFeature(feature, featureProviders)
            try:
                featureOutput = []
                for query in queries:
                    result = feature.prepareQuery(query, provider)
                    if isinstance(result, str) or isinstance(result, unicode):
                        featureOutput.append(result)
                    else:
                        featureOutput.extend(result)
                queries = featureOutput
            except QueryError as e:
                log = logging.getLogger(self.__class__.__name__)
                log.fatal("Error preparing query '%(query)s'.\n%(msg)s"
                          % {"query": self.__title,
                             "msg"  : str(e)})
                raise
            
        return queries


    def __getProviderForFeature(self, feature, featureProviders):
        '''
        :returns: the runtime data provider for a particular feature
        :rtype: :class:`.AbstractFeatureProvider`
        '''
        for provider in featureProviders:
            if provider.supports(feature.__class__):
                return provider
        
        return None
    