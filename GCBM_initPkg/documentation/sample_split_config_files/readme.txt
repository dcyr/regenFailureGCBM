run configuration files can be passed into the call arguments in following ways:

1) same as the original way
	--config, --config_provider
	
2) from external config files, in which the configuration files are listed
	--config_file, --provider_file
	
	see examples of test.cfg and test_data.cfg
		
3) mixed arguments
	--config, --config_provider, --config_file, --provider_file