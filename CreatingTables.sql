CREATE TABLE lead_data_dump (
    id VARCHAR(50) PRIMARY KEY,
    extracted_phone VARCHAR(15),
    full_name VARCHAR(100),
    created_time TIMESTAMP,
    modified_time TIMESTAMP,
    lead_source VARCHAR(50),
    utm_source VARCHAR(50),
    utm_campaign VARCHAR(50),
    utm_adset VARCHAR(50),
    utm_content VARCHAR(50),
    owner_name VARCHAR(100),
    lead_status VARCHAR(100),
    new_lead_status VARCHAR(100),
    age INT,
    BMI DECIMAL(5, 2),
    pre_existing_conditions TEXT,
    affluence VARCHAR(50),
    gender VARCHAR(10),
    lead_quality1 VARCHAR(50),
    BMI2 DECIMAL(5, 2)
);


CREATE TABLE Owner_role_mapping (
	Owner_name VARCHAR(100),
	Owner_role VARCHAR(100)
);


CREATE TABLE Lead_Status_vs_Lead_Stage (
	lead_status VARCHAR(100),
	Junk BOOLEAN,
	Not_Eligible BOOLEAN,
	Connected BOOLEAN,
	Pitch_scheduled BOOLEAN,
	Pitch_completed BOOLEAN,
	Payment_link_sent BOOLEAN,
	Converted BOOLEAN,
	Prospect_Dead BOOLEAN,
	Cross_Consultation BOOLEAN,
	Document_Promised BOOLEAN,
	Document_Recieved BOOLEAN
);