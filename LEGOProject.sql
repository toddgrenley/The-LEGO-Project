
Part I
Starting with the Sets and Themes tables


SELECT *
FROM [Portfolio Project]..LegoSets

SELECT *
FROM [Portfolio Project]..LegoThemes


-- Let's Look at how many sets have been released each year since Lego began

SELECT year, COUNT(year) AS SetsReleased
FROM [Portfolio Project]..LegoSets
GROUP BY year
ORDER BY year

-- And then which years have seen the most releases!

SELECT year, COUNT(year) AS SetsReleased
FROM [Portfolio Project]..LegoSets
GROUP BY year
ORDER BY SetsReleased desc



-- Let's go ahead and join our tables to see how they line up

SELECT *
FROM [Portfolio Project]..LegoSets AS Sets
JOIN [Portfolio Project]..LegoThemes AS Themes
	ON Sets.theme_id = Themes.id



-- How many Sets have been produced of each Theme

SELECT Themes.name, COUNT(Sets.name) AS NumberOfSets
FROM [Portfolio Project]..LegoSets AS Sets
JOIN [Portfolio Project]..LegoThemes AS Themes
	ON Sets.theme_id = Themes.id
GROUP BY Themes.name
ORDER BY NumberOfSets desc

-- My favorite theme was Rock Raiders, so let's see how many of that there were

SELECT Sets.name AS SetName, Themes.name AS Theme, num_parts AS NumberOfParts, year AS Released
FROM [Portfolio Project]..LegoSets AS Sets
JOIN [Portfolio Project]..LegoThemes AS Themes
	ON Sets.theme_id = Themes.id
WHERE Themes.name LIKE '%Rock Raiders%'

-- This gives the average part count for each theme, to give an idea of how complex they typically were

SELECT Themes.name AS Theme, AVG(num_parts) AS AverageParts
FROM [Portfolio Project]..LegoSets AS Sets
JOIN [Portfolio Project]..LegoThemes AS Themes
	ON Sets.theme_id = Themes.id
GROUP BY Themes.name
ORDER BY AverageParts desc

-- Let's check that against an individual theme just to see if it looks right

SELECT Sets.name, year, num_parts
FROM [Portfolio Project]..LegoSets AS Sets
JOIN [Portfolio Project]..LegoThemes AS Themes
	ON Sets.theme_id = Themes.id
WHERE Themes.name LIKE '%Ideas%'



-- After the last few queries involving sets and themes, I noticed some of the sets are only listed with specific subthemes, for instance a Harry Potter set
-- only being listed with the theme "Order of the Phoenix" which is a particular movie in the series. So we want to know the parent themes as well. Let's sort this.

-- This shows there are only a handful of parent IDs that branch into more individual IDs

SELECT COUNT(DISTINCT id) AS IDs, COUNT(DISTINCT parent_id) AS ParentIDs
FROM [Portfolio Project]..LegoThemes

-- This shows all themes without a parent ID listed, meaning they are parent IDs themselves

SELECT name, COUNT(id) AS IDs, COUNT(parent_id) AS ParentIDs
FROM [Portfolio Project]..LegoThemes
WHERE parent_id is NULL
GROUP BY name

-- We need to sort out the themes table so we can see each theme lined up with its parent theme, because our original queries only show subthemes
-- To do this, we will join the themes table on itself

SELECT ThemeA.id AS ParentID, ThemeA.name AS ParentTheme, ThemeB.name AS SubTheme, ThemeB.id AS SubThemeID
FROM [Portfolio Project]..LegoThemes AS ThemeA
LEFT JOIN [Portfolio Project]..LegoThemes AS ThemeB
	ON ThemeA.id = ThemeB.parent_id


-- Now that we have the themes table sorted, we want to be able to query this new table instead of the original to make things easier
-- To do this, we will create a Temp Table for further querying

CREATE TABLE #SortedThemes
(
ParentID nvarchar(255),
ParentTheme nvarchar(255),
SubTheme nvarchar(255),
SubThemeID nvarchar(255)
)

INSERT INTO #SortedThemes
SELECT ThemeA.id AS ParentID, ThemeA.name AS ParentTheme, ThemeB.name AS SubTheme, ThemeB.id AS SubThemeID
FROM [Portfolio Project]..LegoThemes AS ThemeA
LEFT JOIN [Portfolio Project]..LegoThemes AS ThemeB
	ON ThemeA.id = ThemeB.parent_id

-- Let's test it out on the aformentioned Harry Potter theme

SELECT Sets.name AS SetName, year AS Released, num_parts AS Parts, ParentTheme, SubTheme
FROM [Portfolio Project]..LegoSets AS Sets
JOIN #SortedThemes AS Themes
	ON Sets.theme_id = Themes.SubThemeID
WHERE ParentTheme = 'Harry Potter'

-- It works beautifully. Now we can see every set ever released along with its year, number of parts, and themes it was part of! (Which is what most Lego enthusiasts 
-- would care about)



Part II



-- It's all been well and good with the first two tables, but what if we want more information on the Lego sets, such as individual parts?
-- We'll need to connect to other tables for more information, some of which have no directly shared fields, so we'll need to stretch a bit

-- First, let's check out the Inventories table, which is the parent table of the database

SELECT *
FROM [Portfolio Project]..LegoInventories

-- And then go ahead and join with our first Sets table to see how they line up

SELECT *
FROM [Portfolio Project]..LegoSets AS Sets
JOIN [Portfolio Project]..LegoInventories AS Inv
	ON Sets.set_num = Inv.set_num

-- Clean it up and select only relevant information. Also we'll order by ID, which is the primary column of the parent table

SELECT Sets.set_num, Inv.id, name, year, num_parts
FROM [Portfolio Project]..LegoSets AS Sets
JOIN [Portfolio Project]..LegoInventories AS Inv
	ON Sets.set_num = Inv.set_num
ORDER BY id

-- We see that the 'set_num' serial number lines up with a numerical ID in the parent table, so we can use this to reach information in other indirectly related tables
-- Now we'll go to the Inventory Parts table, where this query will show us how each individual set lines up with the parts within it

SELECT id, set_num, part_num, quantity, color_id
FROM [Portfolio Project]..LegoInventories AS Inv
JOIN [Portfolio Project]..LegoInventoryParts AS InvP
	ON Inv.id = InvP.inventory_id
ORDER BY set_num

-- The only problem is the name of the Sets is not displayed, just the serial numbers, so just like with lining up the themes, we'll need to create a new table to 
-- query to line up the names of the Sets with the Parts they contain

CREATE TABLE #PartsSorted
(
id numeric,
set_num nvarchar (255),
part_num nvarchar (255),
quantity numeric,
color_id nvarchar (255)
)

INSERT INTO #PartsSorted
SELECT id, set_num, part_num, quantity, color_id
FROM [Portfolio Project]..LegoInventories AS Inv
JOIN [Portfolio Project]..LegoInventoryParts AS InvP
	ON Inv.id = InvP.inventory_id

-- Let's test it out

SELECT Sets.set_num, name, year, num_parts, part_num, quantity, color_id
FROM [Portfolio Project]..LegoSets AS Sets
JOIN #PartsSorted AS Parts
	ON Sets.set_num = Parts.set_num
ORDER BY id

-- From this we can see a rundown of each part number within each set, so each set will appear once in the table for each different type of part in it
-- Just to cross check, we can sum any quantity of parts for a given set to see if it matches the 'num_parts' column

SELECT SUM(quantity) AS TotalPartsNeeded
FROM [Portfolio Project]..LegoSets AS Sets
JOIN #PartsSorted AS Parts
	ON Sets.set_num = Parts.set_num
WHERE name = 'Rock Raiders HQ'

-- In writing the last query, I noticed all one would need to do is sum the 'quantity' column of the this table to get the TOTAL number of pieces needed to build
-- EVERY set in LEGO's database! Close to 2 million pieces! (Simply remove the WHERE clause from the last query)
