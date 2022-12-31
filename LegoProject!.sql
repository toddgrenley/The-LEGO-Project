
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
-- Work in progress. More to come!