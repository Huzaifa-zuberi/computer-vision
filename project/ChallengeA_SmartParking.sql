-- ============================================================
-- Challenge A: Urban Smart-Parking Ecosystem
-- Author: Huzaif Zuberi 
-- Description: DDL + seeded data for smart-parking backend
-- ============================================================

-- ---------------------- DDL --------------------------------

-- Changed table name from ParkingZones1 to ParkingZones to match insert statements
CREATE TABLE ParkingZones (
    ZoneID          INT             NOT NULL IDENTITY(1,1),
    ZoneName        VARCHAR(100)    NOT NULL,
    LocationDesc    VARCHAR(255)    NULL,
    HourlyRate      DECIMAL(5,2)    NOT NULL,
    CONSTRAINT PK_ParkingZones PRIMARY KEY (ZoneID)
);

CREATE TABLE Spots (
    SpotID          INT             NOT NULL IDENTITY(1,1),
    ZoneID          INT             NOT NULL,
    SpotLabel       VARCHAR(20)     NOT NULL,
    SpotType        VARCHAR(20)     NOT NULL,
    IsOccupied      BIT             NOT NULL DEFAULT 0,
    CONSTRAINT PK_Spots PRIMARY KEY (SpotID),
    CONSTRAINT FK_Spots_Zone FOREIGN KEY (ZoneID)
        REFERENCES ParkingZones(ZoneID), -- Updated to reference fixed table name
    CONSTRAINT CK_Spots_SpotType CHECK (
        SpotType IN ('Compact', 'EV', 'Standard')
    )
);

CREATE TABLE Vehicles (
    VehicleID       INT             NOT NULL IDENTITY(1,1),
    LicensePlate    VARCHAR(20)     NOT NULL,
    OwnerName       VARCHAR(100)    NOT NULL,
    VehicleModel    VARCHAR(100)    NULL,
    CONSTRAINT PK_Vehicles PRIMARY KEY (VehicleID),
    CONSTRAINT UQ_Vehicles_LicensePlate UNIQUE (LicensePlate)
);

CREATE TABLE Reservations (
    ReservationID   INT             NOT NULL IDENTITY(1,1),
    SpotID          INT             NOT NULL,
    VehicleID       INT             NOT NULL,
    StartTime       DATETIME2       NOT NULL,
    EndTime         DATETIME2       NOT NULL,
    Status          VARCHAR(20)     NOT NULL DEFAULT 'Active',
    CONSTRAINT PK_Reservations PRIMARY KEY (ReservationID),
    CONSTRAINT FK_Reservations_Spot FOREIGN KEY (SpotID)
        REFERENCES Spots(SpotID),
    CONSTRAINT FK_Reservations_Vehicle FOREIGN KEY (VehicleID)
        REFERENCES Vehicles(VehicleID),
    CONSTRAINT CK_Reservations_TimeRange CHECK (
        EndTime > StartTime
    )
);

CREATE TABLE Infractions (
    InfractionID    INT             NOT NULL IDENTITY(1,1),
    SpotID          INT             NOT NULL,
    VehicleID       INT             NULL,
    IssueTime       DATETIME2       NOT NULL DEFAULT GETDATE(),
    FineAmount      DECIMAL(7,2)    NOT NULL,
    Description     VARCHAR(255)    NULL,
    CONSTRAINT PK_Infractions PRIMARY KEY (InfractionID),
    CONSTRAINT FK_Infractions_Spot FOREIGN KEY (SpotID)
        REFERENCES Spots(SpotID),
    CONSTRAINT FK_Infractions_Vehicle FOREIGN KEY (VehicleID)
        REFERENCES Vehicles(VehicleID)
);

-- ---------------------- DATA SEED -------------------------

BEGIN TRANSACTION;

-- This now correctly matches the table schema name defined above
INSERT INTO ParkingZones (ZoneName, LocationDesc, HourlyRate)
VALUES
    ('Downtown Core', 'Main St & 5th Ave', 3.50),
    ('Hospital Wing', 'City General Hospital', 2.00),
    ('University Lot', 'North Campus Gate', 1.50);

INSERT INTO Spots (ZoneID, SpotLabel, SpotType, IsOccupied)
VALUES
    (1, 'A-01', 'Compact', 0),
    (1, 'A-02', 'Standard', 1),
    (1, 'A-03', 'EV',      0),
    (2, 'B-01', 'Standard', 0),
    (2, 'B-02', 'Standard', 1),
    (3, 'C-01', 'Compact', 0),
    (3, 'C-02', 'EV',      1);

INSERT INTO Vehicles (LicensePlate, OwnerName, VehicleModel)
VALUES
    ('ABC-1234', 'Huzaif Zuberi',   'Toyota Corolla'),
    ('XYZ-5678', 'Sheikh Uzair Ali','Honda Civic'),
    ('DEF-9012', 'Alice Johnson',   'Tesla Model 3');

INSERT INTO Reservations (SpotID, VehicleID, StartTime, EndTime, Status)
VALUES
    (1, 1, '2025-06-01 08:00', '2025-06-01 10:00', 'Active'),
    (4, 2, '2025-06-01 09:00', '2025-06-01 11:30', 'Active'),
    (7, 3, '2025-06-01 07:00', '2025-06-01 09:00', 'Completed');

INSERT INTO Infractions (SpotID, VehicleID, IssueTime, FineAmount, Description)
VALUES
    (2, 1, '2025-06-01 08:15', 25.00, 'Overstayed time limit'),
    (5, 2, '2025-06-01 10:00', 15.00, 'No valid reservation');

COMMIT TRANSACTION;

PRINT 'Challenge A - Smart Parking schema and seed data loaded successfully.';
GO