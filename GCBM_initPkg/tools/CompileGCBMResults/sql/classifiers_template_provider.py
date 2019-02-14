def getStrings(db):
	classifiers = getClassifiers(db)
	stringSubs = {
        "classifiers": ", ".join(classifiers),
        "ddl_classifiers": ", ".join(("{} VARCHAR".format(c) for c in classifiers)),
        "select_classifiers": ", ".join(("a.{}".format(c) for c in classifiers)),
        "join_classifiers": " AND ".join((
            "COALESCE(a.{0}, 'null') = COALESCE(s.{0}, 'null')".format(c)
            for c in classifiers))
    }
	
	return stringSubs

	
def getClassifiers(db):
	sql = "SELECT * FROM classifiersetdimension LIMIT 1"
	results = db.query(sql)
	return [col for col in results.getColumns() if col not in ("id")]
