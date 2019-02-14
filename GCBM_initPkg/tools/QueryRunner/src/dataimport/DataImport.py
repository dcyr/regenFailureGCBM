class DataImport(object):
    '''
    Base class for data import tasks which are responsible for reading rows from
    a specific type of file for importing into a database.
    '''
    
    def getName(self):
        '''
        :returns: the name of the data import
        :rtype: str
        '''
        raise NotImplementedError()
    
    
    def getDestination(self):
        '''
        :returns: the name of the table to import data into
        :rtype: str
        '''
        raise NotImplementedError()
    
    
    def overwrite(self):
        '''
        :returns: True if the destination table should be overwritten, False if
            it should be appended to
        :rtype: boolean
        '''
        raise NotImplementedError()
    
    
    def getTitleColumn(self):
        '''
        :returns: the name of the identifier column in the destination table,
            which holds the name of the data import returned by :meth:`getName`
        :rtype: str
        '''
        raise NotImplementedError()
    
    
    def getColumns(self):
        '''
        :returns: a list of the names of the columns in the import data in the
            same order returned by :meth:`getRows` and :meth:`getTypes`
        :rtype: list of str
        '''
        raise NotImplementedError()
    
    
    def getRows(self):
        '''
        :returns: an iterator for the data rows contained in the input file,
            with columns in the same order returned by :meth:`getColumns` and
            :meth:`getTypes`
        :rtype: iterator of lists
        '''
        raise NotImplementedError()


    def getTypes(self):
        '''
        :returns: a list of the python types of the columns in the import data
            in the same order returned by :meth:`getRows` and :meth:`getColumns`
        :rtype: list of str
        '''
        raise NotImplementedError()
