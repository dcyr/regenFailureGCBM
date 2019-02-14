# QueryRunner
from system.task.AbstractTask import AbstractTask

class DataImporterTask(AbstractTask):
    '''
    Imports data into each configured database.
    
    :param system: reference to the system instance
    :type system: :class:`.System`
    :param dataImports: list of data imports to perform
    :type queries: list of :class:`.DataImport`
    '''

    def __init__(self, system, dataImports):
        super(DataImporterTask, self).__init__(system)
        self.__dataImports = dataImports

    
    def execute(self):
        '''
        See :meth:`.AbstractTask.execute`.
        '''
        activeDBs = self.getSystem().getConfig().getActiveDBs()
        numImports = len(self.__dataImports)
        
        for queryRunnerDB in activeDBs:
            log = self.getLog(queryRunnerDB)
            db = self.getSystem().getConnectionManager().open(
                  **queryRunnerDB.getConnectionParameters())
            
            for i, dataImport in enumerate(self.__dataImports):
                log.info("Executing data import %(num)i of %(total)i: %(query)s."
                         % {"num"  : i + 1,
                            "total": numImports,
                            "query": dataImport.getName()})

                db.importData(dataImport)
