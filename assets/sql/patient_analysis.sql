-- exporitory analysis: patients info 

select count(*)
from patients; 

-- count the number of deaths
select 
	count(deathdate) as death
from patients
where DEATHDATE <> '';
    


-- count number of addmition per patients
-- gives a code of 0 for admitted once, 1 for multiple admittions
select 
	CASE 
		when count(PATIENT) > 1 then 1
		else 0
	end as readmitted
from encounters
group by PATIENT;



-- count the number of patients are readdmitted
select 
	sum(readmitted) as readmitted
	-- sub query: if a patient was readmitted more than once, give them a value of 1, else 0
from
(	
	SELECT 
		CASE
			when count(patient) > 1 then 1
			else 0
		end as readmitted
	from encounters
	group by patient
) as sq;


-- average age
-- patients who are not dead, sum(days: current day - day born)
select round(sum(total_days) / sum(num_curr_patients) / 365.25) as average_age
from (
	select 
		case
			when deathdate is null then datediff(curdate(), birthdate)
			else 0
		end as total_days, 
		sum(
			case 
				when deathdate is null then 1
				else 0
			end
		) as num_curr_patients
	from patients
	group by total_days
    ) as sq;

-- calculate average using avg function (differnt from above this is probably right)
select avg(datediff(curdate(), birthdate)) /365.25 as avg_age
from patients
where deathdate is null;


-- list of alive patients age ordered by age
	select 
		case
			when deathdate is null then round( datediff(curdate(), birthdate) / 365.25 )
			else 0
		end as age
	from patients
    where deathdate is null
    order by age;

select count(*) from patients where deathdate is null;

-- index of the middle of patients alive age    
SELECT FLOOR(COUNT(*) / 2) - 1
	FROM patients
	WHERE deathdate IS NULL;
    
-- calcualtes the median age
SELECT round(AVG(age)) AS median_age
FROM (
    SELECT 
        CASE
            WHEN deathdate IS NULL THEN round(DATEDIFF(CURDATE(), birthdate) / 365.25)
            ELSE 0
        END AS age
    FROM patients
    WHERE deathdate IS NULL
    ORDER BY age
    limit 0, 409 -- hard code for the middle. I cannot figure out how to make it dynamic
) AS median_result;



-- select durration for each encoutner in hours
select 
	timestampdiff(minute, start, stop)/60 as durration_hours
from encounters
order by durration_hours desc;

-- average stay duration hours per encounter
select 
	avg( timestampdiff(minute, start, stop)/60 ) as avg_durration_hours
from encounters
order by avg_durration_hours desc;


-- average stay per patient 
-- for each patient, count the number of hours stayed and add i, then divide by the number of encounters per patient (group by patient id)
select 
	avg(total_durration_hours / num_encounters) as avg_hour_per_patient
    from (
		select
			patient, 
			sum(timestampdiff(minute, start, stop) )/60 as total_durration_hours,
			count(patient) as num_encounters
		from encounters
		group by patient
		order by num_encounters asc
) as sub;



-- avrage cost per visit 
select round( avg(TOTAL_CLAIM_COST) ) as avg_cost
from encounters;

-- total encounter cost
select round( sum(TOTAL_CLAIM_COST) / 1000000) as avg_cost_million
from encounters;

-- average cost per patient
-- group by patient id, avg cost
select round( avg( cost_patient ) ) as avg_cost
from (
	select patient, sum(TOTAL_CLAIM_COST) as cost_patient
	from encounters
	group by patient
) AS sq_cost;



-- out of pocket cost per patient
select round( avg(cost) ) as avg_cost_not_insurance
from (
	select 
		sum(total_claim_cost) - sum(payer_coverage) as cost
	from encounters
	group by patient
) as sq_cost;

-- avg insurance payment per person
select round( avg(cost) ) as avg_cost_insurance
from (
	select 
		sum(payer_coverage) as cost
	from encounters
	group by patient
) as sq_cost;

-- avg insurance payment per encounter
select round( avg(payer_coverage) ) as avg_encounter_insurance
from encounters;

-- avg out of pocket per encounter
select round( avg(total_claim_cost - payer_coverage) ) as avg_encounter_insurance
from encounters;


-- number of patients without insureance
select
	count(distinct patient)
from encounters 
where payer = 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76'; -- no insurance

-- number of patients with insureance
select
	count(distinct patient)
from encounters 
where payer <> 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76'; -- no insurance

-- red flag. There are duplicate entries in the encounters table.
-- here is a list of duplicates. it makes sense for 1 encounter to have multiple procedures not vice versa
-- assumption (returning patients lost their insurance or gained insurance)
select 
	start, stop, patient, count(*)
from encounters
group by start, stop, patient
having count(*) > 1;

-- red flag. There are duplicate entries in the procedures table.
-- here is a list of duplicates. does this mean the patient had multiple procedures??
select 
	start, stop, patient, count(*)
from procedures
group by start, stop, patient
having count(*) > 1;




-- count procedures coverd by insurance
-- want to join procedures with the subquery
select round( sum(total_cost) )
from procedures
inner join (
	-- procedure has an encounter id that i can use to get the insurance info using join
	select encounters.id as encounter_id, encounters.total_claim_cost as total_cost,encounters.PAYER_COVERAGE as insurance_cost, encounters.patient, encounters.payer, payers.name as insurance_name
	from encounters
	inner join payers
	on encounters.payer = payers.id
) as sub
on procedures.encounter = sub.encounter_id;

-- procedure cost covered by insurance
select 
	round( sum(encounters.payer_coverage) ) as total_insurance_coverage,
	round( sum(encounters.total_claim_cost) ) as total_cost_procedure,
    round( sum(encounters.payer_coverage) ) / round( sum(encounters.total_claim_cost) )*100 as coverage_percent
from procedures 
join encounters
on procedures.encounter = encounters.id
where procedures.encounter = encounters.id;

select 
	round( sum(encounters.payer_coverage) ) as total_insurance_coverage,
	round( sum(encounters.total_claim_cost) ) as total_cost_procedure,
	round( sum(encounters.payer_coverage) ) / round( sum(encounters.total_claim_cost) )*100 as coverage_percent
from encounters;



-- claim stats (insurance coverage vs cost)
select 
	round( sum(encounters.payer_coverage) ) as total_insurance_coverage,
	round( sum(encounters.total_claim_cost) ) as total_cost_procedure,
    round( sum(encounters.payer_coverage) ) / round( sum(encounters.total_claim_cost) )*100 as coverage_percent
from encounters; 


-- count procedures not covered with insurance
select 
	count(*) as count_not_insured
from encounters
where payer = 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76'; -- no insurance

-- count procedures covered with insurance
select 
	count(*) as count_insured
from encounters
where payer <> 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76'; -- no insurance
 

-- % insured (encounters)
select 
	round( sum(payer = 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76') /  count(*) *100 , 1) as percent_uninsured,
    round( sum(payer <> 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76') /  count(*) *100 , 1) as percent_insured
from encounters;


-- % breakdown of encounters
select encounterclass, count(encounterclass), round( count(encounterclass) / (select count(*) from encounters)*100, 1) as percent
from encounters
group by encounterclass
order by percent desc;


-- rank most popular insurer
-- need to join to get insuer name
select 
	case
		when encounters.payer = 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76' then 'No Insurance'
        else payers.name
	end as payer_name,
	count(payer) as count, Round( count(payer) / (select count(*) from encounters)*100, 1) as PERCENT 
from encounters
left join payers on encounters.payer = payers.id
group by payer_name
order by count desc;


-- Insurance payer breakdown
-- use join to get insure names
select payers.name as payer_name, round( sum(payer_coverage) ) as covered, round(sum(total_claim_cost)) as claim_cost, round( sum(payer_coverage) / sum(total_claim_cost)*100 , 1) as percent_covered
from encounters
join payers on encounters.payer = payers.id
group by payer_name
order by percent_covered desc;

-- % of insured patients have to pay out of pocket
select ( sum(total_claim_cost) - sum(payer_coverage) ) / sum(total_claim_cost)*100 as percent_out_of_pocket
from encounters
where payer <> 'b1c428d6-4f07-31e0-90f0-68ffa6ff8c76';
