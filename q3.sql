-- Find the host/hosts with the highest average host rating. Report
-- their email address, number of host ratings, average host rating,
-- and the price for the most expensive booking week they have ever
-- recorded. There must be at least 2 hosts in the result, and each
-- of them must have at least 10 host ratings.


SET SEARCH_PATH TO VacationSchema;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3(
   host SERIAL,
   email_address TEXT,
   num_ratings INTEGER,
   avg_rating FLOAT,
   price DECIMAL(10, 2)
);

-- views

-- The host, their email address, and all their host ratings.
CREATE VIEW HostRatings AS
	SELECT H.host_id, H.email_address, HR.host_rating
	FROM Host H JOIN Property P ON H.host_id = P.host_id
		JOIN RentalPeriod RP ON P.property_id = RP.property_id
		JOIN HostRating HR ON RP.rental_id = HR.rental_id
;

-- The host, their email address, how many host ratings they
-- have as num)ratings, and their rating average.
CREATE VIEW NumPerHost AS
SELECT host_id, email_address, count(host_rating) AS num_ratings, 
	avg(host_rating) AS avg_rating
	FROM HostRatings
	GROUP BY host_id, email_address
;

-- The host and the maximum price they charged for their
-- property in a week.
CREATE VIEW HostMaxPrice AS
	SELECT H.host_id, max(WP.property_price) AS price
	FROM Host H JOIN Property P ON H.host_id = P.host_id
		JOIN RentalPeriod RP ON P.property_id = RP.property_id
		JOIN WeeklyPrices WP ON RP.rental_id = WP.rental_id
	GROUP BY H.host_id
;

-- The host and their combined stats.
CREATE VIEW HostStats AS
	SELECT NPH.host_id, NPH.email_address, NPH.num_ratings, NPH.avg_rating, HMP.price
	FROM NumPerHost NPH JOIN HostMaxPrice HMP ON NPH.host_id = HMP.host_id
;


INSERT INTO q3
	SELECT host_id, email_address, num_ratings, avg_rating, price
	FROM HostStats
	WHERE avg_rating = (
		SELECT max(avg_rating) 
		FROM HostStats)
;



