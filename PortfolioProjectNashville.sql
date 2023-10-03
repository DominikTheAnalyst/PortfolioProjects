/*

Cleaning Data in SQL

*/

SELECT *
FROM Nashville_Housing

-- Standardize Date Format -- 

SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM Nashville_Housing;
--
ALTER TABLE Nashville_Housing
ADD SaleDateConverted DATE;
--
UPDATE Nashville_Housing
SET SaleDateConverted = CONVERT(DATE, SaleDate);

-- POPULATE PROPERTY ADDRESS DATA --

SELECT *
FROM Nashville_Housing
-- where PropertyAddress is null --
ORDER BY ParcelID

-- Join the table to itsel under ParcelID and uniqueID to remove duplicates

SELECT Axel.ParcelID, Axel.PropertyAddress, Beti.ParcelID, Beti.PropertyAddress, 
FROM Nashville_Housing Axel
JOIN Nashville_Housing Beti
ON Axel.ParcelID = Beti.ParcelID
AND Axel.UniqueID <> Beti.UniqueID
WHERE Axel.PropertyAddress is null 
-- we have 35 null Axel.propertyaddress --
-- we put propertyaddress from Axel to Beti, we use ISNULL

SELECT Axel.ParcelID, Axel.PropertyAddress, Beti.ParcelID, Beti.PropertyAddress, ISNULL(Axel.PropertyAddress, Beti.PropertyAddress) -- new column will be created --
FROM Nashville_Housing Axel
JOIN Nashville_Housing Beti
ON Axel.ParcelID = Beti.ParcelID
AND Axel.UniqueID <> Beti.UniqueID
WHERE Axel.PropertyAddress is null 

-- update axel.propertyadress with data from ISNULL column 

UPDATE Axel
SET PropertyAddress = ISNULL(Axel.PropertyAddress, Beti.PropertyAddress)
FROM Nashville_Housing Axel
JOIN Nashville_Housing Beti
ON Axel.ParcelID = Beti.ParcelID
AND Axel.UniqueID <> Beti.UniqueID
WHERE Axel.PropertyAddress is null

-- BREAKING OUT PROPERTY ADDRESS INTO INDIVIDUAL COLUMNS (Address, City, State)

SELECT PropertyAddress, 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM Nashville_Housing
--
ALTER TABLE Nashville_Housing
ADD PropertySplitAdress NVARCHAR(255), PropertySplitCity NVARCHAR(255)
--
UPDATE Nashville_Housing
SET PropertySplitAdress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));
--
SELECT *
FROM Nashville_Housing
-- Breaking out the Owner Address into idividual column
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerSplitAddress, 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerSplitCity,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerSplitState
FROM Nashville_Housing
-- 
ALTER TABLE Nashville_Housing 
ADD OwnerSplitAddress NVARCHAR(255), OwnerSplitCity NVARCHAR(255), OwnerSplitState NVARCHAR(255)
--
UPDATE Nashville_Housing
SET 
OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville_Housing
GROUP BY(SoldAsVacant)
--
SELECT SoldAsVacant,
	CASE 
    	WHEN SoldAsVacant = 0 THEN 'No' 
    	WHEN SoldAsVacant = 1 THEN 'Yes'
		END
FROM Nashville_Housing 
-- Alter the table to change the data type of SoldasVacant to NVARCHAR
ALTER TABLE Nashville_Housing
ALTER COLUMN SoldasVacant NVARCHAR(3); -- Assuming 3 characters are enough for 'No' and 'Yes'
--
UPDATE Nashville_Housing
SET SoldasVacant = CASE 
    WHEN SoldAsVacant = 0 THEN 'No'
    WHEN SoldAsVacant = 1 THEN 'Yes'
    ELSE SoldasVacant -- Handle any other values (optional)
    END;
-- Remove Duplicates. Conditions. If the ParcelID, PropertyAddress, SaleDate, LegalReference
-- are the same we treat it as duplicates. 
-- Found 104 row_num which are duplicates which were delited.
WITH RowNumCTE AS (
SELECT *, 
ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) row_num
FROM Nashville_Housing 
) 
SELECT * -- DELETE
FROM RowNumCTE
WHERE row_num > 1

-- DELETE unused Columns. This is COPY of RAW DATA so we can do it. 
-- We remove columns we converted: SaleDate, OwnerAdress, PropertyAddress and TaxDistrict. 
SELECT *
FROM Nashville_Housing

-- ALTER TABLE Nashville_Housing
-- DROP COLUMN SaleDate, OwnerAddress, PropertyAddress, TaxDistrict

-- Data Profiling by checking missing values in Property Address column
SELECT 'PropertySplitAddress' AS ColumnName, COUNT(*) AS MissingCount
FROM Nashville_Housing
WHERE PropertySplitAddress IS NULL;


