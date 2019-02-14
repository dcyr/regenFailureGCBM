# core
import os

# contrib
import xlrd

# QueryRunner
from DataImport import DataImport
from DataImportError import DataImportError
from Cell import Cell
from CellRange import CellRange

class XLSDataImport(DataImport):
    '''
    Reads an Excel spreadsheet for import into a database table.
    
    :param name: the name of the destination table
    :type name: str
    :param path: the absolute path to the Excel spreadsheet to import
    :type path: str
    :param destination: the name of the table to import data into
    :type destination: str
    :param worksheet: the name of the worksheet to import data from (defaults
        to the first worksheet)
    :type worksheet: str
    :param cellRange: the range of cells to import into a table (attempts to
        detect a usable range of values if not provided)
    :type cellRange: :class:`.CellRange`
    :param columns: optional parameter which names the columns in the selected
        cell range - leave this out if the range already contains a header row
        with column names
    :type columns: list
    :param types: optional - specifies the python type of each column in the
        range of cells to import
    :type types: list
    :param trimWhitespace: optional - specifies whether or not to strip
        whitespace from cell values (default: True)
    :type trimWhitespace: boolean
    :param nullValues: values that should be inserted into the database as null
    :type nullValues: list
    :param dbNull: value that represents null in the database (defaults to the
        native database null type)
    :type dbNull: object
    :param titleColumn: the name of the identifier column if multiple data
        imports are being stored in the same table
    :type titleColumn: str
    :param overwrite: overwrite the destination table if it exists (default: True)
    :type overwrite: boolean
    '''
        
    xlrdIndexedTypes = [
        "unicode", # 0, XL_CELL_EMPTY
        "unicode", # 1, XL_CELL_TEXT
        "float",   # 2, XL_CELL_NUMBER
        "float",   # 3, XL_CELL_DATE
        "int",     # 4, XL_CELL_BOOLEAN (0=FALSE, 1=TRUE)
        "int",     # 5, XL_CELL_ERROR
        "unicode"  # 6, XL_CELL_BLANK
    ]
    
    
    def __init__(self, name, path, destination, worksheet=None,
                 cellRange=None, columns=None, types=None, trimWhitespace=True,
                 nullValues=None, dbNull=None, titleColumn=None,
                 overwrite=True):
        self.__name = name
        self.__destination = destination
        self.__overwrite = overwrite
        self.__trimWhitespace = trimWhitespace
        self.__nullValues = nullValues or []
        self.__dbNull = dbNull
        self.__titleColumn = titleColumn
        self.__columns = columns
        self.__types = types
        self.__useFirstRowAsHeader = columns is None
        
        if not os.path.exists(path):
            raise IOError("File not found: {0}".format(os.path.realpath(path)))

        workbook = xlrd.open_workbook(path)
        sheetNames = workbook.sheet_names()
        if worksheet:
            worksheet = unicode(worksheet)
            if worksheet not in sheetNames:
                raise RuntimeError("Worksheet '{0}' not found.".format(worksheet))
        else:
            worksheet = sheetNames[0]

        self.__ws = workbook.sheet_by_name(worksheet)
        self.__setCellRange(cellRange)

    
    def __setCellRange(self, cellRange):
        if cellRange is None:
            # No user-supplied range - detect start and end cells.
            start = self.__detectRangeStart()
            end = self.__detectRangeEnd(start)
            cellRange = CellRange(start, end)

        if not cellRange.getLastRowIndex():
            # Open-ended range - detect end.
            start = cellRange.getStartCell()
            endColIndex = None
            if cellRange.getEndCell():
                endColIndex = cellRange.getEndCell().getColIndex()
                
            end = self.__detectRangeEnd(start, endColIndex)
            cellRange = CellRange(start, end)
            
        self.__cellRange = cellRange
            
    
    def __detectRangeStart(self):
        '''
        Finds the first range of usable data in the worksheet. This is used
        for cases where the caller hasn't supplied a range to work with.
        '''
        # 1. find the first row where non blank data exists
        # 2. find the first column where non blank data exists
        for row in range(self.__ws.nrows):
            for col in range(self.__ws.ncols):
                if not self.__emptyCell(self.__ws.cell(row, col)):
                    return Cell.FromIndices(row, col)


    def __detectRangeEnd(self, start, endCol=None):
        '''
        Finds the last cell of usable data in the worksheet. This is used
        for cases where the caller has supplied an open-ended start cell to work
        with.
        '''
        firstRow = start.getRowIndex()
        firstCol = start.getColIndex()

        if not endCol:
            # Find the last non-empty column in the first row of data.
            endCol = self.__ws.ncols - 1
            for col in range(firstCol, self.__ws.ncols):
                if self.__emptyCell(self.__ws.cell(firstRow, col)):
                    endCol = col - 1 if col > 0 else 0
                    break

        # Find the last non-empty row in the first column of data.
        endRow = self.__ws.nrows - 1
        for row in range(firstRow, self.__ws.nrows - 1):
            if self.__emptyCell(self.__ws.cell(row, firstCol)):
                endRow = row - 1
                break

        return Cell.FromIndices(endRow, endCol)


    def __toString(self, val):
        if type(val) == unicode:
            return val
       
        return str(val)

    
    def __emptyCell(self, cell):
        '''
        Checks if a cell is empty.
        '''
        val = self.__toString(cell.value)
        return val.isspace() or val == ""
    

    def __transformValue(self, cell_value):
        '''
        Casts an excel cell value to int if excel is storing a number 
        which can be represented as an integer.
        '''
        # Everything in Excel is a string or a float. Cast floats that are
        # actually integers to ints.
        if int(cell_value) == cell_value:
            return int(cell_value)
        
        return cell_value


    def __readRange(self, cellRange):
        firstRow = cellRange.getFirstRowIndex()
        lastRow = cellRange.getLastRowIndex()
        firstCol = cellRange.getFirstColIndex()
        lastCol = cellRange.getLastColIndex()
        
        for row in range(firstRow, lastRow):
            rowValues = []
            for col in range(firstCol, lastCol):
                value = self.__ws.cell(row, col).value
                if isinstance(value, basestring):
                    if self.__trimWhitespace:
                        value = value.strip()
                    if not value.strip():
                        value = None
                elif self.getTypes()[len(rowValues)] == "int":
                    value = self.__transformValue(value)
                    
                if value is None or value in self.__nullValues:
                    value = self.__dbNull
                
                rowValues.append(value)
            
            yield rowValues


    def getRows(self):
        '''
        See :meth:`.DataImport.getRows`.
        '''
        row = self.__cellRange.getFirstRowIndex()
        if self.__useFirstRowAsHeader:
            row += 1
            
        start = Cell.FromIndices(row, self.__cellRange.getFirstColIndex())
        end = self.__cellRange.getEndCell()
        
        return self.__readRange(CellRange(start, end))


    def getName(self):
        '''
        See :meth:`.DataImport.getName`.
        '''
        return self.__name
    
    
    def getDestination(self):
        '''
        See :meth:`.DataImport.getDestination'.
        '''
        return self.__destination
    
    
    def overwrite(self):
        '''
        See :meth:`.DataImport.overwrite`.
        '''
        return self.__overwrite
        
        
    def getTitleColumn(self):
        '''
        See :meth:`.DataImport.getTitleColumn`.
        '''
        return self.__titleColumn


    def getColumns(self):
        '''
        See :meth:`.DataImport.getColumns`.
        '''
        if not self.__columns:
            # No user-defined columns, so the first row of data defines the
            # column names.
            self.__columns = [str(col) for col in self.__readRange(self.__cellRange).next()]
        
            headerRowIdx = self.__cellRange.getFirstRowIndex()
            headerStartColIdx = self.__cellRange.getFirstColIndex()
            emptyCells = [Cell.FromIndices(headerRowIdx, headerStartColIdx + i)
                          for i, col in enumerate(self.__columns) if col is None]
            if emptyCells:
                errorMsg = "".join((
                    "Found empty cells ({0}) in header row. Fix input data or ",
                    "configure column names explicitly."))
                
                raise DataImportError(errorMsg.format(
                        ", ".join((str(cell) for cell in emptyCells))))
            
        return self.__columns


    def getTypes(self):
        '''
        See :meth:`.DataImport.getTypes`.
        '''
        if not self.__types:
            firstRow = self.__cellRange.getFirstRowIndex()
            if self.__useFirstRowAsHeader:
                firstRow += 1
                
            firstCol = self.__cellRange.getFirstColIndex()
            lastCol = self.__cellRange.getLastColIndex()
            row = self.__ws.row_slice(firstRow, firstCol, lastCol)
           
            self.__types = [XLSDataImport.xlrdIndexedTypes[cell.ctype]
                            for cell in row]
            
        return self.__types
