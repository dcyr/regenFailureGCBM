'''
Application entry point.
'''

# core
import logging.config
import argparse
import os
import sys

# contrib
import springpython.context

# QueryRunner
from ApplicationContext import ApplicationContext
from database.query.QueryError import QueryError
from dataimport.DataImportError import DataImportError
from system.config.ConfigError import ConfigError

system = None
log = None

def _captureUserArgsToDict(args):
    '''
    Given a list of args: [--foo bar --baz fizzle], converts them into a
    dictionary suitable for use with ConfigObj: {"foo": "bar", "baz": "fizzle"}
    '''
    userArgs = None
    if len(args) > 1:
        # Captures any user-supplied variable values to pass to config files.
        rawUserArgs = args[1]
        argPairs = zip(rawUserArgs[::2], rawUserArgs[1::2])
        userArgs = dict((k.replace("--", ""), v) for k, v in argPairs)
    
    return userArgs


def _exitWithError(message):
    if log:
        log.error(message)
    else:
        print message
        
    if system:
        system.shutdown()
    
    sys.exit()


if __name__ == "__main__":
    # Allows the user to provide the path to the main configuration file.
    parser = argparse.ArgumentParser(description="Process QueryRunner.")
    parser.add_argument("--config", type=str, required=False,
                        help="path to the script's configuration file",
                        default=r"..\examples\config.ini")
    allArgs = parser.parse_known_args()
    args = allArgs[0]
    userArgs = _captureUserArgsToDict(allArgs)
    
    if not os.path.exists(args.config):
        sys.exit("File not found trying to load configuration: %s"
                 % os.path.realpath(args.config))
    
    # Initializes the springpython container using the configuration file
    # provided by the user.
    try:
        applicationContext = springpython.context.ApplicationContext(
                ApplicationContext(args.config, userArgs))
    
        system = applicationContext.get_object("system")
        
        # Creates the log directory, if it doesn't exist.
        logPath = os.path.realpath(system.getConfig().getLogPath())
        if not os.path.exists(logPath):
            os.makedirs(logPath)
        
        loggingConfig = applicationContext.get_object("loggingConfig")
        logging.config.dictConfig(loggingConfig)
    
        log = logging.getLogger("app.QueryRunner")
        log.info("QueryRunner Configuration")
        log.info(system.getConfig())
        log.info("Running.")
        
        tasks = applicationContext.get_object("tasks")
        for task in tasks:
            task.execute()
            
        log.info("Completed successfully.")

    except ConfigError as e:
        _exitWithError("Error configuring QueryRunner:\n{0}".format(e))
    except QueryError as e:
        _exitWithError("Processing failed - Query error:\n{0}".format(e))
    except DataImportError as e:
        _exitWithError("Processing failed - Data import error:\n{0}".format(e))
    except Exception as e:
        _exitWithError("QueryRunner encountered an error!\n{0}".format(e))
            
    finally:
        if system:
            system.shutdown()
