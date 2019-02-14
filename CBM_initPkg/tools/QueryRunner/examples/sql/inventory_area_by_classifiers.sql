SELECT
    %(classifierSelectCols)s,
    tblInventory.ClassifierSetID,
    SUM(tblInventory.Area) AS SumOfArea
FROM qryCSet_CrossTab
INNER JOIN tblInventory
    ON qryCSet_CrossTab.ClassifierSetIDCroseTab = tblInventory.ClassifierSetID
GROUP BY
	%(classifierGroupByCols)s,
	tblInventory.ClassifierSetID
HAVING SUM(tblInventory.Area) > :min_inventory_area
