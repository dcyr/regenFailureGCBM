def getStrings(db):
	classifiers = getClassifiers(db)
	
	stringSubs = {
		"classifierSelectCols": ", ".join(
				["qryCSet_CrossTab.[%(classifier)s] AS [cls_%(classifier)s]"
                 % {"classifier": classifier} for classifier in classifiers]),
		"classifierGroupByCols": ", ".join(
				["qryCSet_CrossTab.[%s]"
				 % classifier for classifier in classifiers])
	}
	
	return stringSubs

	
def getClassifiers(db):
	sql = "SELECT classifierId FROM tblClassifiers"
	results = db.query(sql)
	usedClassifiers = [row[0] for row in results]

	return usedClassifiers
