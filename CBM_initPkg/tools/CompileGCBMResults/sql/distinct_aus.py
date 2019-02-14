def getStrings(db):
    aus = getAUs(db)
    stringSubs = [{"au": au} for au in aus]
    
    return stringSubs

    
def getAUs(db):
    sql = "SELECT DISTINCT analysis_unit FROM classifiersetdimension"
    results = db.query(sql)
    return [row[0] for row in results]
