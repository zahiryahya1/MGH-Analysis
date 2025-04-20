-- script to clean the datetimes and column name
-- update string to datetime
UPDATE encounters
SET  Stop = STR_TO_DATE(stop, '%Y-%m-%dT%H:%i:%sZ');

update patients
set birthdate = STR_TO_DATE(birthdate, '%Y-%m-%dT%H:%i:%sZ');

update patients
set deathdate = 
	case 
		when deathdate = '' then null
		else STR_TO_DATE(deathdate, '%Y-%m-%d')
	end;


UPDATE procedures
SET  start = STR_TO_DATE(start, '%Y-%m-%dT%H:%i:%sZ');

UPDATE procedures
SET  stop = STR_TO_DATE(stop, '%Y-%m-%dT%H:%i:%sZ');

-- clean the column name with weird character
ALTER TABLE procedures CHANGE `ï»¿START` `START` TEXT;
ALTER TABLE encounters CHANGE `ï»¿Id` `Id` TEXT;
ALTER TABLE organizations CHANGE `ï»¿Id` `Id` TEXT;
ALTER TABLE patients CHANGE `ï»¿Id` `Id` TEXT;
ALTER TABLE payers CHANGE `ï»¿Id` `Id` TEXT;



