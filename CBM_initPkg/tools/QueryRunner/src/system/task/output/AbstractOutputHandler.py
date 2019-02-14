class AbstractOutputHandler(object):
    '''
    Base class for output handlers, which capture output from a :class:`.Query`
    and process it in some way - typically to write it out to a file.
    '''
    
    def handle(self, dbTitle, output):
        raise NotImplementedError
