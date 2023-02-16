# NZA-Census-Places-Counties

## Summary
This repository was created to help state teams working with the [National Zoning Atlas](https://www.zoningatlas.org/) collect county and Place-level data from the U.S. Census Bureau. The outputs include an Excel workbook listing Census Places by type (*e.g.*, city, town, borough, etc.) by largest county overlap, a water-clipped shapefile of Census Places, and a coastline-clipped shapefile of counties. These outputs are generated for whichever state the user specifies.

## Contents
This repository includes two folders: **scripts** and **tables**.

The **scripts** folder contains two R scripts:

- `00_preamble.R` prepares the workspace by loading the required packages, etc. It is called in `01_data_import.R`.
- `01_data_import.R` generates the outputs. It is set to prepare the table and shapefiles for New York. Users may change the state on *line 16*.

The **tables** folder contains on Excel workbook copied from the [U.S. Census](https://www.census.gov/library/reference/code-lists/legal-status-codes.html) that translates the Census Place types from numerical Legal/Statistical Area Description (LSAD) codes to readable text. These LSADs specify if a Census Place is considered a city, borough, township, village, and so on.
