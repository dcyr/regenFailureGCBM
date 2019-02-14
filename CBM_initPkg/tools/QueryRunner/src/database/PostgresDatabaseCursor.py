# QueryRunner
from database.AbstractCursor import AbstractCursor

class PostgresDatabaseCursor(AbstractCursor):
    '''
    Wraps a Postgres database cursor to standardize the way QueryRunner modules
    interact with them.
    '''

    pgToPyTypes = {"bool"   : "bool",
                   "int4"   : "int",
                   "float4" : "float",
                   "float8" : "float",
                   "text"   : "str",
                   "varchar": "str",
                   "name"   : "str",
                   "unknown": "str"}

    
    def __init__(self, db, cursor, description):
        self.__db = db
        self.__cur = cursor
        self.__description = description
        self.__columns = []
        self.__types = []
        
    
    def next(self):
        row = self.__cur.fetchone()
        if row is None:
            self.__cur.close()
            raise StopIteration()
        
        return [row[i] for i in range(len(self.__columns))]
        
    
    def getColumns(self):
        if self.__description and not self.__columns:
            self.__columns = [col[0] for col in self.__description]
            
        return self.__columns
    
    
    def getTypes(self):
        if self.__description and not self.__types:
            typeIds = [col[1] for col in self.__description]
            self.__types = []
            for oid in typeIds:
                cur = self.__db.cursor()
                cur.execute("SELECT typname FROM pg_type WHERE oid = {0}"
                            .format(oid))
                
                pgType = cur.fetchone()[0]
                cur.close()
                if pgType not in PostgresDatabaseCursor.pgToPyTypes:
                    raise KeyError("No python type mapping for pg type: {0}"
                                   .format(pgType))
                
                self.__types.append(PostgresDatabaseCursor.pgToPyTypes[pgType])

        return self.__types
