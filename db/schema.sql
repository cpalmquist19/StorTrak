-- StorTrak db
-- GH 2006
-- run this against the stortrak db. drops everything first!!

-- facilitys (3 right now - main, 29 north, the old mill one)
-- GH 2/06
DROP TABLE IF EXISTS tblFacility;
CREATE TABLE tblFacility (
    FacID INT NOT NULL AUTO_INCREMENT,
    FacNm VARCHAR(50),
    Addr VARCHAR(100),
    Ph VARCHAR(20),
    TaxRt DECIMAL(6,4),
    PRIMARY KEY (FacID)
);

-- units
-- utype: 1=standard 2=drive-up 3=climate (CCU) 4=parking
-- stat: 1=vacant 2=rented 3=reserved 4=damaged 5=company use
--       6=overlocked 7=lien 8=auction pending 9=unknown/legacy
-- 9 is for the stuff from the old access db that didnt match - GH
-- sz is like '10x10', '5x10' etc
DROP TABLE IF EXISTS units;
CREATE TABLE units (
    unit_id INT NOT NULL AUTO_INCREMENT,
    fac INT,
    unit_no VARCHAR(10),
    sz VARCHAR(10),
    utype TINYINT,
    stat TINYINT,
    PRIMARY KEY (unit_id)
);

-- tenants
-- ugc = gate code for the keypad
-- GH 3/06
DROP TABLE IF EXISTS tenant;
CREATE TABLE tenant (
    TenantID INT NOT NULL AUTO_INCREMENT,
    fname VARCHAR(50),
    lname VARCHAR(50),
    ph1 VARCHAR(20),
    ph2 VARCHAR(60),  -- widened, ppl putting emails in here. RJ 8/19
    email VARCHAR(100),
    addr1 VARCHAR(100),
    city VARCHAR(50),
    st CHAR(2),
    zip VARCHAR(10),
    ugc VARCHAR(10),
    dt_added DATETIME,
    PRIMARY KEY (TenantID)
);

-- rental = one tenant in one unit
-- tid = tenant.TenantID
-- pdt = paid thru date
-- moveout_dt null til they leave
DROP TABLE IF EXISTS rental;
CREATE TABLE rental (
    rid INT NOT NULL AUTO_INCREMENT,
    tid INT,
    unit_id INT,
    movein_dt DATE,
    moveout_dt DATE NULL,
    pdt VARCHAR(20),
    rnt_amt FLOAT,
    dep_amt FLOAT,
    PRIMARY KEY (rid)
);

-- ledger. every charge/payment goes here
-- typ: R=rent L=late fee P=payment D=deposit A=adjustment X=void
-- usr = who did it (users.uname)
-- GH 3/06
DROP TABLE IF EXISTS ledger;
CREATE TABLE ledger (
    lid INT NOT NULL AUTO_INCREMENT,
    rid INT,
    typ CHAR(1),
    amt FLOAT,
    dt DATETIME,
    memo VARCHAR(255),
    usr VARCHAR(20),
    PRIMARY KEY (lid)
);

-- payments
-- method = CASH, CHECK, CC, MO
-- only keep last 4 of card!! - GH
DROP TABLE IF EXISTS payment;
CREATE TABLE payment (
    pmt_id INT NOT NULL AUTO_INCREMENT,
    rid INT,
    amt FLOAT,
    method VARCHAR(10),
    chk_no VARCHAR(20),
    cc_last4 VARCHAR(4),
    dt DATETIME,
    usr VARCHAR(20),
    PRIMARY KEY (pmt_id)
);

-- liens
-- 7 = in lien but on a payment plan
-- GH 4/06
DROP TABLE IF EXISTS lien;
CREATE TABLE lien (
    lien_id INT NOT NULL AUTO_INCREMENT,
    rid INT,
    lnstat TINYINT,
    notice1_dt DATE,
    notice2_dt DATE,
    sale_dt DATE,
    sale_amt FLOAT,
    PRIMARY KEY (lien_id)
);

-- street rates by fac/size/type
-- rate_old = what it was before the last increase
DROP TABLE IF EXISTS rates;
CREATE TABLE rates (
    fac INT,
    sz VARCHAR(10),
    utype TINYINT,
    mo_rate DECIMAL(8,2),
    rate_old DECIMAL(8,2)
);

-- misc settings
-- GRACE='5' LATEFEE='15' LATEPCT='10' TAXRT='0.0725'
DROP TABLE IF EXISTS settings;
CREATE TABLE settings (
    k VARCHAR(50) NOT NULL,
    v VARCHAR(255),
    PRIMARY KEY (k)
);

-- users for login
-- pw is md5
-- lvl 9 = admin, everybody else 1 for now
-- GH 2/06
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    uid INT NOT NULL AUTO_INCREMENT,
    uname VARCHAR(20),
    pw VARCHAR(32),
    lvl TINYINT,
    fname VARCHAR(50),
    PRIMARY KEY (uid)
);
