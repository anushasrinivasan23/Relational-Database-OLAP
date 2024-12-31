library(DBI)
library(RSQLite)
library(RMySQL)

# Connection to SQLite database
sqliteCon <- dbConnect(RSQLite::SQLite(), dbname="pharma_sales.db")

# Connection to MySQL database
mysqlCon <- dbConnect(RMySQL::MySQL(), 
                      dbname = 'dbname', 
                      username = 'user', 
                      password = 'pw', 
                      host = 'hostname', 
                      port = )


# SQL statement to create the product_facts table
create_product_facts_sql <- "
CREATE TABLE IF NOT EXISTS product_facts (
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    total_amount_sold DECIMAL(10, 2),
    total_units_sold INT,
    year INT,
    quarter CHAR(2),
    territory VARCHAR(100),
    PRIMARY KEY (product_id, year, quarter, territory)
);
"

# Execute the statement 
dbExecute(mysqlCon, create_product_facts_sql)

# SQL statement to create the rep_facts table
create_rep_facts_sql <- "
CREATE TABLE IF NOT EXISTS rep_facts (
    rep_id INT NOT NULL,
    rep_name VARCHAR(255) NOT NULL,
    total_amount_sold DECIMAL(10, 2),
    average_amount_sold DECIMAL(10, 2),
    year INT,
    quarter CHAR(2),
    territory VARCHAR(100),
    PRIMARY KEY (rep_id, year, quarter)
);
"

# Execute the statement in the MySQL connection
dbExecute(mysqlCon, create_rep_facts_sql)

# If the 'territory' column does not exist, then add it
territory_exists <- dbGetQuery(mysqlCon, "
SELECT COUNT(*)
FROM information_schema.COLUMNS 
WHERE 
    TABLE_SCHEMA = 'sql5698732'  
    AND TABLE_NAME = 'rep_facts' 
    AND COLUMN_NAME = 'territory'
")
if(territory_exists$`COUNT(*)`[1] == 0) {
  dbExecute(mysqlCon, "ALTER TABLE rep_facts ADD COLUMN territory VARCHAR(100);")
}


# SQL query for product_facts
product_facts_sql <- "
SELECT
    p.product_id,
    p.product_name AS product_name,
    SUM(s.total_sale) AS total_amount_sold,
    SUM(s.quantity) AS total_units_sold,
    strftime('%Y', s.sale_date) AS year,
    'Q' || CAST(((CAST(strftime('%m', s.sale_date) AS INTEGER) - 1) / 3 + 1) AS TEXT) AS quarter,
    r.territory AS territory
FROM
    sales s
JOIN
    products p ON s.product_id = p.product_id
JOIN
    reps r ON s.rep_id = r.rep_id
GROUP BY
    p.product_id, year, quarter, r.territory
"

# Get the aggregated data for product_facts from SQLite
product_facts_data <- dbGetQuery(sqliteCon, product_facts_sql)
dbWriteTable(mysqlCon, "product_facts", product_facts_data, append = TRUE, row.names = FALSE, overwrite = FALSE)


rep_facts_sql <- "
SELECT
    r.rep_id,
    r.first_name || ' ' || r.sur_name AS rep_name,
    SUM(s.total_sale) AS total_amount_sold,
    AVG(s.total_sale) AS average_amount_sold,
    strftime('%Y', s.sale_date) AS year,
    CASE 
        WHEN CAST(strftime('%m', s.sale_date) AS INTEGER) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN CAST(strftime('%m', s.sale_date) AS INTEGER) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN CAST(strftime('%m', s.sale_date) AS INTEGER) BETWEEN 7 AND 9 THEN 'Q3'
        WHEN CAST(strftime('%m', s.sale_date) AS INTEGER) BETWEEN 10 AND 12 THEN 'Q4'
    END AS quarter,
    r.territory
FROM
    sales s
LEFT JOIN
    reps r ON s.rep_id = r.rep_id
GROUP BY
    r.rep_id, year, quarter, r.territory
"



# Execute the query and check the number of entries
rep_facts_data <- dbGetQuery(sqliteCon, rep_facts_sql)
nrow(rep_facts_data)  
dbWriteTable(mysqlCon, "rep_facts", rep_facts_data, append = FALSE, row.names = FALSE, overwrite = TRUE)



# Disconnect from databases
dbDisconnect(sqliteCon)
dbDisconnect(mysqlCon)


