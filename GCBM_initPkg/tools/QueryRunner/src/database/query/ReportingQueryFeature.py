# QueryRunner
from AbstractQueryFeature import AbstractQueryFeature
from UnsupportedQueryFeatureError import UnsupportedQueryFeatureError

class ReportingQueryFeature(AbstractQueryFeature):
    '''
    Enables reporting for a query: takes a regular SELECT query and appends the
    output to a table in another database. If the table does not exist, it will
    be created.
    
    :param connectionManager: connection manager service
    :type connectionManager: :class:`.ConnectionManager`
    :param outputDBPath: path to the output database
    :type outputDBPath: str
    :param outputTable: table to append query results to
    :type outputTable: str
    '''
    
    def __init__(self, connectionManager, outputDBPath, outputTable,
                 db_title_column=None):
        self.__connectionManager = connectionManager
        self.__outputDBPath = outputDBPath
        self.__outputTable = outputTable
        self.__db_title_column = db_title_column
        self.__pendingNewTables = []
        
    
    def prepareQuery(self, sql, featureProvider=None):
        if not featureProvider:
            raise UnsupportedQueryFeatureError(self)
        
        if self.__tableExistsOrCreatePending():
            sql = self.__buildInsertQuery(sql)
        else:
            sql = self.__buildCreateTableQuery(sql)
            self.__pendingNewTables.append(self.__outputTable)
            
        if self.__db_title_column:
            dbTitle = featureProvider.getDBTitle()
            sql = self.__includeTitleField(sql, dbTitle)
        
        return sql


    def __tableExistsOrCreatePending(self):
        if self.__outputTable in self.__pendingNewTables:
            return True
        
        outputDB = self.__connectionManager.open(path=self.__outputDBPath)
        if outputDB.hasTable(self.__outputTable):
            return True
        
        return False


    def __buildCreateTableQuery(self, sql):
        '''
        Transforms a regular SELECT query written against a single database
        into a table creation query that inserts the results into a new table
        in the output database.
        '''
        intoClause = "INTO %(table)s IN '%(dbPath)s'" % {
            "table"  : self.__outputTable,
            "dbPath" : self.__outputDBPath}
        
        # 1) Find first SELECT.
        # 2) Find next SELECT or FROM.
        # 3) If the next clause is FROM, or there is no next SELECT,
        #    that's where to put the intoClause.
        # 4) If the next clause is SELECT, keep finding SELECT/FROM pairs
        #    until the next item is a FROM.
        firstSelectClauseIndex = sql.upper().find("SELECT")
        nextSelectClauseIndex = sql.upper().find(
                "SELECT", firstSelectClauseIndex + len("SELECT"))
        nextFromClauseIndex = sql.upper().find("FROM")

        while nextSelectClauseIndex > -1 \
        and nextSelectClauseIndex <= nextFromClauseIndex:
            nextSelectClauseIndex = sql.upper().find(
                    "SELECT", nextSelectClauseIndex + len("SELECT"))
            nextFromClauseIndex = sql.upper().find(
                    "FROM", nextFromClauseIndex + len("FROM"))
            
        createTableSQL = "\n".join((sql[0:nextFromClauseIndex],
                                    intoClause,
                                    sql[nextFromClauseIndex:]))
        return createTableSQL


    def __buildInsertQuery(self, sql):
        '''
        Transforms a regular SELECT query written against a single database into
        a query that inserts the results into an existing table in the output
        database.
        '''
        intoClause = "INSERT INTO %(table)s IN '%(dbPath)s'" % {
            "table"  : self.__outputTable,
            "dbPath" : self.__outputDBPath}
        
        insertSQL = "\n".join((intoClause, sql))

        return insertSQL


    def __includeTitleField(self, sql, title):
        '''
        Includes the title of the current database in the query results which
        are appended to the reporting table.
        '''
        extraSelectField = "    '%s' AS %s, " % (title, self.__db_title_column)
        selectClauseIndex = sql.upper().index("SELECT")
        afterSelect = selectClauseIndex + len("SELECT")
        sqlWithTitleField = "\n".join((sql[0:afterSelect],
                                       extraSelectField,
                                       sql[afterSelect:]))
        return sqlWithTitleField
