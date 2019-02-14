# core
from string import Template

class SQLTemplate(Template):
    '''
    Overrides the standard string Template's usual ``$`` delimiter with ``:``
    for formatting regular-looking named parameter queries.
    '''
    
    delimiter = ":"
