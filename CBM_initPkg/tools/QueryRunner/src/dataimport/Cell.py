# core
import string
import re

# contrib
import xlrd

class Cell(object):
    '''
    Represents a cell in an Excel worksheet. Translates excel row/column labels
    into zero-based row/column indexes compatible with xlrd.
    
    :param row: the 1-based row of the cell (as seen from MS Excel)
    :type row: int
    :param col: the alphabetical column of the cell (as seen from MS Excel)
    :type col: str
    '''
    
    def __init__(self, row, col):
        self.__row = row
        self.__col = col
        
    
    def __str__(self):
        return "{0}{1}".format(self.__col, self.__row)


    @classmethod
    def FromIndices(cls, rowIndex, colIndex):
        '''
        Creates a :class:`.Cell` object from a pair of 0-indexed xlrd indices.
        
        :rtype: :class:`.Cell`
        '''
        row = rowIndex + 1
        col = xlrd.colname(colIndex)
        return cls(row, col)

    
    @classmethod
    def FromString(cls, string):
        '''
        Creates a :class:`.Cell` object from a string, i.e. "A10".
        
        :rtype: :class:`.Cell`
        '''
        matches = re.findall("([a-zA-Z]*)([0-9]*)", string)
        col, row = matches[0]
        
        if not row:
            return cls(None, col)
        
        return cls(int(row), col)
    

    def getRow(self):
        '''
        :returns: the 1-based row of the cell (as seen from MS Excel)
        :rtype: int
        '''
        return self.__row
    
    
    def getColumn(self):
        '''
        :returns: the alphabetical column of the cell (as seen from MS Excel)
        :rtype: str
        '''
        return self.__col
    
    
    def getRowIndex(self):
        '''
        :returns: the zero-based row index of the cell, compatible with xlrd
        :rtype: int
        '''
        return self.__row - 1 if self.__row else 0

    
    def getColIndex(self):
        '''
        :returns: the zero-based column index of the cell, compatible with xlrd
        :rtype: int
        '''
        index = -1

        for pos, char in enumerate(self.__col[::-1]):
            # A = 1 .. Z = 26
            alphaValue = string.ascii_uppercase.index(char) + 1
            index += len(string.ascii_uppercase) ** pos * alphaValue
        
        return index
    