# core
import win32com.client
import os
import logging
import sys

class DatabaseService(object):
    '''
    Provides convenience methods for using MS Access databases. 
    '''
    
    def __init__(self):
        self.__log = logging.getLogger(self.__class__.__name__)
        

    def __is64Bit(self):
        return sys.maxsize > 2147483647


    def create(self, path, overwrite=True):
        '''
        Creates an empty database.
        
        :param path: complete path to new database, including filename
        :type path: str
        :param overwrite: replace the database if it exists
        :type overwrite: boolean
        '''
        if os.path.exists(path):
            if overwrite:
                os.unlink(path)
            else:
                self.__log.debug("Preserved existing %s", path)
                return
            
        destDir = os.path.dirname(path)
        if destDir and not os.path.exists(destDir):
            os.makedirs(destDir)

        provider = "Microsoft.ACE.OLEDB.12.0" if self.__is64Bit() \
            else "Microsoft.Jet.OLEDB.4.0"
        
        dsn = ";".join(("Provider={0}",
                        "Jet OLEDB:Engine Type=5",
                        "Data Source={1}")).format(provider, path)
        
        catalog = win32com.client.Dispatch("ADOX.Catalog")
        catalog.Create(dsn)
        
        self.__log.debug("Created %s", path)
