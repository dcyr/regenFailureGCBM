# QueryRunner
from system.task.AbstractTask import AbstractTask
from database.query.CurrentDatabaseTitleFeatureProvider import CurrentDatabaseTitleFeatureProvider
from database.query.CurrentDatabaseFeatureProvider import CurrentDatabaseFeatureProvider

class QueryRunnerTask(AbstractTask):
    '''
    Runs a generic set of queries against all active databases.
    
    :param system: reference to the system instance
    :type system: :class:`.System`
    :param queries: list of queries to execute
    :type queries: list of :class:`.Query`
    '''
    
    def __init__(self, system, queries):
        super(QueryRunnerTask, self).__init__(system)
        self.__queries = queries
    
    
    def execute(self):
        '''
        See :meth:`.AbstractTask.execute`.
        '''
        activeDBs = self.getSystem().getConfig().getActiveDBs()
        numQueries = len(self.__queries)
        
        for queryRunnerDB in activeDBs:
            log = self.getLog(queryRunnerDB)
            
            db = self.getSystem().getConnectionManager().open(
                    **queryRunnerDB.getConnectionParameters())
            
            queryFeatureProviders = [
                CurrentDatabaseTitleFeatureProvider(queryRunnerDB.getTitle()),
                CurrentDatabaseFeatureProvider(db)]

            for i, query in enumerate(self.__queries):
                log.info("Executing query %(num)i of %(total)i: %(query)s."
                         % {"num"  : i + 1,
                            "total": numQueries,
                            "query": query.getTitle()})

                for sql in query.getPreparedQueries(queryFeatureProviders):
                    outputHandler = query.getOutputHandler()
                    if outputHandler:
                        output = db.query(sql)
                        outputHandler.handle(queryRunnerDB.getTitle(), output)
                    else:
                        db.execute(sql)
