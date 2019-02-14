# QueryRunner
from AbstractQueryRunnerDatabase import AbstractQueryRunnerDatabase
from database.PostgresDatabase import PostgresDatabase

class PostgresQueryRunnerDatabase(AbstractQueryRunnerDatabase):
    '''
    Encapsulates information about a Postgres database.
    
    :param title: database title
    :type title: str
    :param host: the hostname or IP address of the Postgres server
    :type host: str
    :param db: the database on the Postgres server to connect to
    :type db: str
    :param user: the user to connect as
    :type user: str
    :param pwd: the user's password
    :type pwd: str
    :param schema: optional - the schema to execute queries against
    :type schema: str
    '''

    def __init__(self, title, host, db, user, pwd, schema=None):
        self.__initialized = False
        self.__title = title
        self.__host = host
        self.__db = db
        self.__user = user
        self.__pwd = pwd
        self.__schema = schema
        
        
    def __str__(self):
        return """
               Title: %(title)s
               Host: %(host)s
               DB: %(db)s
               Schema: %(schema)s
               """ % {"title" : self.__title,
                      "host"  : self.__host,
                      "db"    : self.__db,
                      "schema": self.__schema}
    
    
    def getTitle(self):
        '''
        :returns: database title
        :rtype: str
        '''
        return self.__title
    
    
    def getConnectionParameters(self):
        return {"host"  : self.__host,
                "db"    : self.__db,
                "user"  : self.__user,
                "pwd"   : self.__pwd,
                "schema": self.__schema}
    
    
    def initialize(self, overwrite=False):
        if self.__initialized:
            raise RuntimeError("Database has already been initialized!")
        
        db = None
        try:
            db = PostgresDatabase(self.__host, self.__user, self.__pwd, self.__db)
            if self.__schema:
                if overwrite:
                    db.execute("DROP SCHEMA IF EXISTS {} CASCADE".format(self.__schema))
                if not db.hasSchema(self.__schema):
                    db.execute("CREATE SCHEMA {}".format(self.__schema))
                    
            self.__initialized = True
        
        finally:
            if db:
                db.close()
