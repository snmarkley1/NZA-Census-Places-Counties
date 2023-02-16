
##############################################################
###
### Import and Clean Census Places and Counties
###
##############################################################


##----------------------------------------------
## Prepare workspace
##----------------------------------------------

source("scripts/00_preamble.R")

## set state
st <- "NY"


## set coordinate system
crs_set <- 4326


## load census legal codes
codes <- read.xlsx("tables/census_legal_codes.xlsx") %>%
  as_tibble() %>%
  select(-3) %>%
  print()


##------------------------------------------------
##  Data import
##------------------------------------------------


## list of states
states <- fips_codes %>%
  as_tibble() %>%
  select(state_name, state_code) %>%
  distinct() %>%
  print()


## create county list
county_list <- fips_codes %>%
  as_tibble() %>%
  filter(state == st) %>%
  select(county_code, county) %>%
  print()


## Import census places
place_import <- tigris::places(state = st) %>%
  # filter place types
  filter(CLASSFP %in% c("C1", "C2", "C3", "C5", "C6", "C7", "C8")) %>%
  # join to get place type
  left_join(codes, by = "LSAD") %>%
  # set coordinate ref. system
  st_transform(crs = crs_set) %>%
  print() 


## map
mapview(place_import)


## Import counties
county_import <- tigris::counties(state = st) %>%
  # set crs
  st_transform(crs = crs_set) %>%
  print()


## map
mapview(county_import)


##-------------------------------------------------
## Prepare water clips
##-------------------------------------------------

## import country files & query for USA
url <- parse_url("https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/World_Countries/FeatureServer")
url$path <- paste(url$path, "0/query", sep = "/")
url$query <- list(where = "COUNTRY = 'United States'",
                  outFields = "*",
                  returnGeometry = "true",
                  f = "geojson")
request <- build_url(url)


## create shorelines polygon
usa_shorelines <- st_read(request) %>%
  # set crs
  st_transform(crs = crs_set) %>%
  # repair geometry
  st_make_valid() %>%
  print()

## map
mapview(usa_shorelines)



## fix county boundaries
##------------------------------------------------------------------------
county_fix <- st_intersection(county_import, usa_shorelines) %>%
  print()

## map
mapview(county_fix)


## Import water areas
##----------------------------------------------------------------------

water <-  tigris::area_water(state = st, county = county_list$county_code) %>%
  # keep only top 2% of water surfaces (focus on coastlines and large lakes)
  filter(AWATER >= quantile(AWATER, 0.98)) %>%
  # set crs
  st_transform(crs = crs_set) %>%
  print()

## map
mapview(water)


## Example of geometric union

#op1 <- st_difference(place_import, st_union(county_import))
#op2 <- st_difference(county_import, st_union(place_import))
#op3 <- st_intersection(county_import, place_import)
#pc_union_test <- bind_rows(op1, op2, op3) %>%
#  print()

#mapview(pc_union_test)

#mapview(place_import)


## cut out water from place geometries
##----------------------------------------------------------------

## places
place_land <- st_difference(place_import, st_union(water)) %>%
  st_collection_extract(., "POLYGON") %>%
  print()

## map
mapview(place_land)



##-----------------------------------------------------------
## Produce table
##-----------------------------------------------------------

## regular union
pc_union <- st_intersection(county_import, place_import) %>%
  # calc. surface area
  mutate(area_m = st_area(.)) %>%
  print()

## map
mapview(pc_union)


## clean union table
pc_area <- pc_union %>%
  # get state name
  left_join(states, by = c("STATEFP" = "state_code")) %>%
  select(state_name, GEOID.1, NAME.1,  LSAD.1, PLACE_TYPE, GEOID, NAME, area_m, geometry) %>%
  rename(
    STATE = state_name,
    PLACE_ID = GEOID.1,
    PLACE = NAME.1,
    LSAD = LSAD.1,
    COUNTY_ID = GEOID,
    COUNTY = NAME
  ) %>%
  arrange(COUNTY, PLACE) %>%
  print()


## further clean up
pc_clean <- pc_area %>%
  as_tibble() %>%
  select(-geometry) %>%
  arrange(PLACE, COUNTY) %>%
  # select counties with maximum overlap of jurisdiction
  # (one county per jurisdiction)
  group_by(PLACE_ID) %>%
  mutate(
    n = n(),
    area_max = max(area_m)
    ) %>%
  ungroup() %>%
  # keep only largest area county overlaps
  filter(area_m == area_max) %>%
  # clean
  select(STATE, COUNTY_ID, COUNTY, PLACE_ID, PLACE, PLACE_TYPE) %>%
  arrange(COUNTY, PLACE) %>%
  print()



##-------------------------------------------------
## create folders and export
##-------------------------------------------------

## create state-specific folders and subfolders
dir.create(st)

shapes_folder <- paste0(st, "/shapes")
tables_folder <- paste0(st, "/tables")

dir.create(shapes_folder)
dir.create(tables_folder)


## write out shapefiles
##------------------------------

## census places
st_write(
  place_land,
  dsn = shapes_folder,
  layer = "census_places",
  driver = "ESRI Shapefile"
)

## counties
st_write(
  county_fix,
  dsn = shapes_folder,
  layer = "counties",
  driver = "ESRI Shapefile"
)


## write out table
##------------------------------

write.xlsx(pc_clean, paste0(tables_folder, "/census_places_by_county.xlsx"))



