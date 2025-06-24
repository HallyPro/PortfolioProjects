-- Standardize date format


ALTER TABLE nashville
	ALTER COLUMN "SaleDate" TYPE DATE
	USING to_date("SaleDate", 'YYYY-MM-DD');


-- Populate Property Address data


SELECT nasa."ParcelID", nasa."PropertyAddress", nasb."ParcelID", nasb."PropertyAddress"
	FROM nashville AS nasa
	JOIN nashville AS nasb
	ON nasa."ParcelID" = nasb."ParcelID"
	AND nasa."UniqueID " <> nasb."UniqueID "
	WHERE nasa."PropertyAddress" IS NULL;

UPDATE nashville AS nasa
	SET "PropertyAddress" = COALESCE(nasa."PropertyAddress", nasb."PropertyAddress")
	FROM nashville AS nasb
	WHERE nasa."ParcelID" = nasb."ParcelID"
	  AND nasa."UniqueID " <> nasb."UniqueID "
  	  AND nasa."PropertyAddress" IS NULL;


-- Separating Address into different columns (Address, City, State)


SELECT 
	SUBSTRING("PropertyAddress", 1, POSITION(',' IN "PropertyAddress") - 1) AS Address
, 	SUBSTRING("PropertyAddress", POSITION(',' IN "PropertyAddress") + 1, LENGTH("PropertyAddress")) AS City 
FROM nashville;

ALTER TABLE nashville
	ADD COLUMN streetAddress VARCHAR(255);

UPDATE nashville
	SET streetAddress = SUBSTRING("PropertyAddress", 1, POSITION(',' IN "PropertyAddress") - 1);

ALTER TABLE nashville
	ADD COLUMN city VARCHAR(255);

UPDATE nashville
	SET city = SUBSTRING("PropertyAddress", POSITION(',' IN "PropertyAddress") + 1, LENGTH("PropertyAddress"));

SELECT 
	(string_to_array("OwnerAddress", ','))[1],
	(string_to_array("OwnerAddress", ','))[2],
	(string_to_array("OwnerAddress", ','))[3]
FROM nashville;

ALTER TABLE nashville
	ADD COLUMN OwnerAddress VARCHAR(255);

ALTER TABLE nashville
	ADD COLUMN OwnerCity VARCHAR(255);

ALTER TABLE nashville
	ADD COLUMN OwnerState VARCHAR(255);

UPDATE nashville
	SET OwnerAddress = (string_to_array("OwnerAddress", ','))[1];

UPDATE nashville
	SET OwnerCity = (string_to_array("OwnerAddress", ','))[2];

UPDATE nashville
	SET OwnerState = (string_to_array("OwnerAddress", ','))[3];

SELECT * FROM nashville;


-- Change Y and N to Yes and No in "Sold as Vacant" field


SELECT "SoldAsVacant",
	CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
		 WHEN "SoldAsVacant" = 'N' THEN 'No'
		 ELSE "SoldAsVacant"
		 END
FROM nashville;

UPDATE nashville
	SET "SoldAsVacant" = CASE WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
		 					  WHEN "SoldAsVacant" = 'N' THEN 'No'
		 					  ELSE "SoldAsVacant"
		 					  END;

SELECT DISTINCT("SoldAsVacant"), COUNT("SoldAsVacant") 
FROM nashville
	GROUP BY "SoldAsVacant"
	ORDER BY 2;


-- Remove Duplicates
WITH RowNumCTE AS (
SELECT *, 
	ROW_NUMBER() OVER ( 
	 PARTITION BY "ParcelID",
	 			   streetaddress,
					city,
			   	   "SalePrice",
				   "SaleDate",
				   "LegalReference"
				   ORDER BY 
				     "UniqueID ") AS row_num
					FROM nashville
)
DELETE FROM nashville 
	WHERE "UniqueID " IN (
	SELECT "UniqueID "
	FROM RowNumCTE
	WHERE row_num > 1
	);


--Delete Unused Columns 


ALTER TABLE nashville 
	DROP COLUMN "TaxDistrict",
	DROP COLUMN "PropertyAddress",
	DROP COLUMN "OwnerAddress",
	DROP COLUMN "SaleDate";

















































 