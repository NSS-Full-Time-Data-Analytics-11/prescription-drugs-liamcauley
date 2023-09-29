--1.
--a. Which prescriber had the highest total number of claims (totaled over all drugs)?
--Report the npi and the total number of claims.

SELECT PRESCRIBER.NPI,
	SUM(TOTAL_CLAIM_COUNT)
FROM PRESCRIBER
INNER JOIN PRESCRIPTION ON PRESCRIBER.NPI = PRESCRIPTION.NPI
GROUP BY PRESCRIBER.NPI
ORDER BY SUM DESC
LIMIT 1;

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,
--specialty_description, and the total number of claims.

SELECT NPPES_PROVIDER_FIRST_NAME,
	NPPES_PROVIDER_LAST_ORG_NAME,
	SPECIALTY_DESCRIPTION,
	SUM(TOTAL_CLAIM_COUNT) AS GRAND_TOTAL
FROM PRESCRIBER
INNER JOIN PRESCRIPTION ON PRESCRIBER.NPI = PRESCRIPTION.NPI
GROUP BY NPPES_PROVIDER_FIRST_NAME,
	NPPES_PROVIDER_LAST_ORG_NAME,
	SPECIALTY_DESCRIPTION
ORDER BY GRAND_TOTAL DESC
LIMIT 1;

--2.
--a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT SPECIALTY_DESCRIPTION,
	COUNT(total_claim_count) AS SPECIALTY_COUNT
FROM PRESCRIBER
INNER JOIN PRESCRIPTION ON PRESCRIBER.NPI = PRESCRIPTION.NPI
GROUP BY SPECIALTY_DESCRIPTION
ORDER BY SPECIALTY_COUNT DESC;

--b. Which specialty had the most total number of claims for opioids?

SELECT SPECIALTY_DESCRIPTION,
	OPIOID_DRUG_FLAG,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM
FROM PRESCRIBER
INNER JOIN PRESCRIPTION ON PRESCRIBER.NPI = PRESCRIPTION.NPI
INNER JOIN DRUG ON PRESCRIPTION.DRUG_NAME = DRUG.DRUG_NAME
WHERE OPIOID_DRUG_FLAG = 'Y'
GROUP BY SPECIALTY_DESCRIPTION,
	OPIOID_DRUG_FLAG
ORDER BY TOTAL_CLAIM DESC;

--c. **Challenge Question:** Are there any specialties that appear in the
--prescriber table that have no associated prescriptions in the prescription table?
SELECT SPECIALTY_DESCRIPTION,
	COUNT(total_claim_count) AS SPECIALTY_COUNT
FROM PRESCRIBER
LEFT JOIN PRESCRIPTION USING (NPI)
GROUP BY SPECIALTY_DESCRIPTION
HAVING SUM(total_claim_count) IS null
 --d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!
--* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
 --3.
--a. Which drug (generic_name) had the highest total drug cost?

SELECT GENERIC_NAME,
	SUM(TOTAL_DRUG_COST::MONEY) AS TOTAL_DRUG
FROM DRUG
INNER JOIN PRESCRIPTION ON PRESCRIPTION.DRUG_NAME = DRUG.DRUG_NAME
WHERE TOTAL_DRUG_COST IS NOT NULL
GROUP BY GENERIC_NAME
ORDER BY TOTAL_DRUG DESC;

--b. Which drug (generic_name) has the hightest total cost per day?
--**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT GENERIC_NAME,
ROUND(SUM(TOTAL_DRUG_COST)/SUM(TOTAL_DAY_SUPPLY), 2)::money AS TOTAL_DAILY
FROM PRESCRIPTION
INNER JOIN DRUG ON PRESCRIPTION.DRUG_NAME = DRUG.DRUG_NAME
GROUP BY GENERIC_NAME
ORDER BY TOTAL_DAILY DESC;

--4.
--a. For each drug in the drug table, return the drug name and then a column named 'drug_type'
--which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic'
--for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT DRUG_NAME,
	CASE
					WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'opioid'
					WHEN ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'antibiotic'
					ELSE 'neither'
	END AS DRUG_TYPE
FROM DRUG;

--b. Building off of the query you wrote for part a, determine whether more was spent
--(total_drug_cost) on opioids or on antibiotics.
--Hint: Format the total costs as MONEY for easier comparision.
WITH DRUG_TYPE_COST AS
	(SELECT DRUG_NAME,
			CASE
							WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'opioid'
							WHEN ANTIBIOTIC_DRUG_FLAG = 'Y' THEN 'antibiotic'
							ELSE 'neither'
			END AS DRUG_TYPE
		FROM DRUG)
SELECT DRUG_TYPE,
	SUM(TOTAL_DRUG_COST::MONEY) AS COST
FROM DRUG_TYPE_COST
INNER JOIN PRESCRIPTION USING(DRUG_NAME)
WHERE DRUG_TYPE = 'antibiotic'
	OR DRUG_TYPE = 'opioid'
GROUP BY DRUG_TYPE
ORDER BY COST DESC 
--5.
--a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT CBSA,
	STATE
FROM CBSA
INNER JOIN FIPS_COUNTY USING(FIPSCOUNTY)
WHERE STATE = 'TN'
GROUP BY CBSA,
	STATE;

--b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT CBSANAME,
	SUM(POPULATION) AS TOTAL_POP
FROM CBSA
INNER JOIN FIPS_COUNTY USING(FIPSCOUNTY)
INNER JOIN POPULATION USING(FIPSCOUNTY)
GROUP BY CBSANAME
ORDER BY TOTAL_POP DESC;

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT *
FROM POPULATION
INNER JOIN FIPS_COUNTY USING(FIPSCOUNTY)
INNER JOIN CBSA USING(FIPSCOUNTY)


--6.
--a. Find all rows in the prescription table where total_claims is at least 3000.
--Report the drug_name and the total_claim_count.

SELECT DRUG_NAME,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM
FROM PRESCRIPTION
WHERE TOTAL_CLAIM_COUNT >= 3000
GROUP BY DRUG_NAME;

--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT DRUG_NAME,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM,
	CASE
					WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'opioid'
					ELSE 'non_opioid'
	END AS OPIOID_CHECK
FROM PRESCRIPTION
INNER JOIN DRUG USING(DRUG_NAME)
WHERE TOTAL_CLAIM_COUNT >= 3000
GROUP BY DRUG_NAME,
	OPIOID_DRUG_FLAG;

--c. Add another column to you answer from the previous part which gives the prescriber
--first and last name associated with each row.

SELECT NPPES_PROVIDER_FIRST_NAME,
	NPPES_PROVIDER_LAST_ORG_NAME,
	DRUG_NAME,
	SUM(TOTAL_CLAIM_COUNT) AS TOTAL_CLAIM,
	CASE
					WHEN OPIOID_DRUG_FLAG = 'Y' THEN 'opioid'
					ELSE 'non_opioid'
	END AS OPIOID_CHECK
FROM PRESCRIBER
INNER JOIN PRESCRIPTION USING (NPI)
INNER JOIN DRUG USING(DRUG_NAME)
WHERE TOTAL_CLAIM_COUNT >= 3000
GROUP BY NPPES_PROVIDER_FIRST_NAME,
	NPPES_PROVIDER_LAST_ORG_NAME,
	DRUG_NAME,
	OPIOID_DRUG_FLAG;

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville
--and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
 --a. First, create a list of all npi/drug_name combinations for pain management specialists
--(specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'),
-- where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it.
--You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT PRESCRIBER.NPI, 
	DRUG.DRUG_NAME
	TOTAL_CLAIM_COUNT
FROM PRESCRIBER CROSS JOIN drug
LEFT JOIN PRESCRIPTION USING(NPI, DRUG_NAME) 
WHERE SPECIALTY_DESCRIPTION = 'Pain Management' 
	AND NPPES_PROVIDER_CITY = 'NASHVILLE'
	AND OPIOID_DRUG_FLAG = 'Y'
GROUP BY PRESCRIBER.NPI,
	DRUG.DRUG_NAME;

--b. Next, report the number of claims per drug per prescriber.
--Be sure to include all combinations, whether or not the prescriber had any claims.
--You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT PRESCRIBER.NPI,
	DRUG.DRUG_NAME,
	TOTAL_CLAIM_COUNT,
FROM PRESCRIBER
INNER JOIN PRESCRIPTION USING(NPI)
INNER JOIN DRUG USING(DRUG_NAME)
WHERE SPECIALTY_DESCRIPTION = 'Pain Management'
	AND NPPES_PROVIDER_CITY = 'NASHVILLE'
	AND OPIOID_DRUG_FLAG = 'Y'
GROUP BY PRESCRIBER.NPI,
	DRUG.DRUG_NAME,
	TOTAL_CLAIM_COUNT;

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0.
--Hint - Google the COALESCE function.

SELECT PRESCRIBER.NPI,
	DRUG.DRUG_NAME,
	TOTAL_CLAIM_COUNT,
	COALESCE(TOTAL_CLAIM_COUNT,

		'0')
FROM PRESCRIBER
INNER JOIN PRESCRIPTION USING(NPI)
INNER JOIN DRUG USING(DRUG_NAME)
WHERE SPECIALTY_DESCRIPTION = 'Pain Management'
	AND NPPES_PROVIDER_CITY = 'NASHVILLE'
	AND OPIOID_DRUG_FLAG = 'Y'
GROUP BY PRESCRIBER.NPI,
	DRUG.DRUG_NAME,
	TOTAL_CLAIM_COUNT;