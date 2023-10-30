CREATE TABLE "Users" (
  "UserID" int PRIMARY KEY,
  "Role" varchar,
  "FirstName" varchar,
  "LastName" varchar,
  "Gender" varchar,
  "DateOfBirth" date,
  "BloodType" int,
  "ContactNumber" varchar,
  "Email" varchar
);

CREATE TABLE "FavoriteCenters" (
  "UserID" int,
  "BloodCenterId" int
);

CREATE TABLE "Donation" (
  "AppointmentID" int PRIMARY KEY,
  "QuantityDonated" decimal,
  "BloodTypeID" int,
  "Date" date
);

CREATE TABLE "Transition" (
  "ID" int PRIMARY KEY,
  "DonationId" int,
  "BloodBankId" int,
  "status" varchar
);

CREATE TABLE "DonationOffers" (
  "OfferID" int PRIMARY KEY,
  "DonorID" int,
  "OfferedAt" date,
  "bloodCenterId" int,
  "status" varchar
);

CREATE TABLE "BloodBanks" (
  "BloodBankID" int PRIMARY KEY,
  "Name" varchar,
  "Location" varchar,
  "ContactNumber" varchar,
  "Email" varchar
);

CREATE TABLE "BloodBankRequests" (
  "ID" int PRIMARY KEY,
  "BloodBankID" int,
  "BloodTypeID" int,
  "Quantity" decimal,
  "CreatedAt" date,
  "DueTo" date
);

CREATE TABLE "BloodCenters" (
  "CenterId" int PRIMARY KEY,
  "Name" varchar,
  "Location" varchar,
  "ContactNumber" varchar,
  "Email" varchar
);

CREATE TABLE "BloodTypes" (
  "BloodTypeID" int PRIMARY KEY,
  "BloodType" varchar
);

CREATE TABLE "BloodInventory" (
  "ID" int PRIMARY KEY,
  "BloodBankID" int,
  "BloodTypeID" int,
  "Quantity" decimal
);

CREATE TABLE "Appointments" (
  "AppointmentID" int PRIMARY KEY,
  "EventID" int,
  "OfferID" int,
  "BloodCenterId" int,
  "BloodTypeID" int,
  "ScheduledOn" date,
  "Status" varchar
);

CREATE TABLE "AppointmentFeedback" (
  "FeedbackID" int PRIMARY KEY,
  "DonationID" int,
  "Rating" int,
  "Comments" text
);

CREATE TABLE "UserRestrictions" (
  "RestrictionID" int PRIMARY KEY,
  "UserID" int,
  "Reason" text,
  "ExpiryDate" date
);

CREATE TABLE "UserDocuments" (
  "documentID" int PRIMARY KEY,
  "UserID" int,
  "Description" text,
  "File" string
);

CREATE TABLE "Events" (
  "EventID" int PRIMARY KEY,
  "BloodCenterId" int,
  "EventName" varchar,
  "EventDate" date,
  "Description" text
);

CREATE UNIQUE INDEX ON "FavoriteCenters" ("UserID", "BloodCenterId");

ALTER TABLE "Users" ADD FOREIGN KEY ("BloodType") REFERENCES "BloodTypes" ("BloodTypeID");

ALTER TABLE "FavoriteCenters" ADD FOREIGN KEY ("UserID") REFERENCES "Users" ("UserID");

ALTER TABLE "FavoriteCenters" ADD FOREIGN KEY ("BloodCenterId") REFERENCES "BloodCenters" ("CenterId");

ALTER TABLE "Donation" ADD FOREIGN KEY ("AppointmentID") REFERENCES "Appointments" ("AppointmentID");

ALTER TABLE "Donation" ADD FOREIGN KEY ("BloodTypeID") REFERENCES "BloodTypes" ("BloodTypeID");

ALTER TABLE "Transition" ADD FOREIGN KEY ("DonationId") REFERENCES "Donation" ("AppointmentID");

ALTER TABLE "Transition" ADD FOREIGN KEY ("BloodBankId") REFERENCES "BloodBanks" ("BloodBankID");

ALTER TABLE "DonationOffers" ADD FOREIGN KEY ("DonorID") REFERENCES "Users" ("UserID");

ALTER TABLE "DonationOffers" ADD FOREIGN KEY ("bloodCenterId") REFERENCES "BloodCenters" ("CenterId");

ALTER TABLE "BloodBankRequests" ADD FOREIGN KEY ("BloodBankID") REFERENCES "BloodBanks" ("BloodBankID");

ALTER TABLE "BloodBankRequests" ADD FOREIGN KEY ("BloodTypeID") REFERENCES "BloodTypes" ("BloodTypeID");

ALTER TABLE "BloodInventory" ADD FOREIGN KEY ("BloodBankID") REFERENCES "BloodBanks" ("BloodBankID");

ALTER TABLE "BloodInventory" ADD FOREIGN KEY ("BloodTypeID") REFERENCES "BloodTypes" ("BloodTypeID");

ALTER TABLE "Appointments" ADD FOREIGN KEY ("EventID") REFERENCES "Events" ("EventID");

ALTER TABLE "Appointments" ADD FOREIGN KEY ("OfferID") REFERENCES "DonationOffers" ("OfferID");

ALTER TABLE "Appointments" ADD FOREIGN KEY ("BloodCenterId") REFERENCES "BloodCenters" ("CenterId");

ALTER TABLE "Appointments" ADD FOREIGN KEY ("BloodTypeID") REFERENCES "BloodTypes" ("BloodTypeID");

ALTER TABLE "AppointmentFeedback" ADD FOREIGN KEY ("DonationID") REFERENCES "Appointments" ("AppointmentID");

ALTER TABLE "UserRestrictions" ADD FOREIGN KEY ("UserID") REFERENCES "Users" ("UserID");

ALTER TABLE "UserDocuments" ADD FOREIGN KEY ("UserID") REFERENCES "Users" ("UserID");

ALTER TABLE "Events" ADD FOREIGN KEY ("BloodCenterId") REFERENCES "BloodCenters" ("CenterId");
