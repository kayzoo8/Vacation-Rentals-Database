 -- For each type (city property, water property, and other) report the 
 -- average number of extra guests (that is, not including the renter 
 -- themself) for properties of that type. Compute the average across
 -- all rentings of that type of property. Each renting should contribute
 -- once to the average, even if it is for multiple weeks. The average
 -- number of extra guests must be non-zero for at least two of the
 -- property types.


SET SEARCH_PATH TO VacationSchema;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4(
   city FLOAT,
   water FLOAT,
   other FLOAT
);


-- views

-- The property IDs of city properties
CREATE VIEW CityProperties AS 
	SELECT CP.city_property_id
	FROM CityProperty CP
;

-- The property IDs of water properties
CREATE VIEW WaterProperties AS 
	SELECT WP.property_id
	FROM WaterProperty WP
;

-- The property IDs of properties that are neither city nor water properties
CREATE VIEW OtherProperties AS 
	SELECT P.property_id
	FROM Property P 
	WHERE P.property_id NOT IN (
		SELECT *
		FROM CityProperties)
		AND P.property_id NOT IN (
			SELECT *
			FROM WaterProperties)
;

-- The average number of extra guests for a city property
CREATE VIEW CityGuests AS 
	SELECT avg(guests_per_rental.guest_count) as city
	FROM (SELECT RP.rental_id, count(Guests.guest_id) as guest_count
			FROM CityProperties CP JOIN RentalPeriod RP ON CP.city_property_id = RP.property_id 
			LEFT JOIN RentalGuests Guests ON RP.rental_id = Guests.rental_id
			GROUP BY RP.rental_id) guests_per_rental
;

-- The average number of extra guests for a water property
CREATE VIEW WaterGuests AS 
	SELECT avg(guests_per_rental.guest_count) as water
	FROM (SELECT RP.rental_id, count(Guests.guest_id) as guest_count
		FROM WaterProperties WP JOIN RentalPeriod RP ON WP.property_id = RP.property_id 
			LEFT JOIN RentalGuests Guests ON RP.rental_id = Guests.rental_id
		GROUP BY RP.rental_id) guests_per_rental
;

-- The average number of extra guests for an 'other' property
CREATE VIEW OtherGuests AS 
	SELECT avg(guests_per_rental.guest_count) as other
	FROM (SELECT RP.rental_id, count(Guests.guest_id) as guest_count
		FROM OtherProperties OP JOIN RentalPeriod RP ON OP.property_id = RP.property_id 
			LEFT JOIN RentalGuests Guests ON RP.rental_id = Guests.rental_id
		GROUP BY RP.rental_id) guests_per_rental
;


INSERT INTO q4
	SELECT
	  COALESCE((SELECT city FROM CityGuests), 0),
	  COALESCE((SELECT water FROM WaterGuests), 0),
	  COALESCE((SELECT other FROM OtherGuests), 0)
;



