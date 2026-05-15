-- A rental is considered to be “at capacity” if it involves a group of guests (including the renter themself) that
-- is big enough to reach the capacity of the property. Report the average property rating for at-capacity rentals,
-- as well as the number of such rentals. Do the same for rentals that were below capacity. There must be at
-- least 20 at-capacity rentals and at least 20 below-capacity rentals.

SET SEARCH_PATH TO VacationSchema;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2(
  capacity_status TEXT,
  num_rentals INTEGER,
  avg_property_rating INTEGER
);

-- views

-- This view reports the average property rating for at-capacity and below-capacity rentals

CREATE VIEW RatedRentalCapacityStatus AS
WITH RentalGuestCounts AS (
  -- Calculate total guests (guests + 1 for the renter) for each rental
  SELECT
    RP.rental_id,
    RP.property_id,
    (
      SELECT COUNT(RG.guest_id)
      FROM RentalGuests RG
      WHERE RG.rental_id = RP.rental_id
    ) + 1 AS total_guests
  FROM RentalPeriod RP
)
SELECT
  RGC.rental_id,
  PR.property_rating,
  CASE
    -- Check if total guests equals property capacity
    WHEN RGC.total_guests = P.capacity THEN 'at-capacity'
    -- Check if total guests is less than property capacity
    WHEN RGC.total_guests < P.capacity THEN 'below-capacity'
  END AS capacity_status
FROM RentalGuestCounts RGC
JOIN Property P
  ON RGC.property_id = P.property_id
JOIN PropertyRating PR
  ON RGC.rental_id = PR.rental_id;



-- Calculating capacity status for all rentals, not just the ones with ratings
-- to get the number of below- and at-capacity rentals

CREATE VIEW AllCapacityStatus AS
WITH RentalGuestCounts AS (
  -- Calculate total guests (guests + 1 for the renter) for each rental
  SELECT
    RP.rental_id,
    RP.property_id,
    (
      SELECT COUNT(RG.guest_id)
      FROM RentalGuests RG
      WHERE RG.rental_id = RP.rental_id
    ) + 1 AS total_guests
  FROM RentalPeriod RP
)
SELECT
  RGC.rental_id,
  CASE
    -- Check if total guests equals property capacity
    WHEN RGC.total_guests = P.capacity THEN 'at-capacity'
    -- Check if total guests is less than property capacity
    WHEN RGC.total_guests < P.capacity THEN 'below-capacity'
  END AS capacity_status
FROM RentalGuestCounts RGC
JOIN Property P
  ON RGC.property_id = P.property_id;



INSERT INTO q2
SELECT
  ACS.capacity_status,
  COUNT(DISTINCT(ACS.rental_id)) AS num_rentals, 
  ROUND(CAST(AVG(PR.property_rating) AS NUMERIC), 2) AS avg_property_rating 
FROM
  AllCapacityStatus AS ACS
LEFT JOIN
  PropertyRating AS PR
  ON ACS.rental_id = PR.rental_id
WHERE
  ACS.capacity_status IS NOT NULL
GROUP BY
  ACS.capacity_status;

  