# QueryRunner
from system.task.AbstractTask import AbstractTask

class PreprocessorTask(AbstractTask):
    '''
    Performs required steps before any task modules are able to run.
    
    #. Calls initialize() on each :class:`.QueryRunnerDatabase` to create
       working copies of original input databases.
    '''
    
    def execute(self):
        '''
        See :meth:`.AbstractTask.execute`.
        '''
        activeDBs = self.getSystem().getConfig().getActiveDBs()

        for db in activeDBs:
            log = self.getLog(db)
            log.info("Initializing database...")
            
            overwriteMode = self.getSystem().getConfig().isOverwrite()
            self.getSystem().getConnectionManager().close(
                **db.getConnectionParameters())
            
            db.initialize(overwriteMode)
