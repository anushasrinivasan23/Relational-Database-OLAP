
# Relational Database OLAP Project

This project demonstrates the creation and analysis of a relational database for OLAP. It includes loading XML data into a database, analyzing the data with R, and generating meaningful insights through SQL queries and visualizations.

---

## **Project Components**

### 1. **Files**
- **AnalyzeData.SrinivasanA.Rmd**: The main R Markdown file for data analysis and reporting.
- **AnalyzeData.SrinivasanA.nb.html**: HTML output of the analysis report.
- **AnalyzeData.SrinivasanA.pdf**: PDF output of the analysis report.
- **LoadOLAP.SrinivasanA.R**: R script for loading and transforming OLAP data.
- **LoadXML2DB.SrinivasanA.R**: R script for parsing XML data and populating the database.

### 2. **Key Features**
- **XML to Relational Database Transformation**:
  - Parses XML files and loads data into a relational database.
- **OLAP Queries**:
  - Analytical queries designed to generate insights for sales and product performance.
- **Visualizations**:
  - Plots and tables for easy interpretation of analytical results.
- **Reports**:
  - Comprehensive HTML and PDF reports summarizing the analysis.

---

## **Technologies Used**
- **R**: For data transformation, analysis, and visualization.
- **MySQL**: For relational database storage and querying.
- **RMarkdown**: To generate dynamic reports combining queries and visualizations.
- **ggplot2**: For data visualizations.
- **XML**: Data source for initial transformation.

---

## **Key Analytical Queries**
### 1. **Top Sales Reps by Year**
   - Ranks sales reps by their performance annually.

### 2. **Sales Per Product Per Quarter**
   - Aggregates sales data for each product by quarter and year.

### 3. **Units Sold Per Product by Region**
   - Summarizes the total number of units sold across different regions.

### 4. **Average Sales Per Rep Over Time**
   - Highlights trends in average sales for sales representatives over the years.

---

## **Project Structure**
```
/RELATIONAL-DATABASE-OLAP
│
├── AnalyzeData.SrinivasanA.Rmd       # Main R Markdown analysis file
├── AnalyzeData.SrinivasanA.nb.html   # HTML report
├── AnalyzeData.SrinivasanA.pdf       # PDF report
├── LoadOLAP.SrinivasanA.R            # OLAP data loading script
├── LoadXML2DB.SrinivasanA.R          # XML data loading script
├── README.md                         # Project documentation
```

---

## **License**
This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## **Future Enhancements**
- Add dashboard functionality for interactive data exploration.
- Include advanced OLAP operations and real-time data processing.
