 -- For each property, report the highest price ever charged for a week
 -- renting that property, the lowest price, and the range (the difference
 -- between the highest and lowest). Include a column that has a star in it
 -- for the property/properties with the highest range and a blank for the
 -- other properties. There must be at least 10 properties in the result.



SET SEARCH_PATH TO VacationSchema;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5(
   property_id SERIAL,
   max_price DECIMAL(10, 2),
   min_price DECIMAL(10, 2),
   range DECIMAL(10, 2),
   largest_range VARCHAR(100)
);


-- views

-- Each property gets a star in the column 'largest_range'
CREATE VIEW StarTable AS 
	SELECT DISTINCT property_id, '*' as largest_range
	FROM RentalPeriod
;

-- The maximum price, minimum price, and range of each property
CREATE VIEW MaxMinRange AS 
	SELECT R.property_id, max(P.property_price) as max_price, min(P.property_price) as min_price,
		max(P.property_price) - min(P.property_price) as range
	FROM WeeklyPrices P JOIN RentalPeriod R ON P.rental_id = R.rental_id
	GROUP BY R.property_id
;


-- The largest range(s) over all properties
CREATE VIEW LargestRanges AS
	SELECT MMR1.property_id, MMR1.range as largest_range
	FROM MaxMinRange MMR1
	WHERE MMR1.range >= ALL (
		SELECT MMR2.range 
		FROM MaxMinRange MMR2)
;

-- The properties with the largest range(s) get a star
CREATE VIEW LargestRangesStar AS 
	SELECT LR.property_id, ST.largest_range
	FROM LargestRanges LR JOIN StarTable ST ON LR.property_id = ST.property_id
;


INSERT INTO q5
	SELECT MMR.property_id, MMR.max_price, MMR.min_price, MMR.range, LRS.largest_range
	FROM MaxMinRange MMR LEFT JOIN LargestRangesStar LRS
		ON MMR.property_id = LRS.property_id
	ORDER BY MMR.property_id -- don't have to but to see
;




