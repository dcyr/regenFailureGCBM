class CellRange(object):
    '''
    Represents a range of cells in an Excel spreadsheet. Provides methods to
    translate the range into xlrd row/column indexes which can be used to get
    slices of a worksheet.
    
    :param startCell: the top-left cell in the range
    :type startCell: :class:`.Cell`
    :param endCell: the bottom-right cell in the range
    :type endCell: :class:`.Cell`
    '''
    
    def __init__(self, startCell, endCell=None):
        self.__startCell = startCell
        self.__endCell = endCell
        
    
    def getStartCell(self):
        '''
        :returns: the top-left cell in the range
        :rtype: :class:`.Cell`
        '''
        return self.__startCell
    
    
    def getEndCell(self):
        '''
        :returns: the bottom-right cell in the range
        :rtype: :class:`.Cell`
        '''
        return self.__endCell


    def getFirstRowIndex(self):
        '''
        :returns: the zero-based index of the first row in the range
        :rtype: int
        '''
        return self.__startCell.getRowIndex()
    
    
    def getLastRowIndex(self):
        '''
        :returns: one higher than the zero-based index of the last row in the
            range (since xlrd reads up to, but not including, the last row
            index)
        :rtype: int
        '''
        if not self.__endCell:
            return None
       
        rowIndex = self.__endCell.getRowIndex()
        return rowIndex + 1 if rowIndex else None
    
    
    def getFirstColIndex(self):
        '''
        :returns: the zero-based index of the first column in the range
        :rtype: int
        '''
        return self.__startCell.getColIndex()
    
    
    def getLastColIndex(self):
        '''
        :returns: one higher than the zero-based index of the last column in the
            range (since xlrd reads up to, but not including, the last column
            index)
        :rtype: int
        '''
        if not self.__endCell:
            return None
        
        return self.__endCell.getColIndex() + 1
