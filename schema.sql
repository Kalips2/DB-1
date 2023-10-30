CREATE TABLE "users"
(
    "UserID"        int PRIMARY KEY,
    "Role"          varchar,
    "FirstName"     varchar,
    "LastName"      varchar,
    "Gender"        varchar,
    "DateOfBirth"   date,
    "BloodType"     int,
    "ContactNumber" varchar,
    "Email"         varchar
);

CREATE TABLE "favorite_centers"
(
    "UserID"        int,
    "BloodCenterId" int
);

CREATE TABLE "donation"
(
    "AppointmentID"   int PRIMARY KEY,
    "QuantityDonated" decimal,
    "BloodTypeID"     int,
    "Date"            date
);

CREATE TABLE "transition"
(
    "ID"          int PRIMARY KEY,
    "donationId"  int,
    "BloodBankId" int,
    "status"      varchar
);

CREATE TABLE "donation_offers"
(
    "OfferID"       int PRIMARY KEY,
    "DonorID"       int,
    "OfferedAt"     date,
    "bloodCenterId" int,
    "status"        varchar
);

CREATE TABLE "blood_banks"
(
    "BloodBankID"   int PRIMARY KEY,
    "Name"          varchar,
    "Location"      varchar,
    "ContactNumber" varchar,
    "Email"         varchar
);

CREATE TABLE "blood_bank_requests"
(
    "ID"          int PRIMARY KEY,
    "BloodBankID" int,
    "BloodTypeID" int,
    "Quantity"    decimal,
    "CreatedAt"   date,
    "DueTo"       date
);

CREATE TABLE "blood_centers"
(
    "CenterId"      int PRIMARY KEY,
    "Name"          varchar,
    "Location"      varchar,
    "ContactNumber" varchar,
    "Email"         varchar
);

CREATE TABLE "blood_types"
(
    "BloodTypeID" int PRIMARY KEY,
    "BloodType"   varchar
);

CREATE TABLE "blood_inventory"
(
    "ID"          int PRIMARY KEY,
    "BloodBankID" int,
    "BloodTypeID" int,
    "Quantity"    decimal
);

CREATE TABLE "appointments"
(
    "AppointmentID" int PRIMARY KEY,
    "EventID"       int,
    "OfferID"       int,
    "BloodCenterId" int,
    "BloodTypeID"   int,
    "ScheduledOn"   date,
    "Status"        varchar
);

CREATE TABLE "appointment_feedback"
(
    "FeedbackID" int PRIMARY KEY,
    "donationID" int,
    "Rating"     int,
    "Comments"   text
);

CREATE TABLE "user_restrictions"
(
    "RestrictionID" int PRIMARY KEY,
    "UserID"        int,
    "Reason"        text,
    "ExpiryDate"    date
);

CREATE TABLE "user_documents"
(
    "documentID"  int PRIMARY KEY,
    "UserID"      int,
    "Description" text,
    "File"        varchar
);

CREATE TABLE "events"
(
    "EventID"       int PRIMARY KEY,
    "BloodCenterId" int,
    "EventName"     varchar,
    "EventDate"     date,
    "Description"   text
);

CREATE UNIQUE INDEX ON "favorite_centers" ("UserID", "BloodCenterId");

ALTER TABLE "users"
    ADD FOREIGN KEY ("BloodType") REFERENCES "blood_types" ("BloodTypeID");

ALTER TABLE "favorite_centers"
    ADD FOREIGN KEY ("UserID") REFERENCES "users" ("UserID");

ALTER TABLE "favorite_centers"
    ADD FOREIGN KEY ("BloodCenterId") REFERENCES "blood_centers" ("CenterId");

ALTER TABLE "donation"
    ADD FOREIGN KEY ("AppointmentID") REFERENCES "appointments" ("AppointmentID");

ALTER TABLE "donation"
    ADD FOREIGN KEY ("BloodTypeID") REFERENCES "blood_types" ("BloodTypeID");

ALTER TABLE "transition"
    ADD FOREIGN KEY ("donationId") REFERENCES "donation" ("AppointmentID");

ALTER TABLE "transition"
    ADD FOREIGN KEY ("BloodBankId") REFERENCES "blood_banks" ("BloodBankID");

ALTER TABLE "donation_offers"
    ADD FOREIGN KEY ("DonorID") REFERENCES "users" ("UserID");

ALTER TABLE "donation_offers"
    ADD FOREIGN KEY ("bloodCenterId") REFERENCES "blood_centers" ("CenterId");

ALTER TABLE "blood_bank_requests"
    ADD FOREIGN KEY ("BloodBankID") REFERENCES "blood_banks" ("BloodBankID");

ALTER TABLE "blood_bank_requests"
    ADD FOREIGN KEY ("BloodTypeID") REFERENCES "blood_types" ("BloodTypeID");

ALTER TABLE "blood_inventory"
    ADD FOREIGN KEY ("BloodBankID") REFERENCES "blood_banks" ("BloodBankID");

ALTER TABLE "blood_inventory"
    ADD FOREIGN KEY ("BloodTypeID") REFERENCES "blood_types" ("BloodTypeID");

ALTER TABLE "appointments"
    ADD FOREIGN KEY ("EventID") REFERENCES "events" ("EventID");

ALTER TABLE "appointments"
    ADD FOREIGN KEY ("OfferID") REFERENCES "donation_offers" ("OfferID");

ALTER TABLE "appointments"
    ADD FOREIGN KEY ("BloodCenterId") REFERENCES "blood_centers" ("CenterId");

ALTER TABLE "appointments"
    ADD FOREIGN KEY ("BloodTypeID") REFERENCES "blood_types" ("BloodTypeID");

ALTER TABLE "appointment_feedback"
    ADD FOREIGN KEY ("donationID") REFERENCES "appointments" ("AppointmentID");

ALTER TABLE "user_restrictions"
    ADD FOREIGN KEY ("UserID") REFERENCES "users" ("UserID");

ALTER TABLE "user_documents"
    ADD FOREIGN KEY ("UserID") REFERENCES "users" ("UserID");

ALTER TABLE "events"
    ADD FOREIGN KEY ("BloodCenterId") REFERENCES "blood_centers" ("CenterId");

-- 1. Function to get Blood Type of user:

CREATE OR REPLACE FUNCTION get_blood_type(user_id int)
    RETURNS varchar AS
$$
DECLARE
    blood_type varchar;
BEGIN
    SELECT bt."BloodType"
    INTO blood_type
    FROM users u
             JOIN blood_types bt ON u."BloodType" = bt."BloodTypeID"
    WHERE u."UserID" = user_id;
    RETURN blood_type;
END;
$$ LANGUAGE plpgsql;

-- 2. Function + Trigger: Update Blood Inventory on Transition Status DONE:

CREATE OR REPLACE FUNCTION update_blood_inventory_on_done_transition()
    RETURNS TRIGGER AS
$$
DECLARE
    blood_bank_id INT;
    blood_type_id INT;
BEGIN
    IF NEW.status = 'DONE' THEN
        -- Get Blood Bank ID and Blood Type ID associated with the donation
        SELECT a."BloodCenterId", d."BloodTypeID"
        INTO blood_bank_id, blood_type_id
        FROM appointments a
                 JOIN donation d ON a."AppointmentID" = d."AppointmentID"
        WHERE d."AppointmentID" = NEW.donationId;

        -- Update Blood Inventory
        UPDATE blood_inventory
        SET "Quantity" = blood_inventory."Quantity" + (SELECT donation."QuantityDonated"
                                                       FROM donation
                                                       WHERE donation."AppointmentID" = NEW.donationId)
        WHERE blood_inventory."BloodBankID" = blood_bank_id
          AND blood_inventory."BloodTypeID" = blood_type_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_blood_inventory_on_done_transition_trigger
    AFTER INSERT OR UPDATE
    ON transition
    FOR EACH ROW
EXECUTE FUNCTION update_blood_inventory_on_done_transition();

-- 3. Function + Trigger: Create new appointment on donation offer status APPROVED

CREATE OR REPLACE FUNCTION create_appointment_on_approved_offer()
    RETURNS TRIGGER AS
$$
DECLARE
    new_appointment_id int;
BEGIN
    IF NEW.status = 'APPROVED' THEN
        INSERT INTO appointments ("OfferID", "BloodCenterId", "BloodTypeID", "ScheduledOn", "Status")
        -- Current date doesn't make sense, just try to play with triggers.
        VALUES (NEW.OfferID, NEW.bloodCenterId, NULL, current_date, 'Scheduled')
        RETURNING "AppointmentID" INTO new_appointment_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_appointment_on_approved_offer_trigger
    AFTER INSERT
    ON donation_offers
    FOR EACH ROW
EXECUTE FUNCTION create_appointment_on_approved_offer();


-- 4. Function get user age

CREATE OR REPLACE FUNCTION get_user_age(date_of_birth date)
    RETURNS integer AS
$$
DECLARE
    age integer;
BEGIN
    SELECT EXTRACT(year FROM age(current_date, date_of_birth)) INTO age;
    RETURN age;
END;
$$ LANGUAGE plpgsql;

-- Procedures:

CREATE OR REPLACE PROCEDURE update_blood_inventory(blood_bank_id int, blood_type_id int, quantity decimal)
AS
$$
BEGIN
    UPDATE blood_inventory
    SET "Quantity" = Quantity + quantity
    WHERE "BloodBankID" = blood_bank_id
      AND "BloodTypeID" = blood_type_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE update_user_restrictions(restriction_id int, user_id int, reason text, expiry_date date)
AS
$$
BEGIN
    UPDATE user_restrictions
    SET "UserID"     = user_id,
        "Reason"     = reason,
        "ExpiryDate" = expiry_date
    WHERE "RestrictionID" = restriction_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE calculate_total_blood_for_type(blood_type_id int, OUT total_quantity decimal)
AS
$$
DECLARE
    total         decimal := 0;
    blood_bank_id int;
BEGIN
    FOR blood_bank_id IN (SELECT DISTINCT "BloodBankID" FROM blood_inventory)
        LOOP
            SELECT COALESCE(SUM("Quantity"), 0)
            INTO total
            FROM blood_inventory
            WHERE "BloodTypeID" = blood_type_id
              AND "BloodBankID" = blood_bank_id;
        END LOOP;

    SELECT total
    INTO total_quantity;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE update_blood_bank_info(
    blood_bank_id int,
    new_name varchar,
    new_location varchar,
    new_contact_number varchar,
    new_email varchar
)
AS
$$
BEGIN
    UPDATE blood_banks
    SET "Name"          = new_name,
        "Location"      = new_location,
        "ContactNumber" = new_contact_number,
        "Email"         = new_email
    WHERE "BloodBankID" = blood_bank_id;
END;
$$ LANGUAGE plpgsql;













