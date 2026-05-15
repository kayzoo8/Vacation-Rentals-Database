-- For each type of luxury (hot tub etc.), report the number of properties that offer that luxury.


SET SEARCH_PATH TO VacationSchema;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1(
   luxury_type luxury_type,
   num_of_properties INTEGER
);


INSERT INTO q1
	SELECT luxury_type, COUNT(property_id) AS num_of_properties
	FROM LuxuryType
	GROUP BY
  		luxury_type
	ORDER BY
  		num_of_properties DESC;

