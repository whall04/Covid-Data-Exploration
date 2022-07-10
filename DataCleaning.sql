-- Cleaning Data in SQL


Select *
From PortfolioProject.dbo.NashvilleHousing

-------------------------------------------------------------------------------------------------
-- Standardize date

Select SaleDateConverted, CONVERT(date, SaleDate)
From PortfolioProject..NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(date, saledate)


--In case of Update error

Alter Table portfolioproject.dbo.nashvillehousing
Add SaleDateConverted date;

Update PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(date, saledate)



-------------------------------------------------------------------------------------------------
-- Populate property address data

Select *
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) 
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) 
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


-------------------------------------------------------------------------------------------------
-- Breaking Out Address into Individual Columns (Address, City, State)

Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

Select
Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, Substring(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress)) as City
From PortfolioProject.dbo.NashvilleHousing


Alter Table portfolioproject.dbo.nashvillehousing
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

Alter Table portfolioproject.dbo.nashvillehousing
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET PropertySplitCity = Substring(PropertyAddress, CHARINDEX(',', PropertyAddress) +2, LEN(PropertyAddress))



Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From PortfolioProject.dbo.NashvilleHousing

Alter Table portfolioproject.dbo.nashvillehousing
Add OwnerSplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

Alter Table portfolioproject.dbo.nashvillehousing
Add OwnerSplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

Alter Table portfolioproject.dbo.nashvillehousing
Add OwnerSplitState Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

Select distinct(SoldAsVacant), COUNT(soldasvacant)
From PortfolioProject.dbo.NashvilleHousing
group by SoldAsVacant
order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   Else SoldAsVacant
	   END
From PortfolioProject.dbo.NashvilleHousing


Update PortfolioProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   Else SoldAsVacant
	   END


-------------------------------------------------------------------------------------------------
-- Remove Duplicates

With RowNumCTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate, 
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProject.dbo.NashvilleHousing
)
Delete 
From RowNumCTE
Where row_num > 1


-------------------------------------------------------------------------------------------------
-- Delete unused columns

Alter Table PortfolioProject.dbo.NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate



