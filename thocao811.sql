USE finalproject;

/* ######################################################################################################################################################
       
DATA CLEANING
	1. Check Missing Value & NULL
	2. Data Consistency: Check for and correct inconsistencies.
	3. Removing Duplicates: Identify and remove duplicate rows if any.

########################################################################################################################################################
*/

/* Data cleaning 1. Check Missing Value & NULL  */
-- Check Missing Value
SELECT row_id 		FROM us_household_income WHERE row_id = '';
SELECT id 			FROM us_household_income WHERE id = '' ;
SELECT State_Code  	FROM us_household_income WHERE State_Code = '' ;
SELECT State_Name	FROM us_household_income WHERE State_Name = '' ;
SELECT State_ab  	FROM us_household_income WHERE State_ab = '' ;
SELECT County  		FROM us_household_income WHERE County = '' ;
SELECT City  		FROM us_household_income WHERE City = '' ;
SELECT Place  		FROM us_household_income WHERE Place = '' ;
SELECT Type  		FROM us_household_income WHERE Type = '' ;
SELECT Primary_  	FROM us_household_income WHERE Primary_ = '' ;
SELECT Zip_Code 	FROM us_household_income WHERE Zip_Code = '' ;
SELECT Area_Code 	FROM us_household_income WHERE Area_Code = '' ;
SELECT ALand  		FROM us_household_income WHERE ALand  = '' AND ALand  <> 0;  -- WHERE ALand = '' sẽ đưa ra toàn bộ giá trị = 0, nên cần thêm điều kiện ALand khác 0
SELECT AWater  		FROM us_household_income WHERE AWater = '' AND AWater <> 0;
SELECT Lat  		FROM us_household_income WHERE Lat = '' AND Lat <> 0;
SELECT Lon  		FROM us_household_income WHERE Lon = '' AND Lon <> 0;
-- Result: No missing value.

-- Check NULL
SELECT * 
FROM us_household_income
WHERE row_id IS NULL
	OR id IS NULL
	OR State_Code IS NULL
	OR State_Name IS NULL
	OR State_ab IS NULL
	OR County IS NULL
	OR City IS NULL
	OR Place IS NULL
	OR Type IS NULL
	OR Primary_ IS NULL
	OR Zip_Code IS NULL
	OR Area_Code IS NULL
	OR ALand IS NULL
	OR AWater IS NULL
	OR Lat IS NULL
	OR Lon IS NULL
; 
-- Result: only 1 row has NULL in column "Place"

-- Xóa dòng chứa giá trị NULL ở cột "Place"
DELETE FROM us_household_income WHERE Place IS NULL;


-- -----------------------------------------------------------------------------------------------------------------------------------
/* Data cleaning 2. Data Consistency */

-- Đối với State, mỗi State_Name chỉ có 1 State_Code, 1 State_ab
SELECT 
	COUNT(DISTINCT State_Code),
    COUNT(DISTINCT State_Name),
    COUNT(DISTINCT State_ab) 
FROM us_household_income
;
-- Result: Có 52 State_Code tương ứng với 52 State_ab nhưng có tới 53 State_Name. Tức là có 1 State_Name đang bị sai.

-- Xác định State_Name đang bị sai
-- Bước 1: Tạo bảng chứa giá trị duy nhất của State_Code và State_Name.
SELECT DISTINCT State_Code, State_Name
FROM us_household_income;

-- Bước 2: Tìm ra State_Code bị lặp lại 2 lần và State_Name tương ứng.
WITH cte_count_state_name AS (

	WITH cte_distinct_state AS (
		SELECT DISTINCT State_Code, State_Name
		FROM us_household_income
		)
	SELECT 
		State_Code, 
		State_Name, 
		COUNT(State_Name) OVER(partition by State_Code) count_state_name
	FROM cte_distinct_state
)
SELECT 
	State_Code, 
    State_Name
FROM cte_count_state_name
WHERE count_state_name > 1
;
-- Result (2 rows): State_Code = 13 vừa ứng với State_Name = "Georgia", vừa ứng với State_Name = "georia" nhưng "georia" là sai

-- UPDATE: Trong cột State_Name, thay "georia" thành "Georgia"
UPDATE us_household_income
SET State_Name = CASE WHEN State_Name = 'georia' THEN 'Georgia' ELSE State_Name END;
-- Result 1 row(s) affected Rows matched: 32532  Changed: 1 



-- Đối với County
-- Check ký tự đặc biệt ngoài bộ chữ cái tiếng Anh alphabel, dấu chấm, dấu sở hữu cách, dấu gạch ngang. \s là khoảng space.
SELECT DISTINCT County
FROM us_household_income
WHERE County REGEXP "[^a-z \s . ' -]"
;
-- Result (2 rows): 'Do�a Ana County' và 'R�o Grande Municipio' chứa ký tự lạ �.

-- UPDATE: Trong cột County, thay 'Do�a Ana County' thành 'Dona Ana County', thay 'R�o Grande Municipio' thành 'Rio Grande Municipio'
UPDATE us_household_income
SET County = CASE 
				WHEN County = 'Do�a Ana County' 	 THEN 'Dona Ana County' 
                WHEN County = 'R�o Grande Municipio' THEN 'Rio Grande Municipio'
				ELSE County 
                END;
-- Result: 4 row(s) affected Rows matched: 32532  Changed: 4




-- Đối với City              
-- Check ký tự đặc biệt ngoài bộ chữ cái tiếng Anh alphabel, dấu chấm, dấu sở hữu cách, dấu gạch ngang. \s là khoảng space.
SELECT DISTINCT City
FROM us_household_income
WHERE City REGEXP "[^a-z \s . ' -]"; 
-- Result (1 rows): 'Pennsboro Wv  26415' đang bị lỗi chứa ký tự số. Tên City đúng là 'Pennsboro'.

-- UPDATE: Trong cột City, thay 'Pennsboro Wv  26415' thành 'Pennsboro'.
UPDATE us_household_income
SET City = CASE WHEN City = 'Pennsboro Wv  26415' THEN 'Pennsboro' ELSE City END;
-- Result: 1 row(s) affected Rows matched: 32532  Changed: 1




-- Đối với Place
-- Check ký tự đặc biệt ngoài bộ chữ cái tiếng Anh alphabel, dấu chấm, dấu sở hữu cách, dấu gạch ngang. \s là khoảng space.
SELECT DISTINCT Place
FROM us_household_income
WHERE Place REGEXP "[^a-z \s . ' -]"
;
/* Result (7 rows): 
	'Raymer (New Raymer)'
	'Boquer�n'
	'El Mang�'
	'Fr�nquez'
	'Liborio Negr�n Torres'
	'Parcelas Pe�uelas'
	'R�o Lajas'
*/ 
/* UPDATE: trong cột Place 
	'Raymer (New Raymer)' -----> 'Raymer'
	'Boquer�n' -----> 'Boqueron'
	'El Mang�' -----> 'El Mango'
	'Fr�nquez' -----> 'Franchise'
	'Liborio Negr�n Torres'	-----> 'Liborio Negron Torres'
	'Parcelas Pe�uelas' -----> 'Parcelas Penuelas'
	'R�o Lajas'	-----> 'Rio Lajas'
*/ 
UPDATE us_household_income
SET Place = CASE 
				WHEN Place = 'Raymer (New Raymer)' 	THEN 'Raymer'
				WHEN Place = 'Boquer�n' 			THEN 'Boqueron'
				WHEN Place = 'El Mang�' 			THEN 'El Mango'
				WHEN Place = 'Fr�nquez' 			THEN 'Franchise'
				WHEN Place = 'Liborio Negr�n Torres'THEN 'Liborio Negron Torres'
				WHEN Place = 'Parcelas Pe�uelas' 	THEN 'Parcelas Penuelas'
				WHEN Place = 'R�o Lajas' 			THEN 'Rio Lajas'
				ELSE Place 
                END;
-- Result: 7 row(s) affected Rows matched: 32532  Changed: 7 




-- Đối với Type
SELECT DISTINCT Type
FROM us_household_income
ORDER BY 1;
/* Result (12 rows): 
	'Borough'
	'Boroughs'
	'CDP'
	'City'
	'Community'
	'County'
	'CPD'
	'Municipality'
	'Town'
	'Track'
	'Urban'
	'Village'

Có 2 lỗi, có thể là nhầm lẫn khi gõ chữ.
'Borough' và 'Boroughs' là cùng nói về 'Borough'.
CPD là viết tắt của “Continuing Professional Development”, không phải Type of geographic area. Đó có thể là CDP.
*/
-- UPDATE: Trong cột Type, thay 'Boroughs' thành 'Borough', thay 'CPD' thành 'CDP'.
UPDATE us_household_income
SET Type = CASE 
			WHEN Type = 'Boroughs' THEN 'Borough' 
			WHEN Type = 'CPD' THEN 'CDP'
			ELSE Type 
			END;
-- Result: 3 row(s) affected Rows matched: 32532  Changed: 3 


	
-- Đối với Primary_
SELECT Primary_, COUNT(*)
FROM us_household_income
GROUP BY Primary_;
-- Result (2 rows): có 29439 giá trị là 'Track'  và   3093 giá trị là 'place'
-- Ko phát hiện bất thường



-- Đối với Zip_Code
-- Check định dạng của Zip_Code
SELECT DISTINCT Zip_Code
FROM us_household_income
WHERE Zip_Code REGEXP "[^0-9]";
-- Result: Không có Zip_Code nào có ký tự ngoài bộ chữ số từ 0->9

-- Check độ dài của Zip_Code
SELECT DISTINCT 
	State_Name,
    Zip_Code, 
    LENGTH(Zip_Code) AS length,
    CASE 
		WHEN LENGTH(Zip_Code) = 3 THEN CONCAT('00', Zip_Code)
        WHEN LENGTH(Zip_Code) = 4 THEN CONCAT('0', Zip_Code)
        ELSE Zip_Code
	END as new_Zip_Code
FROM us_household_income
ORDER BY length;
/* Result:
zip code có format gồm 5 chữ số mà data có những zip code chỉ gồm 3-4 chữ số. 
zip code của bang Puerto Rico thường có 2 số 00 ở đầu (ví dụ 00601). 
zip code của bang Connecticut thường có 1 số 0  ở đầu (ví dụ 06001).
*/

-- Cột Zip_Code đang để kiểu dữ liệu INT, ko thể bổ sung thêm số 0 vào đằng trước Zip_Code để đủ 5 chữ số.
-- Đổi kiểu dữ liệu từ INT sang VARCHAR(5)
ALTER TABLE us_household_income 
CHANGE COLUMN `Zip_Code` `Zip_Code` VARCHAR(5) NULL DEFAULT NULL;    

-- UPDATE: Trong cột Zip_Code, bổ sung thêm số 0 vào đằng trước để đủ 5 chữ số.
UPDATE us_household_income
SET Zip_Code = CASE 
					WHEN LENGTH(Zip_Code) = 3 THEN CONCAT('00', Zip_Code)
					WHEN LENGTH(Zip_Code) = 4 THEN CONCAT('0', Zip_Code)
					ELSE Zip_Code
				END;
-- Result: 2775 row(s) affected Rows matched: 32532  Changed: 2775




-- Đối với Area_Code
-- Check định dạng của Area_Code
SELECT DISTINCT Area_Code
FROM us_household_income
WHERE Area_Code REGEXP "[^0-9]";
-- Result (1 row): có Area_Code = 'M' là ký tự chữ cái.

-- Check độ dài của Area_Code
SELECT DISTINCT 
    Area_Code, 
    LENGTH(Area_Code) AS length
FROM us_household_income
ORDER BY length;  
-- Result: có Area_Code = 'M' chỉ có 1 ký tự, trong khi các Area_Code khác đều có 3 chữ số.

-- Kiểm tra thông tin của những dòng có Area_Code = 'M' 
SELECT * 
FROM us_household_income
WHERE Area_Code = 'M';
-- Result (1 row): row_id = 28896, bang Texas, Anderson County, thành phố Pasadena, thị trấn Elkhart

-- Ở những nơi cùng địa điểm, thì có Area_Code như thế nào
SELECT Area_Code, COUNT(*) as count_area_code
FROM us_household_income
WHERE 
	State_Name = 'Texas' 
	AND County = 'Anderson County' 
	AND City = 'Pasadena'
	AND Place = 'Elkhart'
GROUP BY 
	Area_Code;
-- Result (3 rows): có 11 bản ghi chứa Area_Code = 713, 1 bản ghi Area_Code = 832 và 1 bản ghi Area_Code = 'M'.

-- UPDATE: Trong cột Area_Code, thay 'M' thành 713, với điều kiện Area_Code ko chứa ký tự số thuộc [0-9] và nơi đó ở bang Texas, Anderson County, thành phố Pasadena, thị trấn Elkhart
UPDATE us_household_income
SET Area_Code = 713
WHERE Area_Code REGEXP "[^0-9]"
	AND State_Name = 'Texas' 
	AND County = 'Anderson County' 
	AND City = 'Pasadena'
	AND Place = 'Elkhart';
-- Result: 1 row(s) affected Rows matched: 1  Changed: 1




-- Đối với ALand
SELECT 
	MIN(ALand), 
	MAX(ALand), 
	AVG(ALand)
FROM us_household_income; 
-- Result (1 row): Min = 0;   MAX = 91,632,669,709  ; MEAN = 116,759,749.5149
-- Thắc mắc: tại sao diện tích đất ở lại có thể = 0 ???

-- Tìm hiểu các bản ghi có ALand = 0
SELECT * 
FROM us_household_income 
WHERE ALand = 0; 
/* Result: 70 rows 
	Những dòng có ALand = 0 thì có AWater cực lớn ( từ 13,141,095  tới  6,248,340,078)
    Có thể có những hộ gia đình bên Mỹ, sinh sống trên du thuyền, thay vì ở nhà mặt đất.

*/



-- Lat ranges from -90 to 90 and Lon ranges from -180 to 180.
SELECT * FROM us_household_income
WHERE Lat < -90  OR Lat > 90
   OR Lon < -180 OR Lon > 180
; 
-- Result: 0 rows.
    



-- ##############################################################################################################
/* DATA CLEANING 3. Removing Duplicates (Identify and remove duplicate rows if any)  
	Phần 1: Check trùng lặp trên cột id. vÌ id giống nhau, chắc chắn các cột còn lại cũng giống nhau
    Phần 2: Check trùng lặp trên các cột còn lại ngoài 2 cột (row_id, id)
*/

-- Phần 1: Check trùng lặp trên cột id ---------------------------------------------------------------------------
-- Check duplicate values
SELECT id, COUNT(*) as count_id
FROM us_household_income
GROUP BY id
HAVING count_id > 1
;
-- Result (7 rows): có 7 id lặp lại, và chỉ lặp lại 1 lần.
 
-- Xác định row_id của duplicate values
SELECT *
FROM
(
	SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id) as Row_Num
    FROM us_household_income
) AS Row_Table
WHERE Row_Num > 1
;
-- Result (7 rows): 7 row_id của duplicate values

-- Remove duplicate values
DELETE FROM us_household_income
WHERE row_id IN (
				SELECT row_id
				FROM
				(
					SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id) as Row_Num
					FROM us_household_income
				) AS Row_Table
				WHERE Row_Num > 1
			);
-- Result 7 rows tương ứng với 7 row_id đã bị xóa.


-- Phần 2: Check trùng lặp trên các cột còn lại ngoài 2 cột (row_id, id) ------------------------------------------------------
-- Check duplicate values
SELECT 
	State_Code, State_Name, State_ab, County, City, Place, Type, Primary_, Zip_Code, Area_Code, ALand, AWater, Lat, Lon, 
	COUNT(*) as count_infomation
FROM 
	us_household_income
GROUP BY 
	State_Code, State_Name, State_ab, County, City, Place, Type, Primary_, Zip_Code, Area_Code, ALand, AWater, Lat, Lon
HAVING 
	count_infomation > 1
;
-- Result (2270 rows): có 2270 dòng lặp lại, và chỉ lặp lại 1 lần.
 
-- Xác định row_id của duplicate values
SELECT *
FROM
(	SELECT *, 
	ROW_NUMBER() 
	OVER(PARTITION BY 
	State_Code, State_Name, State_ab, County, City, Place, Type, Primary_, Zip_Code, Area_Code, ALand, AWater, Lat, Lon) as Row_Num
    FROM us_household_income
) AS Row_Table

WHERE Row_Num > 1
;
-- Result (2270 rows): 2270 row_id của duplicate values

-- Remove duplicate values
DELETE FROM us_household_income
WHERE row_id IN 
(
	SELECT row_id
	FROM
	(	SELECT *, 
		ROW_NUMBER() 
		OVER(PARTITION BY State_Code, State_Name, State_ab, County, City, Place, Type, Primary_, Zip_Code, Area_Code, ALand, AWater, Lat, Lon) as Row_Num
		FROM us_household_income
	) AS Row_Table
        
	WHERE Row_Num > 1
);
-- Result 2270 rows tương ứng với 2270 row_id đã bị xóa.




/* #####################################################################################################################################################
     
EDA
Here are 23 tasks to practice your MySQL skills and perform exploratory data analysis (EDA) to extract meaningful insights:
- Tasks 1 - 9: 0.5 points each.
- Tasks 10 - 22: 1 point each.
- Task 0: 2 point.

########################################################################################################################################################
*/ 
-- EDA TASK 0: Create Store Procedure and Create Event 
-- Quy trình hoạt động hàng tuần để cập nhật và xóa dữ liệu (From Cleaning Tasks)

DELIMITER $$
CREATE PROCEDURE clean_data_us_household_income ()
BEGIN
	-- Xóa dòng chứa giá trị NULL ở cột "Place"
	DELETE FROM us_household_income WHERE Place IS NULL;
    
    -- UPDATE: Trong cột State_Name, thay "georia" thành "Georgia"
	UPDATE us_household_income
	SET State_Name = CASE WHEN State_Name = 'georia' THEN 'Georgia' ELSE State_Name END;
    
    -- UPDATE: Trong cột County, thay 'Do�a Ana County' thành 'Dona Ana County', thay 'R�o Grande Municipio' thành 'Rio Grande Municipio'
	UPDATE us_household_income
	SET County = CASE 
					WHEN County = 'Do�a Ana County' THEN 'Dona Ana County' 
					WHEN County = 'R�o Grande Municipio' THEN 'Rio Grande Municipio'
					ELSE County 
					END;
                    
	-- UPDATE: Trong cột City, thay 'Pennsboro Wv  26415' thành 'Pennsboro'.
	UPDATE us_household_income
	SET City = CASE WHEN City = 'Pennsboro Wv  26415' THEN 'Pennsboro' ELSE City END;	
    
    -- UPDATE: trong cột Place 
    UPDATE us_household_income
	SET Place = CASE 
					WHEN Place = 'Raymer (New Raymer)' THEN 'Raymer'
					WHEN Place = 'Boquer�n' THEN 'Boqueron'
					WHEN Place = 'El Mang�' THEN 'El Mango'
					WHEN Place = 'Fr�nquez' THEN 'Franchise'
					WHEN Place = 'Liborio Negr�n Torres' THEN 'Liborio Negron Torres'
					WHEN Place = 'Parcelas Pe�uelas' THEN 'Parcelas Penuelas'
					WHEN Place = 'R�o Lajas' THEN 'Rio Lajas'
					ELSE Place 
					END;
                                        
	-- UPDATE: Trong cột Type, thay 'Boroughs' thành 'Borough', thay 'CPD' thành 'CDP'.
	UPDATE us_household_income
	SET Type = CASE 
				WHEN Type = 'Boroughs' THEN 'Borough' 
				WHEN Type = 'CPD' THEN 'CDP'
				ELSE Type 
				END;                    
    
    -- -----------------------------------------------------------------------------------------------------------------
	-- Cột Zip_Code đang để kiểu dữ liệu INT, ko thể bổ sung thêm số 0 vào đằng trước Zip_Code để đủ 5 chữ số.
	-- Đổi kiểu dữ liệu từ INT sang TEXT
	ALTER TABLE us_household_income 
	CHANGE COLUMN `Zip_Code` `Zip_Code` TEXT NULL DEFAULT NULL;    

	-- UPDATE: Trong cột Zip_Code, bổ sung thêm số 0 vào đằng trước để đủ 5 chữ số.
	UPDATE us_household_income
	SET Zip_Code = CASE 
						WHEN LENGTH(Zip_Code) = 3 THEN CONCAT('00', Zip_Code)
						WHEN LENGTH(Zip_Code) = 4 THEN CONCAT('0', Zip_Code)
						ELSE Zip_Code
					END;
                    
	-- -----------------------------------------------------------------------------------------------------------------
	-- UPDATE: Trong cột Area_Code, thay 'M' thành 713, với điều kiện Area_Code ko chứa ký tự số thuộc [0-9] và nơi đó ở bang Texas, Anderson County, thành phố Pasadena, thị trấn Elkhart
	UPDATE us_household_income
	SET Area_Code = 713
	WHERE Area_Code REGEXP "[^0-9]"
		AND State_Name = 'Texas' 
		AND County = 'Anderson County' 
		AND City = 'Pasadena'
		AND Place = 'Elkhart';    
        
	-- -----------------------------------------------------------------------------------------------------------------
    -- Remove duplicate values 
	DELETE FROM us_household_income
	WHERE row_id IN 
	(
		SELECT row_id
		FROM
		(	SELECT *, 
			ROW_NUMBER() 
			OVER(PARTITION BY State_Code, State_Name, State_ab, County, City, Place, Type, Primary_, Zip_Code, Area_Code, ALand, AWater, Lat, Lon) as Row_Num
			FROM us_household_income
		) AS Row_Table
			
		WHERE Row_Num > 1
	);
    
END $$
DELIMITER ;

-- Enable the event scheduler
SET GLOBAL event_scheduler = ON;

-- Create the event
CREATE EVENT weekly_clean_us_household_income
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP 
DO CALL clean_data_us_household_income();






-- ===========================================================================================================================
-- EDA TASK 1: Summarizing Data by State           
-- Shows the average land area and average water area for each state
SELECT 
	State_Name,
	State_ab, 
	AVG(ALand)  AS avg_aland,
	AVG(AWater) AS avg_awater
FROM us_household_income
GROUP BY State_Name, State_ab
ORDER BY avg_aland desc
;
-- Result 52 rows 



-- -----------------------------------------------------------------------------------------------------------------
-- EDA TASK 2: Filtering Cities by Population Range 
-- List of all cities where the land area is between 50,000,000 and 100,000,000 square meters
SELECT 
	City,
	State_Name, 
	County
FROM us_household_income 
GROUP BY State_Name, County, City
HAVING SUM(ALand) BETWEEN 50000000 AND 100000000
ORDER BY City
;
-- Result 1403 rows 


-- -----------------------------------------------------------------------------------------------------------------
-- EDA TASK 3: Counting Cities per State
-- Counts the number of cities in each state
SELECT 
	State_Name,
	State_ab, 
    COUNT(DISTINCT City) AS count_city
FROM us_household_income
GROUP BY State_Name, State_ab
ORDER BY count_city desc
;
-- Result 52 rows. 
-- Bang có số lượng City lớn nhất là California (CA) với 656 Cities.
-- Bang có số lượng City lớn nhất là District of Columbia (DC) chỉ có 2 Cities.



-- -----------------------------------------------------------------------------------------------------------------
/*  EDA TASK 4: Identifying Counties with Significant Water Area
	Question:
	Please identify the top 10 counties with the highest total water area. 
    The report should include the county name, state name, and total water area, 
    ordered by total water area in descending order.
*/    

SELECT  
	County, 
    State_Name, 
	SUM(AWater) AS total_water
FROM 
	us_household_income
GROUP BY 
	County, State_Name
ORDER BY 
	total_water DESC
LIMIT 10
; 
-- Result 10 rows returned
-- Nơi có diện tích mặt nước lớn nhất là Aleutians East Borough, bang Alaska, với Total Water Area = 88,885,425,633 m^2



-- -----------------------------------------------------------------------------------------------------------------
/*	EDA TASK 5: Finding Cities Near Specific Coordinates
	We are looking for a list of all cities within a specific latitude and longitude range 
		* latitude between 30 and 35
        * longitude between -90 and -85 
        => Hãy hình dung đây là một HÌNH CHỮ NHẬT.
    Include the city name, state name, county, and coordinates. 
	Order the results by latitude and then by longitude.
*/
SELECT 
	City, 
    State_Name, 
    County, 
    CONCAT(Lat, ', ', Lon) AS Coordinates
FROM us_household_income
WHERE Lat BETWEEN 30 AND 35
  AND Lon BETWEEN -90 AND -85
ORDER BY Lat ASC, Lon ASC
;
-- Result 846 rows returned



-- -----------------------------------------------------------------------------------------------------------------
/*	EDA TASK 6: Using Window Functions for Ranking
	Question:
    We need to rank cities within each state based on their land area. 
    Please use a window function to assign ranks and include the city name, state name, land area, and rank in your results. 
    The report should be ordered by state name and rank.
*/
SELECT 
    City,
    State_Name,  
	ALand AS Land_Area,
    RANK() OVER (PARTITION BY State_Name ORDER BY ALand DESC) AS Rank_
FROM us_household_income
ORDER BY State_Name ASC, Rank_ ASC
;
-- 30255 rows returned



-- -----------------------------------------------------------------------------------------------------------------
/* 	EDA TASK 7: Creating Aggregate Reports
	Question:
    Can you generate a report showing the total land area and water area for each state, 
	along with the number of cities in each state? 
    Include the state name and abbreviation, and order the results by the total land area in descending order.
*/
SELECT 
    State_Name,
    State_ab,
    SUM(ALand)  AS total_land_area,
    SUM(AWater) AS total_water_area,
    COUNT(DISTINCT City) AS number_of_cities
FROM 
    us_household_income
GROUP BY 
    State_Name, 
    State_ab
ORDER BY 
    total_land_area DESC;
-- Result 52 rows returned


-- -----------------------------------------------------------------------------------------------------------------
/*	EDA TASK 8: Subqueries for Detailed Analysis
	Question:
    Can you provide a list of all cities where the "land area" is > the "average land area" of all cities? 
    Use a subquery to calculate the average land area. 
    The report should include the city name, state name, and land area, 
    Ordered by land area in descending order.
*/
SELECT 
    City,
    State_Name,
    ALand
FROM 
    us_household_income
WHERE 
    ALand > (SELECT AVG(ALand) FROM us_household_income)
ORDER BY 
    ALand DESC
;
-- Result: 4285 rows returned
-- Result: AVG(ALand) =    113,889,278.1872
-- No.1: Kiana, Alaska, 91,632,669,709.
-- Min : Notus, Idaho, 	   113,895,231.




-- -----------------------------------------------------------------------------------------------------------------
/* 	EDA TASK 9: Identifying Cities with High Water to Land Ratios
	Question:
    Can you identify cities where the water area is greater than 50% of the land area? 
    Include the city name, state name, land area, water area, and the calculated water to land ratio.
    Order the results by the water to land ratio in descending order.
*/
SELECT 
    City,
    State_Name,
    ALand,
    AWater,
    (AWater / ALand) AS water_to_land_ratio
FROM 
    us_household_income
WHERE 
    AWater > ALand * 0.5
ORDER BY 
    water_to_land_ratio DESC;
-- Result 884 rows returned



-- =====================================================================================================================================================================================================================
/* 	EDA TASK 10: Dynamic SQL for Custom Reports
	TẠO Sored Procedure:
	INPUT : State Abbreviation (StateAbbrev)
	OUTPUT: Tổng số City, trung bình ALand, trung bình AWater và danh sách tất cả các thành phố có diện tích đất và nước tương ứng.
	
    Note: 
    Nếu người ta nhập sai chính tả, hoặc ko có thông tin STATE đó trong tập dữ liệu, thì điều hướng ra thông báo gì đó, ko muốn để bảng trống.
	Đây là tính trung bình diện tích của các City trong state đó, hay trung bình diện tích của các vùng nhỏ nhỏ trong State đó.
	Nếu là tính trung bình diện tích của các City thì lẽ ra phải tính tổng diện tích trước chứ.
    
    Cách fix lỗi:
    Test từng cái table sẽ hiển thị trong Result (đã fix được sau 5 lần test :)))
*/
DELIMITER $$

CREATE PROCEDURE GetStateReport(IN StateAbbrev VARCHAR(2))
BEGIN
	
    -- khai báo biến
    DECLARE totalCities INT;
    DECLARE avgLandArea DECIMAL(20,2); 
    DECLARE avgWaterArea DECIMAL(20,2);
    
    -- Điều hướng trường hợp ai đó nhập sai thông tin
    IF 
    
    StateAbbrev NOT IN (SELECT DISTINCT State_ab FROM us_household_income) 
    THEN SELECT CONCAT("No infomation about State Abbreviation: ", StateAbbrev) AS `Response`; 
    
    ELSE

    -- tính toán
    SELECT COUNT(City), AVG(total_aland), AVG(total_awater) 
	INTO totalCities, avgLandArea, avgWaterArea
    FROM 
    (
		SELECT 
			City,
			State_ab, 
			SUM(ALand)  AS total_aland,
			SUM(AWater) AS total_awater
		FROM us_household_income 
        WHERE State_ab = StateAbbrev
		GROUP BY State_ab, City
    ) AS t1
    ;

    -- Bảng 1: xuất output tổng số thành phố, diện tích đất trung bình, diện tích mặt nước trung bình của STATE
    SELECT totalCities  AS 'Total Number of Cities',
           avgLandArea  AS 'Average Land Area (sq meters)',
           avgWaterArea AS 'Average Water Area (sq meters)';

    -- Bảng 2: xuất ra output danh sách tất cả các thành phố với diện tích đất và nước tương ứng.
	SELECT 
		City,
		SUM(ALand)  AS total_aland,
		SUM(AWater) AS total_awater
	FROM us_household_income 
	WHERE State_ab = StateAbbrev
	GROUP BY City
    ORDER BY City;

	END IF;
END $$

DELIMITER ;

CALL GetStateReport('AZ');
-- Result: Ra 2 bảng 
-- Bảng 1: Total Number of Cities = 113, Average Land Area (sq meters) = 172883721.39, Average Water Area (sq meters) = 465176.66
-- Bảng 2: 617 rows returned, gồm các thành phố của bang 'AZ' (Arizona) và diện tích mặt đất và diện tích mặt nước tương ứng

CALL GetStateReport('XY');
-- Result: SHOW thông báo "No infomation about State Abbreviation: XY"



-- =====================================================================================================================================================================================================================
-- EDA TASK 11: Creating and Using Temporary Tables
-- lưu trữ TOP 20 thành phố theo diện tích đất liền
-- Sử dụng bảng tạm thời này để tính diện tích mặt nước trung bình của 20 thành phố này.

-- Bước 1: Tạo Temporary Tables lưu trữ TOP 20 thành phố theo diện tích đất liền
CREATE TEMPORARY TABLE Top20CitiesByLandArea AS
SELECT 
    City,
    State_Name,
    ALand AS Land_Area,
    AWater AS Water_Area
FROM 
    us_household_income
ORDER BY 
    ALand DESC
LIMIT 20;

-- Bước 2: Sử dụng bảng tạm thời này để tính diện tích mặt nước trung bình của 20 thành phố này.
SELECT 
    AVG(Water_Area) AS Average_Water_Area
FROM 
    Top20CitiesByLandArea;
SELECT 
    City,
    State_Name,
    Land_Area,
    Water_Area
FROM 
    Top20CitiesByLandArea;
-- Result: 20 row(s) returned




-- =====================================================================================================================================================================================================================
-- EDA TASK 12: Complex Multi-Level Subqueries (Truy vấn con phức tạp)
-- liệt kê tất cả các State, nơi diện tích đất trung bình của các City lớn hơn diện tích đất trung bình tổng thể của tất cả các City
SELECT 
    State_Name, 
    AVG(ALand) AS Avg_Land_Area
FROM 
    us_household_income
GROUP BY 
    State_Name
HAVING 
    AVG(ALand) > (SELECT AVG(ALand) FROM US_Household_Income)
ORDER BY 
    Avg_Land_Area DESC;
-- Result: 20 rows returned




/* =====================================================================================================================================================================================================================
EDA TASK 13: Optimizing Indexes for Query Performance (Đánh giá hiệu suất truy vấn )

Bạn có thể phân tích tác động của việc lập chỉ mục đến hiệu suất truy vấn không? 
Tạo chỉ mục trên các cột State_Name, City và County, và so sánh thời gian thực hiện 
của một truy vấn phức tạp trước và sau khi lập chỉ mục. 

Cung cấp thông tin chuyên sâu về cách lập chỉ mục đã cải thiện (hoặc không cải thiện) hiệu suất truy vấn, 
bao gồm thời gian thực hiện và kế hoạch truy vấn.
*/
-- Bước 1: Tạo truy vấn 
EXPLAIN SELECT *
FROM us_household_income 
WHERE State_Name = 'North Dakota'
AND City LIKE 'U%'
AND County LIKE 'A%';


-- Bước 2 :cả 3 cột này ta đều tạo index dựa trên tiền tố. Nhưng bao nhiêu ký tự đầu là đủ
SELECT DISTINCT State_Name 	FROM us_household_income;  	-- 52 rows     North Carolina, North Dakota => chọn 8 ký tự đầu
SELECT DISTINCT City 		FROM us_household_income;	-- > 5000 rows Altamont, Altamonte Springs  => chọn 8 ký tự đầu
SELECT DISTINCT County 		FROM us_household_income;	-- 1133 rows   Aleutians East Borough, Aleutians West Census Area => chọn 8 ký tự đầu

-- Bước 3: Tạo các idx trên từng Columns (State_Name, City và County)
CREATE INDEX idx_1_state ON us_household_income(State_Name(8));
CREATE INDEX idx_1_city ON us_household_income(City(8));
CREATE INDEX idx_1_county ON us_household_income(County(8));

-- Bước 4: Tạo các idx trên 2 Columns (State_Name, City và County)
CREATE INDEX idx_21_state_city ON us_household_income(State_Name(8), City(8));
CREATE INDEX idx_22_city_state ON us_household_income(City(8), State_Name(8));
CREATE INDEX idx_23_state_county ON us_household_income(State_Name(8), County(8));
CREATE INDEX idx_24_county_state ON us_household_income(County(8), State_Name(8));
CREATE INDEX idx_25_county_city ON us_household_income(County(8), City(8));
CREATE INDEX idx_26_city_county ON us_household_income(City(8), County(8));

-- Bước 5: Tạo các idx trên 3 Columns (State_Name, City và County)
CREATE INDEX idx_31_state_city_county ON us_household_income(State_Name(8), City(8), County(8));
CREATE INDEX idx_32_state_county_city ON us_household_income(State_Name(8), County(8), City(8));
CREATE INDEX idx_33_city_state_county ON us_household_income(City(8), State_Name(8), County(8));
CREATE INDEX idx_34_city_county_state ON us_household_income(City(8), County(8), State_Name(8));
CREATE INDEX idx_35_county_city_state ON us_household_income(County(8), City(8), State_Name(8));
CREATE INDEX idx_36_county_state_city ON us_household_income(County(8), State_Name(8), City(8));



/* 	Lần 1 (ẩn index đi): Quét qua 32133 rows, nhưng chỉ filtered 0.02 %
	0.015 sec / 0.000 sec
*/
/* 	Lần 2 (chỉ show index 1 cột): 
	34 thẻ,
	key_len là idx_1_state, 
    quét 115 dòng, 
    filtered = 0.21 %
    0.015 sec / 0.000 sec
*/	
/* 	Lần 3 (show thêm các index 2 cột): 
	68 thẻ
	key_len là idx_21_state_city, 
    quét 1 dòng, 
    filtered = 50%
    0.000 sec / 0.000 sec
*/	
/* 	Lần 4 (show thêm các index 3 cột): 
	68 thẻ 
	key_len là idx_21_state_city, 
    quét 1 dòng, 
    filtered = 50%
    0.000 sec / 0.000 sec
*/	

-- Xem các chỉ số của các index trên 2 cột.
SHOW INDEX FROM us_household_income;
-- idx_23_state_county có số lượng thẻ (52, 1676)   ít hơn   idx_21_state_city với số thẻ (52, 11104)
-- Chạy Explain lần 5, ẩn idx_21_state_city 
-- thì MySQL chọn idx_23_state_county, quét 75 rows, chỉ filtered 0.41%

/*++++++++++++++++++++++++++++++++++++++*/
/* Sẽ ra sao nếu tăng mấy cái ký tự đầu */
CREATE INDEX idx_2_1_state_city ON us_household_income(State_Name(8), City(9));
-- Vẫn là idx_21_state_city

CREATE INDEX idx_3_1_state_city_county ON us_household_income(State_Name(8), City(9), County(11));
-- Vẫn là idx_21_state_city

CREATE INDEX idx_3_3_1_state_city_county ON us_household_income(State_Name(20), City(22), County(30));
-- Vẫn là idx_21_state_city



/* =====================================================================================================================================================================================================================
EDA TASK 14: Recursive Common Table Expressions (CTEs)
Đệ quy -> Tính Tổng TÍCH LŨY diện tích mặt đất (ALand) cho các thành phố trong mỗi tiểu bang
*/
-- Bước 1: Hình dung ra cái bảng ban đầu chưa tính Tổng tích lũy
SELECT 
	City,
	State_Name,
	SUM(ALand) AS total_aland,
	ROW_NUMBER() OVER(PARTITION BY State_Name ORDER BY City)  AS `rank_`
FROM us_household_income 
GROUP BY State_Name, City
ORDER BY State_Name, City;
-- Result 11228 rows returned

-- Bước 2: Tạo Recursive CTE
WITH RECURSIVE cte_cumulative_sum AS (
	  SELECT
		  City,
          State_Name, 
		  total_aland, 
		  rank_, 
		  total_aland AS cumulative_sum
	  FROM 
		(SELECT 
				City,
				State_Name,
				SUM(ALand) AS total_aland,
				ROW_NUMBER() OVER(PARTITION BY State_Name ORDER BY City)  AS `rank_`
		FROM us_household_income 
		GROUP BY State_Name, City
		ORDER BY State_Name, City        
        ) subquery1 
	  WHERE 
		rank_ = 1 
	  
	UNION ALL

	  SELECT 
		t2.City,
        t2.State_Name,  
		t2.total_aland, 
		t2.rank_, 
		(t2.total_aland + t1.cumulative_sum) 
	  FROM 
		(SELECT 
				City,
				State_Name,
				SUM(ALand) AS total_aland,
				ROW_NUMBER() OVER(PARTITION BY State_Name ORDER BY City)  AS `rank_`
		FROM us_household_income 
		GROUP BY State_Name, City
		ORDER BY State_Name, City        
        ) t2         
	  JOIN cte_cumulative_sum t1
		ON t2.rank_ = t1.rank_ + 1 
	   AND t2.State_Name = t1.State_Name
)
SELECT *
FROM cte_cumulative_sum
ORDER BY State_Name, City;

/*Result: 11228 rows returned
	0.313 sec / 0.015 sec
	Thời gian phân tích cú pháp (0.015 giây)
	Tổng thời gian thực hiện (0.313 giây)
*/



/* =====================================================================================================================================================================================================================
EDA TASK 15: Data Anomalies Detection
Phát hiện những điểm bất thường trong tập dữ liệu, chẳng hạn như các thành phố có diện tích đất cao hoặc thấp bất thường so với mức trung bình của tiểu bang
Include the city name, state name, land area, state average land area, and anomaly score.

Use statistical methods like standard deviation to identify these anomalies.
Z = (X - mean(X))/ std   
Theo phân phối chuẩn tắc,  | Z | > 3   tức data nằm ngoài 99.73% tổng thể.
*/

-- Bước 1: Thống kê các chỉ số cơ bản: MEAN (trung bình) và STD (phương sai)
SELECT 
	City,
	State_Name,
	SUM(ALand) AS total_aland,
    AVG(SUM(ALand)) OVER(PARTITION BY State_Name) AS `mean`,
    STDDEV(SUM(ALand)) OVER(PARTITION BY State_Name) AS `std`
FROM us_household_income 
GROUP BY State_Name, City;

-- Bước 2: Tính Z = (X - mean(X))/ std
WITH cte_statistical AS (
	SELECT 
		City,
		State_Name,
		SUM(ALand) AS total_aland,
		AVG(SUM(ALand)) OVER(PARTITION BY State_Name) AS `mean`,
		STDDEV(SUM(ALand)) OVER(PARTITION BY State_Name) AS `std`
	FROM us_household_income 
	GROUP BY State_Name, City
)
SELECT 
	City,
	State_Name, 
    total_aland AS `land_area`,
    mean AS `AVG_land_area`,
	ROUND((total_aland - mean)/ std , 2) AS anomaly_Z_score
FROM  
	cte_statistical
WHERE  
	ABS((total_aland - mean)/ std ) > 3
;
-- Result: 223 rows returned
    
    
    
 
/* ===============================================================================================================================================================================
-- EDA TASK 16: Stored Procedures for Complex Calculations
-- Dự đoán diện tích đất và nước trong tương lai dựa trên xu hướng lịch sử
-- Task hoàn toàn bình thường em nhé.
-- Test the stored procedure with different inputs and document the results.
-- Khi em Call có thể nhập input vào để xem kết quả
*/

# xEM BÀI cÁ HỀ  DKT161



/* ===============================================================================================================================================================================
-- EDA TASK 17: Implementing Triggers for Data Integrity
-- tự động cập nhật bảng summary bất cứ khi nào dữ liệu mới được chèn, cập nhật hoặc xóa trong tập dữ liệu chính
-- Tổng hợp như tổng diện tích đất và diện tích mặt nước theo tiểu bang.
-- Kiểm tra trình kích hoạt để đảm bảo Triggers cập nhật chính xác những thay đổi trong tập dữ liệu chính.

-- CASE 1, row data mới insert là 1 state chưa từng xuất hiện => thêm 1 dòng mới
-- CASE 2, row data mới insert là 1 state đã tồn tại          => cộng thêm
-- CASE 3, row data mới delete là 1 state đã tồn tại          => trừ đi
*/
-- Cái bảng Summary Table, nó trông như thế nào ?
SELECT state_ab, SUM(ALand) as total_aland, SUM(AWater) as total_awater
FROM us_household_income
GROUP BY state_ab;

-- Phải tạo 1 cái bảng như này đã
CREATE TABLE state_summary (
    state_ab VARCHAR(2),
    total_aland BIGINT,
    total_awater BIGINT,
    PRIMARY KEY (state_ab)
);

-- Phi vụ INSERT ----------------------------------------------------------------------------------------------------------  
DELIMITER $$
CREATE TRIGGER update_state_summary_when_insert
    AFTER INSERT ON us_household_income
    FOR EACH ROW
BEGIN
    
    -- Trường hợp CASE 1, state_ab chưa tồn tại trong "state_summary"
    -- Thì INSERT nguyên cái rows mới đó
	IF  NEW.State_ab NOT IN (SELECT DISTINCT state_ab FROM state_summary) 
		THEN 
        INSERT INTO state_summary(`state_ab`, `total_aland`, `total_awater`)
        SELECT NEW.State_ab, NEW.ALand, NEW.AWater
        ;

    ELSE
		-- Trường hợp CASE 2, state_ab đã tồn tại trong "state_summary"
        -- Thì UPDATE tính tổng cộng thêm
		UPDATE state_summary
        SET total_aland  = total_aland  + NEW.ALand,
			total_awater = total_awater + NEW.AWater
		WHERE  state_ab = NEW.State_ab;
    
    END IF;
END $$
DELIMITER ;


-- Phi vụ DELETE ----------------------------------------------------------------------------------------------------------  
DELIMITER $$
CREATE TRIGGER update_state_summary_when_delete
    AFTER DELETE ON us_household_income
    FOR EACH ROW
BEGIN
	-- Trường hợp CASE 3, state_ab đã tồn tại trong "state_summary"
	-- Thì UPDATE tính tổng cộng thêm
	UPDATE state_summary
	SET total_aland  = total_aland  - OLD.ALand,
		total_awater = total_awater - OLD.AWater
	WHERE   state_ab = OLD.State_ab;
    
END $$
DELIMITER ;

-- test CASE 1 -----------------------------------------------------------------------------------------------------------------------------------
INSERT INTO us_household_income (id, State_Code, State_Name, State_ab, County, City, Place, Type, Primary_, Zip_Code, Area_Code, ALand, AWater, Lat, Lon) 
VALUES (199571, 53, 'Alabaka', 'XY', 'Turtle', 'Auburn', 'Auburn city', 'City', 'place', 36830, '334', 152375113, 2646161, 32.6077220, -85.4895450
);
SELECT * FROM state_summary;
-- Result (1 row): XY, 152375113, 2646161
-- Vì chưa có state nào là 'XY' => thêm 1 dòng hoàn toàn mới.


-- test CASE 2 -----------------------------------------------------------------------------------------------------------------------------------
INSERT INTO us_household_income (id, State_Code, State_Name, State_ab, County, City, Place, Type, Primary_, Zip_Code, Area_Code, ALand, AWater, Lat, Lon) 
VALUES (200118, 53, 'Alabaka', 'XY', 'Rabbit Fox', 'Auburn', 'Auburn city', 'City', 'place', 36830, '334', 520, 520, 32.6077220, -85.4895450
);
SELECT * FROM state_summary;
-- Result (1 row): XY, 152375633, 2646681 
-- Đã tồn tại state 'XY' => total_aland, total_awater được cộng với data mới => tổng mới.


-- test CASE 3 -----------------------------------------------------------------------------------------------------------------------------------
DELETE FROM us_household_income WHERE `id` = '199571';
SELECT * FROM state_summary;
-- Result (1 row): XY, 520, 520
-- total_aland, total_awater được TRỪ ĐI phần vừa delete trong bảng us_household_income => tổng mới.




/* ===============================================================================================================================================================================
-- EDA TASK 18: Advanced Data Encryption and Security

-- Use MySQL encryption functions to encrypt columns: 
	-->	https://www.geeksforgeeks.org/mysql-aes_encrypt-function/?ref=ml_lbp
    
-- mã hóa các cột như Zip_Code và Area_Code
-- Trình bày cách giải mã dữ liệu cho người dùng được ủy quyền và thảo luận về ý nghĩa của việc bảo mật dữ liệu
*/
-- Bước 1: Tạo thêm 2 cột là COPY version của Zip_Code và Area_Code --> Tiến hành mã hóa 

-- ??? muốn lưu trữ mấy cái MÃ HÓA thì dùng định dạng gì ??? 
-- ---> https://stackoverflow.com/questions/7461962/mysql-how-to-store-aes-encrypted-data
ALTER TABLE US_Household_Income
ADD COLUMN Encrypted_Zip_Code BLOB,
ADD COLUMN Encrypted_Area_Code BLOB;
-- Đã thêm 2 cột mới ở cuối table, là 2 cột NULL


-- Mã hóa dữ liệu
SET @encryption_key = 'loveyoumore';

-- Chú ý là ở phần Clean Data đã chuyển datatype của Zip_Code thành 
UPDATE US_Household_Income
SET Encrypted_Zip_Code  = AES_ENCRYPT(Zip_Code, @encryption_key),
    Encrypted_Area_Code = AES_ENCRYPT(Area_Code, @encryption_key);
-- Running Time: 2.891 sec
-- 2 cột NULL thành 2 cột BLOB
-- Show giá trị các ô hiển thị BLOB (Convert to ASCII) (quá trình tìm ra: BINARY(NULL) -> HEX(đã hiển thị ABC) -> ASCII(đủ các ký tự)): 
-- https://stackoverflow.com/questions/4234010/how-do-i-convert-a-column-to-ascii-on-the-fly-without-saving-to-check-for-matche

SELECT 
    City,
    State_Name,
    Zip_Code,
    Area_Code,
    CONVERT(Encrypted_Zip_Code USING ascii) AS Encrypted_Zip_Code,
    CONVERT(Encrypted_Area_Code USING ascii) AS Encrypted_Area_Code
FROM 
    US_Household_Income;
--  Hiển thị được đoạn text sau khi Zip_Code và Area_Code được mã hóa
/*  Ví dụ dòng đầu tiên:
		City= Robertsdale
		State_Name = Alabama
        Zip_Code   = 36567
        Area_Code  = 251
		Encrypted_Zip_Code  = ??[?U\'?3?_?p?
		Encrypted_Area_Code =?PN?-???k?xXE
*/


-- Giải mã
-- dùng hàm AES_DECRYPT để giải mã. SELECT luôn sẽ ra BLOB, cần chuyển nó về dạng văn bản ban đầu 
-- ---> CAST AS CHAR(10)
SELECT 
    City,
    State_Name,
    Zip_Code,
    Area_Code,
    CONVERT(Encrypted_Zip_Code USING ascii) AS Encrypted_Zip_Code,
    CONVERT(Encrypted_Area_Code USING ascii) AS Encrypted_Area_Code,
    CAST(AES_DECRYPT(Encrypted_Zip_Code , @encryption_key) AS CHAR(10)) AS Decrypted_Zip_Code,
    CAST(AES_DECRYPT(Encrypted_Area_Code, @encryption_key) AS CHAR(10)) AS Decrypted_Area_Code
FROM 
    US_Household_Income;
--  Hiển thị được đoạn text sau giải mã y hệt cột gốc ban đầu
/*  Ví dụ dòng đầu tiên:
		City= Robertsdale
		State_Name = Alabama
        Zip_Code   = 36567
        Area_Code  = 251
        
		Encrypted_Zip_Code  = ??[?U\'?3?_?p?
		Encrypted_Area_Code = ?PN?-???k?xXE
        
        Decrypted_Zip_Code  = 36567
        Decrypted_Area_Code = 251
*/




/* =====================================================================================================================================================================================================================
EDA TASK 19: Geospatial Analysis 
TẠO stored procedure
INPUT : tọa độ, bán kính
OUTPUT: địa điểm trong phạm vi hình tròn: city name, state name, county  AND  khoảng cách với điểm cho trước

Công thức tính khoảng cách địa lý: 
https://stackoverflow.com/questions/5031268/algorithm-to-find-all-latitude-longitude-locations-within-a-certain-distance-fro/5045027#5045027
*/

DELIMITER $$

CREATE PROCEDURE Geospatial_Analysis(latitude FLOAT, longitude FLOAT, radius_km FLOAT)
BEGIN
	-- cte_distance_km sẽ ra danh sách các City, State_Name, County trùng lặp nhau với khoảng cách khác nhau
    -- nhưng em chỉ muốn biết từ tọa độ cho trước --> thành phố đó, khoảng cách GẦN NHẤT là bao xa ?
	WITH cte_rank_distance_km AS ( 
    
			WITH cte_distance_km AS (
				SELECT 
					City, 
					State_Name, 
					County, 
					6371 * 2 * ASIN(SQRT(
										POWER(SIN((latitude - Lat) * pi()/180 / 2), 2) + 
										COS(latitude * pi()/180 ) * COS(abs(Lat) * pi()/180) * 
										POWER(SIN((longitude - Lon) * pi()/180 / 2), 2) 
					)) AS `distance_km`
				FROM 
					us_household_income
			)
			SELECT *,
				ROW_NUMBER() OVER(PARTITION BY State_Name, County, City ORDER BY `distance_km`) `rank_`
			FROM cte_distance_km
			WHERE 
				distance_km <= radius_km
	)
	SELECT 
		City, 
		State_Name, 
		County,
		ROUND( distance_km, 4 ) AS `ROUND_distance_km`
	FROM cte_rank_distance_km
	WHERE `rank_` = 1 
	;
END $$

DELIMITER ;

-- CALL `finalproject`.`Geospatial_Analysis`(<{latitude FLOAT}>, <{longitude FLOAT}>, <{radius_km FLOAT}>);
-- Cho trước tọa độ ( vĩ độ = 30,  kinh độ = -100 ). Xác định các City quanh bán kính 100 km
CALL Geospatial_Analysis(30, -100, 100) ;
-- Result (10 rows): Tìm thấy 10 thành phố.



/* =====================================================================================================================================================================================================================
EDA TASK 20: Analyzing Correlations
Correlation between land area (ALand) and water area (AWater) for each state
r = (n*sumXY - sumX*sumY)/ SQRT{(n*sumX^2 - (sumX)^2)*(n*sumY^2 - (sumY)^2)}
Kích thước số quá lớn, vượt ra ngoài BIGINT ---> Cùng chia dữ liệu 2 cột cho 10
*/
WITH ste_correl AS (
	SELECT
		State_Name,
		COUNT(*) n,
		sum(ALand/10) sumX,
		sum(AWater/10) sumY,
		sum(ALand/10*AWater/10) sumXY,
		sum(ALand/10*ALand/10) sumX2,
		sum(AWater/10*AWater/10) sumY2
	FROM us_household_income
	GROUP BY State_Name
)
SELECT 
	State_Name, 
	(n*sumXY - sumX*sumY)/ 
    SQRT((n*sumX2 - (sumX)*(sumX))*(n*sumY2 - (sumY)*(sumY))) AS correlation_coefficient
FROM ste_correl
;
-- Result: (52 rows) 52 State và hệ số tương quan ứng với từng State

-- Các hệ số tương quan từ -0.00056(Hawai) -----> 0.9882 (District of Columbia)
-- Ko có tương quan nghịch

-- Bang "District of Columbia"  có giá trị correlation coefficient = 0.9882,
-- thể hiện có hệ số tương quan thuận mạnh mẽ giữa diện tích mặt đất và diện tích mặt nước của riêng bang "District of Columbia".
-- Điều này có nghĩa là ở bang "District of Columbia", các khu vực có diện tích mặt đất cao hơn, có xu hướng có diện tích mặt nước cap hơn.





/* =====================================================================================================================================================================================================================
	EDA TASK 21: Hotspot Detection
	Nơi mà sự kết hợp giữa diện tích đất ALand và diện tích mặt nước AWater khác biệt đáng kể so với tiêu chuẩn 
	Use statistical methods like standard deviation to identify these anomalies.
    Include city name, state name, land area, water area, and the deviation score in your report.
    
	Z = (X - mean(X))/ std   
	Theo phân phối chuẩn tắc, |Z| > 3  tức data nằm ngoài 99.73% tổng thể.
	IDEA: |Z_aland| > 3 OR |Z_awater| > 3 thì là giá trị khác biệt so với tiêu chuẩn.
*/
WITH cte_statistical AS (
	SELECT 
		City,
		State_Name,
		SUM(ALand) AS total_aland,
        SUM(AWater) AS total_awater,
        
		AVG(SUM(ALand)) OVER(PARTITION BY State_Name) AS `mean1`,
		STDDEV(SUM(ALand)) OVER(PARTITION BY State_Name) AS `std1`,
        
		AVG(SUM(AWater)) OVER(PARTITION BY State_Name) AS `mean2`,
		STDDEV(SUM(AWater)) OVER(PARTITION BY State_Name) AS `std2`	
        
	FROM us_household_income 
	GROUP BY State_Name, City
)
SELECT 
	City,
	State_Name, 
	total_aland,
	total_awater,
	ROUND((total_aland - mean1)/ std1 , 2) AS anomaly_Z_score_aland,
    ROUND((total_awater - mean2)/ std2 , 2) AS anomaly_Z_score_awater
FROM  
	cte_statistical
WHERE  
	ABS((total_aland - mean1)/ std1 ) > 3 OR ABS((total_awater - mean2)/ std2 ) > 3
;
-- 369 row(s) returned
-- running time: 0.484 sec / 0.016 sec




/* =====================================================================================================================================================================================================================
-- EDA TASK 22: Resource Allocation Optimization (Tối ưu hóa phân bổ tài nguyên) 
-- Phân bổ nguồn lực (ví dụ: kinh phí) dựa trên diện tích đất và nước của mỗi thành phốWITH RECURSIVE cte_cumulative_sum AS (    SELECT     City,           State_Name,      total_aland,      rank_,      total_aland AS cumulative_sum    FROM    (SELECT      City,     State_Name,     SUM(ALand) AS total_aland,     ROW_NUMBER() OVER(PARTITION BY State_Name ORDER BY City)  AS `rank_`   FROM us_household_income    GROUP BY State_Name, City   ORDER BY State_Name, City                 ) subquery1     WHERE    rank_ = 1       UNION ALL     SELECT    t2.City,         t2.State_Name,     t2.total_aland,    t2.rank_,    (t2.total_aland + t1.cumulative_sum)     FROM    (SELECT      City,     State_Name,     SUM(ALand) AS total_aland,     ROW_NUMBER() OVER(PARTITION BY State_Name ORDER BY City)  AS `rank_`   FROM us_household_income    GROUP BY State_Name, City   ORDER BY State_Name, City                 ) t2             JOIN cte_cumulative_sum t1   ON t2.rank_ = t1.rank_ + 1      AND t2.State_Name = t1.State_Name ) SELECT * FROM cte_cumulative_sum ORDER BY State_Name, City

