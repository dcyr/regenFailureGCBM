# QueryRunner
from AbstractQueryConfigurer import AbstractQueryConfigurer
from database.query.TemplatedQueryFeature import TemplatedQueryFeature
from system.config.ConfigError import ConfigError

# core
import os
import imp

class TemplatedQueryConfigurer(AbstractQueryConfigurer):
    
    def configure(self, query, featureConfig):
        templateProvider = None
        templateProviderModule = featureConfig.get("template_provider")
        templateProviderModuleRealPath = os.path.join(
                self.getConfigHelper().getCurrentPath(),
                templateProviderModule)
        
        if not os.path.exists(templateProviderModuleRealPath):
            raise ConfigError("Template provider not found: {}".format(
                    templateProviderModuleRealPath))
        
        if templateProviderModule:
            templateProvider = imp.load_source(templateProviderModule,
                                               templateProviderModuleRealPath)
            
        feature = TemplatedQueryFeature(templateProvider)
        query.addFeature(feature)
