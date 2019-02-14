# core
import logging

class AbstractTask(object):
    '''
    Abstract base class for all task modules.

    :param system: reference to the system instance
    :type system: :class:`.System`
    '''
    
    def __init__(self, system):
        self.__system = system
        self.__log = logging.getLogger("app.%s" % self.__class__.__name__)


    def getSystem(self):
        '''
        :rtype: :class:`.System`
        '''
        return self.__system

        
    def getLog(self, db=None):
        '''
        Gets a logger for the task module: either the root logger, or a
        db-specific logger retrieved from the logging service.
        
        :param db: a specific db to retrieve a logger for
        :type db: :class:`.QueryRunnerDatabase`
        :rtype: Logger_
        
        .. _Logger: http://docs.python.org/library/logging.html#logging.Logger
        '''
        if db is not None:
            return logging.getLogger(
                    "app.%(task)s.%(db)s" % {"task": self.__class__.__name__,
                                             "db"  : db.getTitle()})
        
        return self.__log
    
   
    def execute(self):
        '''
        The entry point for the task module.  Subclasses are required to
        implement this method in order for the system to execute them.
        
        :raises: :exc:`NotImplementedError` if a subclass fails to implement
            this method
        '''
        raise NotImplementedError
        