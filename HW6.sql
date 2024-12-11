-- DB Assignmnet 6
-- Christina DiMaggio
-- December 10 2024

/* **************************************************************************************** */
-- when set, it prevents potentially dangerous updates and deletes
set SQL_SAFE_UPDATES=0;

-- when set, it disables the enforcement of foreign key constraints.
set FOREIGN_KEY_CHECKS=0;

/* **************************************************************************************** 
-- These control:
--     the maximum time (in seconds) that the client will wait while trying to establish a 
	   connection to the MySQL server 
--     how long the client will wait for a response from the server once a request has 
       been sent over
**************************************************************************************** */
SHOW SESSION VARIABLES LIKE '%timeout%';       
SET GLOBAL mysqlx_connect_timeout = 600;
SET GLOBAL mysqlx_read_timeout = 600;

/* **************************************************************************************** */
-- The DB where the accounts table is created
use indexing;
 -- drop table accounts; -- this is used to help drop the table to then regenerate a new accounts table
 
-- Create the accounts table
CREATE TABLE accounts (
  account_num CHAR(5) PRIMARY KEY,    -- 5-digit account number (e.g., 00001, 00002, ...)
  branch_name VARCHAR(50),            -- Branch name (e.g., Brighton, Downtown, etc.)
  balance DECIMAL(10, 2),             -- Account balance, with two decimal places (e.g., 1000.50)
  account_type VARCHAR(50)            -- Type of the account (e.g., Savings, Checking)
);

-- to show what type of table that has been created
show table status like 'accounts';

-- procedures used to create 50000, 100000, and 150000 records for the accounts table
-- in order to make sure the NEW stores procedure for the number of records is run 
-- make sure to right click in schemas to drop stored prodecdure after run!

/* ***************************************************************************************************
The procedure generates 50000 records for the accounts table, with the account_num padded to 5 digits.
branch_name is randomly selected from one of the six predefined branches.
balance is generated randomly, between 0 and 100,000, rounded to two decimal places.
In order to change how many records are generated looks at comments in prodecure to show were to change numbers
***************************************************************************************************** */
-- Change delimiter to allow semicolons inside the procedure
DELIMITER $$

CREATE PROCEDURE generate_accounts()
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE branch_name VARCHAR(50);
  DECLARE account_type VARCHAR(50);
  
  -- Loop to generate 100,000 account records
  WHILE i <= 50000 DO -- change to be 100,000 or 150,000 depending on how many records needed for run
    -- Randomly select a branch from the list of branches
    SET branch_name = ELT(FLOOR(1 + (RAND() * 6)), 'Brighton', 'Downtown', 'Mianus', 'Perryridge', 'Redwood', 'RoundHill');
    
    -- Randomly select an account type
    SET account_type = ELT(FLOOR(1 + (RAND() * 2)), 'Savings', 'Checking');
    
    -- Insert account record
    INSERT INTO accounts (account_num, branch_name, balance, account_type)
    VALUES (
      LPAD(i, 5, '0'),                   -- Account number as just digits, padded to 5 digits (e.g., 00001, 00002, ...)
      branch_name,                       -- Randomly selected branch name
      ROUND((RAND() * 50000), 2),       -- Random balance between 0 and 50,000, rounded to 2 decimal places 
										 -- change 50,000 to be 100,000 or 150,000 depending on how many records needed for run
      account_type                       -- Randomly selected account type (Savings/Checking)
    );

    SET i = i + 1;
  END WHILE;
END$$

-- Reset the delimiter back to the default semicolon
DELIMITER ;

-- ******************************************************************
-- execute the procedure
-- ******************************************************************
CALL generate_accounts(); -- make sure to drop procedure after a new record number is implimented to ensure the correct number of records shows
select count(*) from accounts; -- ensure proper number of records is included
select * from accounts limit 10; -- shows sample of what records in account table
-- able to show variety in branch names in table

-- ******************************************************************************************
-- Timing analysis procedure, for POINT QUERY or RANGE QUERY
-- ******************************************************************************************
-- Change delimiter to allow semicolons inside the procedure
DELIMITER $$

CREATE PROCEDURE measure_query_execution_time()
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE total_time BIGINT DEFAULT 0;
    DECLARE start_time DATETIME(6);
    DECLARE end_time DATETIME(6);
    DECLARE execution_time INT;

    -- Loop to execute the query 10 times
    WHILE i < 10 DO
        -- Step 1: Capture the start time with microsecond precision
        SET start_time = NOW(6);

        -- Step 2: Run the POINT QUERY you want to measure 
			-- Make sure to comment or uncomment depending on which query you need to run
	-- SET @sql_query = 'SELECT count(*) FROM accounts WHERE branch_name = ''Downtown'' AND account_type = ''Savings'';';
        
        -- Step 2: Run the RANGE query you want to measure
			-- Make sure to comment or uncomment depending on which query you need to run
	SET @sql_query = 'SELECT count(*) FROM accounts WHERE branch_name = ''Downtown'' AND balance BETWEEN 5000 AND 100000;';

	PREPARE dynamic_query FROM @sql_query;
        EXECUTE dynamic_query;
        DEALLOCATE PREPARE dynamic_query;

        -- Step 3: Capture the end time with microsecond precision
        SET end_time = NOW(6);

        -- Step 4: Calculate the execution time in microseconds
        SET execution_time = TIMESTAMPDIFF(MICROSECOND, start_time, end_time);

        -- Add the execution time to the total time
        SET total_time = total_time + execution_time;

        -- Increment the loop counter
        SET i = i + 1;
    END WHILE;

    -- Step 5: Calculate the average execution time and return it
    SELECT total_time / 10 AS average_execution_time_microseconds;
END$$

DELIMITER ;

-- use this code to call either the procedures above utilizing point or range query
CALL measure_query_execution_time(); 

-- CREATING INDEXES ******************************************************************
-- alter table accounts add primary key(account_num); primary key index should already be added in table but if not uncomment to add 
CREATE INDEX idx_branch_name ON accounts (branch_name); -- used for point queries
CREATE INDEX idx_balance ON accounts (balance); -- used for point queries

-- If you frequently run queries that filter or sort by both branch_name and account_type, 
-- creating a composite index on these two columns can improve performance.
CREATE INDEX idx_branch_balance_type ON accounts (branch_name, balance); -- used for range queries

SHOW INDEXES from accounts; -- shows what indexes are present in the table
-- DROP INDEX [INSERT INDEX NAME] ON accounts; -- this is used to ensure unnecessary indexes are not in the table 


