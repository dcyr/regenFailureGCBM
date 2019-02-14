# core
import logging

# contrib
import psycopg2

# QueryRunner
from database.AbstractDatabase import AbstractDatabase
from database.PostgresDatabaseCursor import PostgresDatabaseCursor
from database.query.QueryError import QueryError
from dataimport.DataImportError import DataImportError

class PostgresDatabase(AbstractDatabase):
    '''
    Holds a connection to a Postgres database.

    :param host: the hostname or IP address of the Postgres server
    :type host: str
    :param user: the user to connect as
    :type user: str
    :param pwd: the user's password
    :type pwd: str
    :param db: the database on the Postgres server to connect to
    :type db: str
    :param schema: optional - the schema to execute queries against
    :type schema: str
    '''
    
    decimalDigits = 6

    pyToSqlTypes = {"unicode"        : "TEXT",
                    "float"          : "REAL",
                    "decimal.Decimal": "REAL",
                    "int"            : "INTEGER",
                    "str"            : "TEXT",
                    "bool"           : "INTEGER",
                    "memo"           : "TEXT",
                    "None"           : "TEXT"}
    

    def __init__(self, host, user, pwd, db, schema=None):
        self.__connection = None
        self.__host = host
        self.__user = user
        self.__pwd = pwd
        self.__db = db
        self.__schema = schema
        self.__importedTables = []
        self.__log = logging.getLogger("app.%s" % self.__class__.__name__)
        
        
    def __str__(self):
        return "{0}:{1}@{2}".format(self.__db, self.__schema, self.__host)
        

    def __getCursor(self):
        if not self.__connection:
            self.__connection = psycopg2.connect(
                   "host='{host}' dbname='{db}' user='{user}' password='{pwd}'"
                   .format(host=self.__host, db=self.__db, user=self.__user,
                           pwd=self.__pwd))
            
        cur = self.__connection.cursor()
        if self.__schema:
            cur.execute("SET search_path = {0}".format(self.__schema))

        cur.itersize = 10000
    
        return cur
    
    
    def __initializeTable(self, tableName, columnNames, columnTypes, overwrite=True):
        if tableName not in self.__importedTables:
            tableExists = False
            if self.hasTable(tableName):
                if overwrite:
                    self.execute("DROP TABLE {}".format(tableName))
                else:
                    tableExists = True

            if not tableExists:
                colDefs = ",".join([
                        "{} {}".format(colName, PostgresDatabase.pyToSqlTypes[colType])
                        for colName, colType in zip(columnNames, columnTypes)])
                
                createTableSql = "CREATE TABLE {} ({})".format(tableName, colDefs)
                self.execute(createTableSql)
                
            self.__importedTables.append(tableName)
            
            
    class __FileProtocolWrapper(object):
        
        def __init__(self, rows, title=None):
            self.__rows = rows
            self.__title = title
            
        
        def read(self, size=None):
            return self.readline()
        
        
        def readline(self, size=None):
            try:
                values = []
                if self.__title:
                    values.append(self.__title)
                values.extend(self.__rows.next())
                
                formatted_values = []
                for value in values:
                    if isinstance(value, basestring):
                        formatted_values.append(value.encode("utf-8"))
                    elif value is None or value == int(value):
                        formatted_values.append(value)
                    else:
                        formatted_values.append(round(value, PostgresDatabase.decimalDigits))
                
                row = "{}\n".format("|".join(
                        "{}".format(value) if value is not None else ""
                        for value in formatted_values))
                
                return row
            except StopIteration:
                return ""
            
    
    def close(self):
        '''
        See :meth:`.AbstractDatabase.close'.
        '''
        if self.__connection is not None:
            self.__connection.close()
            self.__connection = None
            
    
    def query(self, sql, params=None):
        '''
        See :meth:`.AbstractDatabase.query'.
        '''
        try:        
            cur = self.__getCursor()
            if params is not None:
                cur.execute(sql, params)
            else:
                cur.execute(sql)
        except psycopg2.ProgrammingError as e:
            raise QueryError(e)
            
        return PostgresDatabaseCursor(self.__connection, cur, cur.description)
    
        
    def execute(self, sql, params=None):
        ''' 
        See :meth:`.AbstractDatabase.execute'.
        '''
        try:        
            cur = self.__getCursor()
            if params is not None:
                cur.execute(sql, params)
            else:
                cur.execute(sql)
        except psycopg2.ProgrammingError as e:
            raise QueryError(e)
        
        self.__connection.commit()
        
        return cur.rowcount
    

    def executeMany(self, sql, params):
        ''' 
        Executes an SQL statement once per set of parameters.
        
        :param sql: SQL insert/update/delete statement to repeat
        :type sql: str
        :param params: SQL parameter lists
        :type params: list of lists
        '''
        try:
            cur = self.__getCursor()
            cur.executemany(sql, params)
        except psycopg2.ProgrammingError as e:
            raise QueryError(e)
        
        self.__connection.commit()
        
    
    def hasTable(self, tableName):
        '''
        Checks if a table exists in the database.

        :param name: table name to find
        :type name: str
        :returns: True if found, False if not
        :rtype: boolean
        '''
        try:
            with self.__getCursor() as cur:
                cur.execute("SELECT * FROM information_schema.tables "
                            "WHERE table_name LIKE '{}'".format(tableName))
                return bool(cur.rowcount)
        except psycopg2.ProgrammingError as e:
            raise QueryError(e)


    def hasSchema(self, schemaName):
        '''
        Checks if a schema exists in the database.

        :param name: table name to find
        :type name: str
        :returns: True if found, False if not
        :rtype: boolean
        '''
        try:
            with self.__getCursor() as cur:
                cur.execute("SELECT * FROM information_schema.schemata "
                            "WHERE schema_name ILIKE '{}'".format(schemaName))
                return bool(cur.rowcount)
        except psycopg2.ProgrammingError as e:
            raise QueryError(e)


    def importData(self, dataImport):
        '''
        Imports data into the database.
        
        :param dataImport: the DataImport to store data from
        :type dataImport: `.DataImport`
        '''
        tableName = dataImport.getDestination()
        titleColumn = dataImport.getTitleColumn()

        columnNames = list(dataImport.getColumns())
        if not columnNames:
            raise DataImportError(
                    "Error processing data import '{0}': No column names "
                    "specified. Either configure the column names explicitly or "
                    "ensure that the input data contains a header row.".format(
                            dataImport.getName()))
        
        if titleColumn:
            columnNames.insert(0, titleColumn)
        
        columnTypes = dataImport.getTypes()
        if titleColumn:
            columnTypes.insert(0, "str")

        self.__initializeTable(tableName, columnNames, columnTypes,
                               dataImport.overwrite())

        with self.__getCursor() as cur:
            cur.copy_from(file=self.__FileProtocolWrapper(
                                  dataImport.getRows(),
                                  title=dataImport.getName() if titleColumn else None),
                          table=tableName,
                          sep="|",
                          columns=columnNames,
                          null="")

        self.__connection.commit()
