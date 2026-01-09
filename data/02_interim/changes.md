 | file name
---|---
input file | `01_raw/TANGO_1_DATA.xlsx`
output file | `02_processing/TANGO_1_DATA_cleaned.xlsx`


# Changes

# EVENTS sheet

### eventID not unique

eventID | changes
---|---
`AT_1` | 2 events with the same ID, one for amphipod trap deployment, one for collection. Consolidate both into the 1 event. 
`AT_2` | 2 events with the same ID, one for amphipod trap deployment, one for collection. Consolidate both into the 1 event.
`AT_3` | 2 events with the same ID, one for amphipod trap deployment, one for collection. Consolidate both into the 1 event. set AT_3 max depth to 60m (was filled in 60m for min depth twice.
`AT_4` | 2 events with the same ID, one for amphipod trap deployment, one for collection. Consolidate both into the 1 event.
`AT_5` | 2 events with the same ID, one for amphipod trap deployment, one for collection. Consolidate both into the 1 event. Set AT_3 min depth to 23m instead of altitude.
`ST_2` | 2 events with the same ID, one for amphipod trap deployment, one for collection. Consolidate both into the 1 event.

### eventDate

- rename `eventDate` to `eventDate_start`
- add `eventDate_end` for date range needed for amphipod trap that spans multiple days

### coordinates typo

`AT_1` & `AT_2` may have typo in coordinates because it has huge cuim.

- change AT_1 Latitude end (degree) to 65. To double check with data provider.

### rename Collector fields

to Collector1, Collector2, Collector3, Collector4

### add orcid of collectors

as collector1orcid, collector2orcid, collector3orcid, collector4orcid

### fix typo of station

Correct Grandider Channel to Grandidier Channel

### add higherGeographyID

SCAR Gazetteer ID based on locality value

### populate gearType based on eventID abbreviations

There are many events that have no context. gearType populated based on cruise report page 41. Replacing the values below because there are empty gearType but with eventID with the same abbreviation to ensure that they are all consistent.

Replace value

eventID abbr | old gearType | new gearType
---|---|---
ROV | blueROV | Remote Operating Vehicles
ICE, SEAICE | | sea ice works
SCUBA | SCUBA | Scuba divers
NIS | NISKIN 3L | Niskin
 | Mavic 2 PRO | Mavic 2 PRO drone aerial mapping 

## SAMPLES sheet

### add identifiedByID

for each of identifiedBy1,2,3

### add recordedByID

for each of recordedBy1,2

### replace abbreviation in identifiedBy1,2,3

old identifiedBy | new identifiedBy|
---|---
AB | Axelle Brusselman
CM | Camille Moreau
HR | Henri Robert
LK | Lea Katz
MD | Martin Dogniez
BDE | Bruno Delille

### some rows have column shifted

rows with identifiedBy3 = "ethanol" have columns shifted. Shift "ethanol" to "preserved in" column.

### rename fields

old name | new name
---|---
scientificName | verbatimIdentification

### add fields

- identificationQualifier
- correctedVerbatimIdentification: splitting out sp, mix, identificationQualifier, fixed MANY typos 
- vernacularName: extracted from scientificName
- taxon fields: scientificName based on WoRMS, scientificNameAuthorship, kingdom, phylum, class, order, family, genus, specificEpithet.

## fix eventID typo

old eventID | new eventID
---|---
SCUBA 05 | SCUBA_5
RD_06 | RD_6
RD_07 | RD_7
ITD1 | ITD_1
CT_5 | CTD_5
