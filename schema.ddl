-- Documentation of choices and assumptions

-- Could not:
	-- What constraints from the domain specification could not be enforced 
	-- without using assertions or triggers, if any? (Again, you are not 
	-- writing any assertions or triggers on this assignment.)

		-- We could not enforce that every property that appears in Property 
		-- must also have at least one row in LuxuryProperty. This constraint 
		-- would require a cross-table check or possibly a subquery which is not 
		-- supported by PostGreSQL. We also could not enforce that the renter's 
		-- age on the first day of the rental must be at least 18 years, either 
		-- in RentalPeriod or Renter. The date of birth information is kept in 
		-- Guest, so we would have needed to perform a cross-table check. Another 
		-- constraint we could not enforce is ensuring that the number of guests 
		-- in a property does not exceed its capacity. Based on the way we 
		-- designed these tables, it would again involve cross-table checks 
		-- between RentalPeriod, Property, and RentalGuests. We also could not 
		-- enforce that the host rating must be done by the renter. We originally 
		-- had renter_id as an attribute in host rating, but postgreSQL raised an 
		-- error due to rental_id not being UNIQUE in the RentalPeriod table. 
		-- However, specifying that rental_id should be unique in RentalPeriod 
		-- would mean that a renter_id can only rent a property once, so we 
		-- decided to sacrifice the constraint as the latter statement is more 
		-- reflective of the real world.

-- Did not:
	-- What constraints from the domain specification could have been enforced 
	-- without using assertions or triggers, but were not enforced, if any? Why not?

		-- We possibly could have enforced that the renter must be over 18 if 
		-- we kept the renter's date of birth in Renter and did the check 
		-- constraint in Renter. However, this would possibly introduce redundancy 
		-- as this information is already kept in Guest and renter_id references
		-- guest_id in Guest. We wanted to prioritize avoiding redundancy and 
		-- designing the table in a way that is sensible in the real world.

-- Extra constraints:
	-- What additional constraints that we didn’t mention did you enforce, if any?

		-- We set a constraint on property_price in WeeklyPrices to be a max 
		-- of 8 digits, plus 2 for a decimal value. This attribute represents 
		-- the weekly price of a property. The constraint is directly in the type
		-- definition, where it is represented by DECIMAL(10, 2). Therefore, 
		-- this caps the total weekly rental price at <= $99,999,999.99.

-- Assumptions:
	-- What assumptions did you make? There may be things we didn’t specify 
	-- that you would like to know. In a real design scenario, you would ask 
	-- your client or domain experts. For this assignment, make reasonable 
	-- assumptions and document them here

		-- We assumed that ratings take on integer values between 1 to 5 
		-- inclusive. We also assume that a guest can only leave a single 
		-- comment per rental. We assumed that each property that is rented 
		-- out will have at least one bedroom and 0 or more bathrooms. There 
		-- were some extra constraints not specified by the domain specification 
		-- that we could not enforce, so we assume them for now. For example, 
		-- we will assume that anyone leaving a rating or comment has actually 
		-- stayed at the property. 


DROP SCHEMA IF EXISTS VacationSchema CASCADE;
CREATE SCHEMA VacationSchema;
SET SEARCH_PATH TO VacationSchema;


-- ===================================
-- Hosts
	-- Each row contains the id of the host and the host's email address.
-- ===================================
CREATE TABLE Host (
	host_id SERIAL PRIMARY KEY,
	email_address TEXT NOT NULL
);


-- ===================================
-- Properties
	-- Each row contains the id of the property, the host if of the
	-- property, the number of bedrooms, number of bathrooms, the
	-- capacity, and the address of the property.
-- ===================================

CREATE TABLE Property (
	property_id SERIAL PRIMARY KEY,
	host_id INTEGER NOT NULL REFERENCES Host(host_id),
	num_bedrooms INTEGER NOT NULL CHECK (num_bedrooms > 0),
	num_bathrooms INTEGER NOT NULL CHECK (num_bathrooms >= 0),
	capacity INTEGER NOT NULL CHECK (capacity >= num_bedrooms),
	address VARCHAR(200) NOT NULL
);


-- ===================================
-- City Property
	-- There are 4 transit types: bus, LRT, subway, or none.
	-- Each row represents a city property that has a walkability
	-- score and the closest transit type.
-- ===================================
CREATE TYPE transit_type AS ENUM ('bus', 'LRT', 'subway', 'none');

CREATE TABLE CityProperty (
	city_property_id INTEGER PRIMARY KEY REFERENCES Property(property_id),
	walkability_score INTEGER NOT NULL CHECK (walkability_score >= 0 AND 
		walkability_score <= 100),
	closest_transit_type transit_type NOT NULL
);


-- ===================================
-- Water Property
	-- There are 3 possible bodies of water: beach, lake, or pool.
	-- Each row has a unique water_property_id primary key to allow
	-- for a property to list more than one water type. A row also
	-- contains a property id that references Property, the water type,
	-- and a boolean value for whether lifeguards are offered.
-- ===================================
CREATE TYPE water_type AS ENUM ('beach', 'lake', 'pool');

CREATE TABLE WaterProperty (
	water_property_id SERIAL PRIMARY KEY,
	property_id INTEGER NOT NULL REFERENCES Property(property_id),
	water_type water_type NOT NULL,
	lifeguards_offered BOOLEAN NOT NULL DEFAULT false,
	UNIQUE (property_id, water_type)
);  


-- ===================================
-- Luxury Property
	-- There are 6 luxury types as specified by the domain.
	-- Each row has a lux_id as a primary key to allow a property
	-- to identify multiple luxuries.
-- ===================================
CREATE TYPE luxury_type AS ENUM ('hot tub', 'sauna', 'laundry service', 
	'daily cleaning', 'daily breakfast delivery', 'concierge service');

CREATE TABLE LuxuryType (
	lux_id SERIAL PRIMARY KEY,
	property_id INTEGER NOT NULL REFERENCES Property(property_id),
	luxury_type luxury_type NOT NULL,
	UNIQUE (property_id, luxury_type)
);


-- ===================================
-- Guest
	-- Each row represents a guest where they are identified
	-- by a guest id. The row also stores their name, address,
	-- and date of birth.
-- ===================================
CREATE TABLE Guest (
	guest_id SERIAL PRIMARY KEY,
  	name VARCHAR(100) NOT NULL,
  	address TEXT NOT NULL,
  	date_of_birth DATE NOT NULL
);
  
  
-- ===================================
-- Renter
	-- Each row represents that this specific guest was a renter
	-- for a property/rental period. Renter id references guest id
	-- and their credit card information is also stored.
-- =================================== 
CREATE TABLE Renter ( 
	renter_id SERIAL PRIMARY KEY REFERENCES Guest(guest_id),
	credit_card_num VARCHAR(25) NOT NULL
  );


-- ===================================
-- Rental Period
	-- Each row represents a rental of a property. Uniquely identified
	-- by a rental id, the property and renter are also identified,
	-- the guests' arrival date is tracked with a constraint that it must
	-- be a Saturday (as specified by the domain), and the number of 
	-- weeks that they stay is kept too.
-- ===================================
CREATE TABLE RentalPeriod (
	rental_id SERIAL PRIMARY KEY,
	property_id INTEGER NOT NULL REFERENCES Property(property_id),
	renter_id INTEGER NOT NULL REFERENCES Renter(renter_id),
	arrival_date DATE NOT NULL CHECK (EXTRACT(DOW FROM arrival_date) = 6),
	duration_weeks INTEGER NOT NULL CHECK (duration_weeks > 0)
);



-- ===================================
-- Weekly Prices
	-- Each row represents the price for a week of a specific rental. If 
	-- there is no other row inserted for a given rental_id (i.e., week_num 
	-- is just 1 with no other row for the same rental_id), then we assume that 
	-- the price stays constant for the duration of the stay. This table also
	-- allows the price to change for different weeks of the same rental.
-- ===================================
CREATE TABLE WeeklyPrices (
	weekly_price_id SERIAL PRIMARY KEY,
	rental_id INTEGER NOT NULL REFERENCES RentalPeriod(rental_id),
	week_num INTEGER NOT NULL CHECK (week_num > 0),
	property_price DECIMAL(10, 2) NOT NULL CHECK (property_price >= 0),
	UNIQUE(rental_id, week_num)
);



-- ===================================
-- Rental Guests
	-- Each row represents a guest of a rental. It does not include the renter.
	-- If a rental_id does not appear in this table, then there were no
	-- additional guests.
-- ===================================
CREATE TABLE RentalGuests (
	rental_guest_id SERIAL PRIMARY KEY,
	rental_id INTEGER NOT NULL REFERENCES RentalPeriod(rental_id),
	guest_id INTEGER NOT NULL REFERENCES Guest(guest_id),
	UNIQUE(rental_id, guest_id)
);



-- The possible values of a rating.
DROP DOMAIN IF EXISTS score;
CREATE DOMAIN score AS smallint 
    DEFAULT NULL
    CHECK (VALUE >= 1 AND VALUE <= 5);
 
-- ===================================
-- PropertyRating
	-- Each row represents a rating and/or comment that a guest gave a 
	-- property under a rental_id. The same guest may comment on the same
	-- property if they choose to rent it another time (as rental_id will
	-- be different). A guest can only comment if they have given a rating,
	-- so we allow a potential NULL value here.
-- ===================================   
CREATE TABLE PropertyRating (
	p_rating_id SERIAL PRIMARY KEY,
	rental_id INTEGER NOT NULL REFERENCES RentalPeriod,
  	guest_id INTEGER NOT NULL REFERENCES Guest,
  	property_rating score NOT NULL,
  	comment TEXT,
  	UNIQUE(rental_id, guest_id)
);

-- ===================================
-- HostRating
	-- Each row represents a rating score of a host. The rental id
	-- is included so that a host could be rated multiple times by
	-- possible the same person as long as it's a different stay.
-- ===================================
CREATE TABLE HostRating (
	h_rating_id SERIAL PRIMARY KEY,
	rental_id INTEGER NOT NULL REFERENCES RentalPeriod,
  	host_rating score NOT NULL
);







