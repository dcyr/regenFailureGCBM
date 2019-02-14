# contrib
from springpython.config import PythonConfig
from springpython.config import Object
from springpython.aop import RegexpMethodPointcutAdvisor

# QueryRunner
from Config import Config
from aop.QueryInterceptor import QueryInterceptor
from database.ConnectionFactory import ConnectionFactory
from domain.AccessQueryRunnerDatabase import AccessQueryRunnerDatabase
from domain.SQLiteQueryRunnerDatabase import SQLiteQueryRunnerDatabase
from domain.PostgresQueryRunnerDatabase import PostgresQueryRunnerDatabase
from system.System import System
from system.config.ConfigHelper import ConfigHelper
from system.config.QueryFactory import QueryFactory
from system.config.TemplatedQueryConfigurer import TemplatedQueryConfigurer
from system.config.MultiNamedParametersQueryConfigurer import MultiNamedParametersQueryConfigurer
from system.config.NamedParametersQueryConfigurer import NamedParametersQueryConfigurer
from system.config.DatabaseNamedParametersQueryConfigurer import DatabaseNamedParametersQueryConfigurer
from system.config.ReportingQueryConfigurer import ReportingQueryConfigurer
from system.service.ConnectionManager import ConnectionManager
from system.service.DatabaseService import DatabaseService
from system.task.PreprocessorTask import PreprocessorTask
from system.task.QueryRunnerTask import QueryRunnerTask
from system.task.DataImporterTask import DataImporterTask
from system.config.DataImportFactory import DataImportFactory

class ApplicationContext(PythonConfig):
    
    def __init__(self, rootConfigFilePath, userArgs=None):
        super(ApplicationContext, self).__init__()
        self.__rootConfigFilePath = rootConfigFilePath
        self.__userArgs = userArgs
    
    @Object(lazy_init=True)
    def configHelper(self):
        return ConfigHelper(self.__rootConfigFilePath, self.__userArgs)

    @Object(lazy_init=True)
    def loggingConfig(self):
        configHelper = self.configHelper()
        cfg = configHelper.getConfig()
        loggingConfigPath = cfg["DEFAULT"]["logging_config"]
        with configHelper.readConfig(loggingConfigPath, "logging.configspec"):
            loggingSection = configHelper.getConfig()["LOGGING"]
        
        # Handlers can contain file paths which use ConfigObj's string
        # interpolation, but ConfigObj Sections do not behave exactly like
        # dicts, which causes :meth:`logging.dictConfig` to extract the
        # uninterpolated strings - so the call to dict() is required in order to
        # do the interpolation ahead of time.
        return loggingSection.dict()

    @Object(lazy_init=True)
    def config(self):
        cfg = self.configHelper().getConfig()
        appConfig = cfg["DEFAULT"]
        
        outputPath = appConfig["output_path"]
        logPath    = appConfig["log_path"]
        logQueries = appConfig.as_bool("log_queries")
        overwrite  = appConfig.as_bool("overwrite_working_dbs")

        activeDBs = []
        for dbTitle, dbInfo in cfg["databases"].iteritems():
            if dbInfo.as_bool("enabled"):
                workingPath = dbInfo.get("working_db_path")
                if workingPath:
                    if workingPath.endswith(".db"):
                        db = SQLiteQueryRunnerDatabase(
                                title=dbTitle,
                                workingDBPath=workingPath,
                                originalDBPath=dbInfo.get("original_db_path"))
                    else:
                        db = AccessQueryRunnerDatabase(
                                dbService=self.databaseService(),
                                title=dbTitle,
                                workingDBPath=dbInfo["working_db_path"],
                                originalDBPath=dbInfo.get("original_db_path"))
                else:
                    db = PostgresQueryRunnerDatabase(
                            title=dbTitle,
                            host=dbInfo["host"],
                            db=dbInfo["db"],
                            user=dbInfo["user"],
                            pwd=dbInfo["pwd"],
                            schema=dbInfo.get("schema"))
                
                activeDBs.append(db)
            
        return Config(outputPath=outputPath,
                      logPath=logPath,
                      logQueries=logQueries,
                      activeDBs=activeDBs,
                      overwrite=overwrite)
    
    @Object(lazy_init=True)
    def system(self):
        system = System()
        system.setConfig(self.config())
        system.setConnectionManager(self.connectionManager())
        system.setDatabaseService(self.databaseService())

        return system
    
    @Object(lazy_init=True)
    def connectionFactory(self):
        pointcutAdvisor = RegexpMethodPointcutAdvisor(
                advice=[QueryInterceptor(self.config().isLoggingEnabled())],
                patterns=[".*query.*",
                          ".*execute.*"])
        
        return ConnectionFactory(pointcutAdvisor)
   
    @Object(lazy_init=True)
    def connectionManager(self):
        return ConnectionManager(self.connectionFactory())
    
    @Object(lazy_init=True)
    def databaseService(self):
        return DatabaseService()

    @Object(lazy_init=True)
    def preprocessor(self):
        return PreprocessorTask(system=self.system())

    @Object(lazy_init=True)
    def queryRunner(self):
        cfg = self.configHelper().getConfig()
        taskConfig = cfg["queries"]
        queries = self.queryFactory().createQueriesFromConfig(taskConfig)
            
        return QueryRunnerTask(system=self.system(), queries=queries)
    
    @Object(lazy_init=True)
    def dataImporter(self):
        cfg = self.configHelper().getConfig()
        taskConfig = cfg.get("data_imports")
        if not taskConfig:
            return None
        
        dataImports = self.dataImportFactory().createDataImportsFromConfig(taskConfig)
        
        return DataImporterTask(system=self.system(), dataImports=dataImports)
    
    @Object(lazy_init=True)
    def templatedQueryConfigurer(self):
        return TemplatedQueryConfigurer(system=self.system(),
                                        configHelper=self.configHelper())
    
    @Object(lazy_init=True)
    def multiNamedParametersQueryConfigurer(self):
        return MultiNamedParametersQueryConfigurer(system=self.system(),
                                                   configHelper=self.configHelper())
    
    @Object(lazy_init=True)
    def namedParametersQueryConfigurer(self):
        return NamedParametersQueryConfigurer(system=self.system(),
                                              configHelper=self.configHelper())
    
    @Object(lazy_init=True)
    def databaseNamedParametersQueryConfigurer(self):
        return DatabaseNamedParametersQueryConfigurer(system=self.system(),
                                                      configHelper=self.configHelper())
    
    @Object(lazy_init=True)
    def reportingQueryConfigurer(self):
        cfg = self.configHelper().getConfig()
        appConfig = cfg["DEFAULT"]
        
        overwrite = appConfig.as_bool("overwrite_reporting_tables")
        
        return ReportingQueryConfigurer(system=self.system(),
                                        configHelper=self.configHelper(),
                                        overwrite=overwrite)
    
    @Object(lazy_init=True)
    def dataImportFactory(self):
        return DataImportFactory(self.system(), self.configHelper())
    
    @Object(lazy_init=True)
    def queryFactory(self):
        queryConfigurers = {
            "templated": self.templatedQueryConfigurer(),
            "multi_named_parameters": self.multiNamedParametersQueryConfigurer(),
            "named_parameters": self.namedParametersQueryConfigurer(),
            "database_named_parameters": self.databaseNamedParametersQueryConfigurer(),
            "reporting": self.reportingQueryConfigurer()
        }
        
        return QueryFactory(self.system(), queryConfigurers, self.configHelper())
    
    @Object(lazy_init=True)
    def tasks(self):
        tasks = []
        tasks.append(self.preprocessor())
        dataImporterTask = self.dataImporter()
        if dataImporterTask:
            tasks.append(dataImporterTask)
        tasks.append(self.queryRunner())
        
        return tasks
    