# core
import os
import csv

# QueryRunner
from AbstractOutputHandler import AbstractOutputHandler

class CsvOutputHandler(AbstractOutputHandler):
    '''
    Writes query output to a delimited text file.
    
    :param outputPath: the file to write to; if it doesn't exist, it will be
        created
    :type outputPath: str
    :param header: optional - output a header row with the column names
    :type header: boolean
    '''
    
    def __init__(self, outputPath, delimiter=",", header=False, rotate=False):
        self.__outputPath = outputPath
        self.__delimiter = delimiter
        self.__header = header
        self.__rotate = rotate
        self.__rotation = 1


    def __writeNew(self, outPath, output):
        with open(outPath, "wb") as fh:
            writer = csv.writer(fh, delimiter=self.__delimiter)
            if self.__header:
                writer.writerow(output.getColumns())
            
            writer.writerows(output)

        
    def __writeExisting(self, outPath, output):
        with open(outPath, "ab") as fh:
            writer = csv.writer(fh, delimiter=self.__delimiter)
            writer.writerows(output)

    
    def handle(self, dbTitle, output):
        '''
        See :meth:`.AbstractOutputHandler.handle`.
        '''
        if not output.getColumns():
            return
        
        outPath = self.__outputPath
        if self.__rotate:
            fileName, ext = os.path.splitext(outPath)
            outPath = "{}_{}{}".format(fileName, self.__rotation, ext)
            self.__rotation += 1
            
        if os.path.exists(outPath):
            self.__writeExisting(outPath, output)
        else:
            self.__writeNew(outPath, output)
