# QueryRunner
from AbstractOutputHandler import AbstractOutputHandler

class MdbOutputHandler(AbstractOutputHandler):
    '''
    Writes query output to an Access database.
    
    :param connectionManager: connection manager service
    :type connectionManager: :class:`.ConnectionManager`
    :param outputDBPath: path to the output database
    :type outputDBPath: str
    :param outputTable: table to append query results to
    :type outputTable: str
    '''

    pyToSqlTypes = {"unicode"        : "VARCHAR",
                    "float"          : "FLOAT",
                    "int"            : "INTEGER",
                    "str"            : "VARCHAR",
                    "bool"           : "YESNO",
                    "memo"           : "MEMO",
                    "decimal.Decimal": "FLOAT"}
    
        
    def __init__(self, connectionManager, outputDBPath, outputTable,
                 dbTitleColumn=None):
        self.__connectionManager = connectionManager
        self.__outputDBPath = outputDBPath
        self.__outputTable = outputTable
        self.__dbTitleColumn = dbTitleColumn


    def handle(self, dbTitle, output):
        '''
        See :meth:`.AbstractOutputHandler.handle`.
        '''
        db = self.__connectionManager.open(path=self.__outputDBPath)
            
        # Gets each column's name.
        fields = ['"{0}"'.format(field) for field in output.getColumns()]
        if self.__dbTitleColumn:
            fields.insert(0, '"{0}"'.format(self.__dbTitleColumn))
                
        if not db.hasTable(self.__outputTable):
            # Gets each column's data type.
            types = list(output.getTypes())
            if self.__dbTitleColumn:
                types.insert(0, "str")
                
            # Creates a comma-separated list of "<column name> <data type>".
            fieldDef = ",".join((" ".join((f[0], MdbOutputHandler.pyToSqlTypes[f[1]]))
                                 for f in zip(fields, types)))
            
            sql = "CREATE TABLE {0} ({1})".format(self.__outputTable, fieldDef)
            db.execute(sql)
        
        # Populates the table.
        sql = "INSERT INTO {0} ({1}) VALUES ({2})".format(
                self.__outputTable, ",".join(fields), ",".join("?" * len(fields)))
        
        batch = []
        for i, row in enumerate(output):
            if self.__dbTitleColumn:
                row.insert(0, dbTitle)
                
            batch.append(row)
            if i % 10000 == 0:
                if batch:
                    db.executeMany(sql, batch)
                    batch = []

        if batch:
            db.executeMany(sql, batch)
