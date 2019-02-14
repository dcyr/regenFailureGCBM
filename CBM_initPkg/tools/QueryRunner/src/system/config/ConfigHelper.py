# core
import os
from contextlib import contextmanager

# QueryRunner
from system.config.ConfigError import ConfigError

# contrib
from configobj import ConfigObj
from validate import Validator

class ConfigHelper(object):
    '''
    Helper class for reading from a hierarchical set of configuration files in
    ConfigObj library .ini format. Using the `readConfig` context manager, it is
    possible to traverse configuration files which reference each other through
    relative or absolute paths.
    
    This class is not thread-safe, as it maintains a list of the paths it has
    visited.
    
    :param rootConfigFilePath: relative or absolute path to the root
        configuration file in the hierarchy, which is parsed immediately. This
        file should contain the [DEFAULT] section, if used.
    :type rootConfigFilePath: str
    :param userArgs: optional dictionary of user-supplied variables for template
        substitution - for example, if a config file references a variable
        $var1, userArgs could pass in {"arg1": "foo"} to externally supply the
        substitution.
    :type userArgs: dict
    '''
    
    def __init__(self, rootConfigFilePath, userArgs=None):
        self.__pathStack = []
        self.__pathStack.append(os.path.abspath(os.path.dirname(rootConfigFilePath)))
        self.__configObj = ConfigObj(rootConfigFilePath, interpolation="Template")
        if userArgs:
            self.__configObj["DEFAULT"].merge(userArgs)
    
    
    @contextmanager
    def readConfig(self, configFilePath, configSpec=None):
        '''
        Parses a .ini file at a given path, either absolute or relative to this
        helper class' current working directory. The given path becomes the
        helper class' current working directory while this context manager is in
        use.
        
        :param configFilePath: relative or absolute path to a .ini file to parse
        :type configFilePath: str
        :param configSpec: optional path to configspec file, which must be in
            the same directory as the config file
        :type configSpec: str
        :returns: this :class:`.ConfigHelper` instance
        :rtype: :class:`.ConfigHelper`
        '''
        path, filename = os.path.split(configFilePath)
        self.__pathStack.append(path)
        fullConfigFilePath = os.path.join(self.getCurrentPath(), filename)
        if not os.path.exists(fullConfigFilePath):
            raise ConfigError("File not found: {0}".format(fullConfigFilePath))
        
        # Optionally includes a configspec file for ConfigObj Validator, used
        # for converting config values to correct types.
        fullConfigSpecPath = None
        if configSpec:
            fullConfigSpecPath = os.path.join(self.getCurrentPath(), configSpec)
            if not os.path.exists(fullConfigSpecPath):
                raise ConfigError("Config-spec file for {0} not found at {1}".format(
                    fullConfigFilePath, fullConfigSpecPath))
        
        cfg = ConfigObj(fullConfigFilePath,
                        interpolation="Template",
                        configspec=fullConfigSpecPath)
        
        if configSpec:
            validator = Validator()
            cfg.validate(validator)
        
        # Merges defaults for string interpolation.
        cfg.merge(self.__configObj["DEFAULT"])
        
        # Merges the newly-read configuration file into the main configuration.
        self.__configObj.merge(cfg)
        
        try:
            yield self
        finally:
            self.__pathStack.pop()
            
    
    def readFile(self, path, lineFilter=None):
        '''
        Reads the contents of a file at a given path, which can be either
        absolute or relative to this helper class' current working directory.
        
        :param path: absolute or relative path to the file to read
        :type path: str
        :param lineFilter: a filter function that takes a string (a line from
            the file) and returns a modified string or None/empty string if the
            whole line should be skipped.
        :type lineFilter: function
        :returns: the contents of the file
        :rtype: str
        '''
        fullPath = self.getAbsolutePath(path)
        with open(fullPath) as fp:
            if lineFilter:
                contents = "".join((lineFilter(line)
                                    for line in fp.readlines()
                                    if lineFilter(line)
                                    and not lineFilter(line).isspace()))
            else:
                contents = fp.read()
        
        return contents
    
    
    def getAbsolutePath(self, path):
        '''
        :returns: the absolute path to a file referenced by the current config
            section; that is, if a path is specified in a configuration file as
            relative to the config file location, this returns the absolute path
            to the file
        :rtype: str
        '''
        return os.path.abspath(os.path.join(self.getCurrentPath(), path))
    
    
    def getCurrentPath(self):
        '''
        :returns: the current working directory of this :class:`.ConfigHelper`
            instance
        :rtype: str
        '''
        return os.path.join(*self.__pathStack)

    
    def getConfig(self):
        '''
        :returns: the underlying :class:`.ConfigObj` containing the
            configuration data read so far
        :rtype: :class:`.ConfigObj`
        '''
        return self.__configObj
    