# core
import os
import shutil

# QueryRunner
from AbstractQueryRunnerDatabase import AbstractQueryRunnerDatabase

class SQLiteQueryRunnerDatabase(AbstractQueryRunnerDatabase):
    '''
    Encapsulates information about a database.
    
    :param title: database title
    :type title: str
    :param workingDBPath: the database path to execute queries against - either
        a new database or a copy of the database at ``originalDBPath``
    :type workingDBPath: str
    :param originalDBPath: (optional) path to the original database to make a
        copy of. If empty, a new working database will be created
    :type originalDBPath: str
    '''

    def __init__(self, title, workingDBPath, originalDBPath=None):
        self.__title          = title
        self.__originalDBPath = originalDBPath
        self.__workingDBPath  = workingDBPath
        self.__initialized    = False
        
        
    def __str__(self):
        return """
               Title: %(title)s
               Original DB Path: %(originalDBPath)s
               Working DB Path: %(workingDBPath)s
               """ % {"title"         : self.__title,
                      "originalDBPath": os.path.abspath(self.__originalDBPath)
                                        if self.__originalDBPath else "<new>",
                      "workingDBPath" : os.path.abspath(self.__workingDBPath)}
    
    
    def getTitle(self):
        '''
        :returns: database title
        :rtype: str
        '''
        return self.__title
    
    
    def getConnectionParameters(self):
        '''
        :returns: the path to the working copy of this database
        :rtype: str
        '''
        return {"path": os.path.abspath(self.__workingDBPath)}
    
    
    def initialize(self, overwrite=False):
        '''
        Initializes a database by creating a working copy of the original.
        
        :param overwrite: overwrite the old working database, if it exists
        :type overwrite: boolean
        '''
        if self.__initialized:
            raise RuntimeError("Database has already been initialized!")
        
        if overwrite or not os.path.exists(self.__workingDBPath):
            workingDir = os.path.dirname(self.__workingDBPath)
            if workingDir and not os.path.exists(workingDir):
                os.makedirs(workingDir)
                
            if os.path.isfile(self.__workingDBPath):
                os.remove(self.__workingDBPath)
            
            if self.__originalDBPath:
                shutil.copyfile(self.__originalDBPath, self.__workingDBPath)
                
        self.__initialized = True
        