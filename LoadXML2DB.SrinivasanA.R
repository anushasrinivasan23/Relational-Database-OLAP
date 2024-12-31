library(DBI)
library(RSQLite)
library(XML)
library(DBI)

# Connect to the database 
conn <- dbConnect(RSQLite::SQLite(), dbname = "pharma_sales.db")

# Create the 'reps' table
dbExecute(conn, "CREATE TABLE IF NOT EXISTS reps (
  rep_id VARCHAR(10) PRIMARY KEY,
  first_name VARCHAR(50),
  sur_name VARCHAR(50),
  territory VARCHAR(50),
  commission DECIMAL(10, 2)
)")

# Create the 'customers' table
dbExecute(conn, "CREATE TABLE  IF NOT EXISTS customers (
  customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_name VARCHAR(100),
  country VARCHAR(50)
)")

# Create Products table
dbExecute(conn, "
CREATE TABLE  IF NOT EXISTS products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_name TEXT NOT NULL
)")

# Create sales table
dbExecute(conn, "
CREATE TABLE  IF NOT EXISTS sales (
    sale_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id INTEGER,
    rep_id INTEGER,
    customer_id INTEGER,
    sale_date DATE,
    quantity INTEGER,
    total_sale REAL,
    FOREIGN KEY (product_id) REFERENCES products (product_id),
    FOREIGN KEY (rep_id) REFERENCES reps (rep_id),
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
)")


# Insert Reps Data from the XML File
insert_reps_data <- function(filepath, conn) {
  doc <- xmlParse(filepath)
  
  reps <- xpathApply(doc, "//rep", fun = function(node) {
    rep_id = xmlGetAttr(node, "rID")
    first_name = xmlValue(node[["name"]][["first"]])
    sur_name = xmlValue(node[["name"]][["sur"]])
    territory = xmlValue(node[["territory"]])
    commission = as.numeric(xmlValue(node[["commission"]]))
    
    # Check if this rep_id already exists
    exists <- dbGetQuery(conn, sprintf("SELECT 1 FROM reps WHERE rep_id = '%s'", rep_id))
    
    if (nrow(exists) == 0) {
      return(data.frame(rep_id = rep_id, first_name = first_name, sur_name = sur_name, territory = territory, commission = commission, stringsAsFactors = FALSE))
    } else {
      return(NULL)
    }
  })
  
  # Filter out entries where rep already exists
  reps <- reps[!sapply(reps, is.null)]
  if (length(reps) > 0) {
    reps_df <- do.call(rbind, reps)
    dbWriteTable(conn, "reps", reps_df, append = TRUE, row.names = FALSE, overwrite = FALSE)
  }
}
insert_reps_data("txn-xml/pharmaReps-F23.xml",conn)

# Function to ensure date is in 'YYYY-MM-DD' format
date_format <- function(date) {
  parts <- unlist(strsplit(date, "/"))
  formatted_date <- sprintf('%04d-%02d-%02d', as.numeric(parts[3]), as.numeric(parts[1]), as.numeric(parts[2]))
  return(formatted_date)
}

# Insert a product if it doesn't exist
insert_product <- function(product_name, conn) {
  exists <- dbGetQuery(conn, sprintf("SELECT 1 FROM products WHERE product_name = '%s'", product_name))
  if (nrow(exists) == 0) {
    dbExecute(conn, sprintf("INSERT INTO products (product_name) VALUES ('%s')", product_name))
  }
}

# Insert a customer if it doesn't exist
insert_customer <- function(customer_name, country, conn) {
  exists <- dbGetQuery(conn, sprintf("SELECT 1 FROM customers WHERE customer_name = '%s'", customer_name))
  if (nrow(exists) == 0) {
    dbExecute(conn, sprintf("INSERT INTO customers (customer_name, country) VALUES ('%s', '%s')", customer_name, country))
  }
}


insert_sales_data <- function(filepath, conn) {
  doc <- xmlParse(filepath)
  
  txns <- xpathApply(doc, "//txn", fun = function(node) {
    repID <- xmlGetAttr(node, "repID")
    customer <- xmlValue(node[["customer"]])
    country <- xmlValue(node[["country"]])
    product <- xmlValue(node[["sale"]][["product"]])
    qty <- as.integer(xmlValue(node[["sale"]][["qty"]]))
    total <- as.numeric(xmlValue(node[["sale"]][["total"]]))
    date <- xmlValue(node[["sale"]][["date"]])
    
    # Ensure referenced product and customer exist
    insert_product(product, conn)
    insert_customer(customer, country, conn)
    
    # Get product_id and customer_id 
    product_id <- dbGetQuery(conn, sprintf("SELECT product_id FROM products WHERE product_name = '%s'", product))
    customer_id <- dbGetQuery(conn, sprintf("SELECT customer_id FROM customers WHERE customer_name = '%s'", customer))
    data.frame(
      rep_id = paste0('r', repID),  # Adding 'r' prefix here
      product_id = product_id$product_id[1],
      customer_id = customer_id$customer_id[1],
      sale_date = date_format(date),
      quantity = qty,
      total_sale = total,
      stringsAsFactors = FALSE
    )
  })
  
  # Combine all transactions into a single data frame
  sales_df <- do.call(rbind, txns)
  
  # Insert data into the 'sales' table
  dbWriteTable(conn, "sales", sales_df, append = TRUE, row.names = FALSE, overwrite = FALSE)
}

insert_sales_data("txn-xml/pharmaSalesTxn-10-F23.xml",conn)
insert_sales_data("txn-xml/pharmaSalesTxn-20-F23.xml",conn)
insert_sales_data("txn-xml/pharmaSalesTxn-3000-F23.xml",conn)
insert_sales_data("txn-xml/pharmaSalesTxn-5000-F23.xml",conn)
insert_sales_data("txn-xml/pharmaSalesTxn-8000-F23.xml",conn)

dbGetQuery(conn,"select * from reps")
dbGetQuery(conn,"select * from sales")
dbGetQuery(conn,"select * from products")
dbGetQuery(conn,"select * from customers")

# Query to count and print the number of rows in each table
num_reps <- dbGetQuery(conn, "SELECT COUNT(*) as Total FROM reps")
print(paste("Number of rows in reps:", num_reps$Total))

num_customers <- dbGetQuery(conn, "SELECT COUNT(*) as Total FROM customers")
print(paste("Number of rows in customers:", num_customers$Total))

num_products <- dbGetQuery(conn, "SELECT COUNT(*) as Total FROM products")
print(paste("Number of rows in products:", num_products$Total))

num_sales <- dbGetQuery(conn, "SELECT COUNT(*) as Total FROM sales")
print(paste("Number of rows in sales:", num_sales$Total))

# Close the connection
dbDisconnect(conn)