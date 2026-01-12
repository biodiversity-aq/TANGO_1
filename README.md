# TANGO_1

Antarctic biodiversity data processing and standardization for the TANGO_1 expedition.

## Project Organization

```
├── LICENSE            <- MIT License
├── README.md          <- The top-level README for developers using this project
├── data
│   ├── 01_raw         <- The original, immutable data dump
│   ├── 02_interim     <- Intermediate data that has been transformed
│   └── 03_output      <- The final, canonical data sets for modeling
│
├── src                <- Source code for use in this project
│   └── clean_data.R   <- Script to clean and standardize data
│
├── renv               <- R environment management (dependency management)
├── .Rprofile          <- R profile to activate renv
├── TANGO_1.Rproj      <- RStudio project file
└── .gitignore         <- Specifies intentionally untracked files to ignore
```

## Directory Descriptions

### `data/`

Data directory organized following the principle that data is immutable and transformed through a pipeline:

- **`01_raw/`** - Original, immutable data files. Never edit these files directly.
  - `TANGO_1_DATA.xlsx` - Raw expedition data
  - `gear_protocol.tsv` - Gear type and sampling protocol reference data

- **`02_interim/`** - Intermediate data that has been cleaned or transformed.
  - `TANGO_1_DATA_cleaned.xlsx` - Manually cleaned data with corrections
  - `changes.md` - Documentation of all changes made during manual data cleaning

- **`03_output/`** - Final, processed data ready for use or publication.
  - `tango_1_events.tsv` - Standardized event data
  - `tango_1_samples.tsv` - Standardized sample data

### `src/`

Source code for data processing:

- **`clean_data.R`** - Main data cleaning and standardization script that:
  - Loads raw and interim data
  - Standardizes field names to Darwin Core terms
  - Cleans and validates coordinates, dates, and times
  - Consolidates collector and identifier information
  - Exports final standardized TSV files

### `renv/`

R environment management directory. Contains the `renv` package infrastructure for reproducible dependency management. This ensures that the project uses consistent package versions across different machines and over time.

## Getting Started

### Prerequisites

- R (version 4.0 or higher recommended)
- RStudio (optional but recommended)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/biodiversity-aq/TANGO_1.git
   cd TANGO_1
   ```

2. Open the project in RStudio by double-clicking `TANGO_1.Rproj`, or start R in the project directory.

3. The `renv` environment will be automatically activated (via `.Rprofile`). Restore the project dependencies:
   ```r
   renv::restore()
   ```

### Usage

To process the data:

```r
source("src/clean_data.R")
```

This will:
1. Load data from `data/01_raw/` and `data/02_interim/`
2. Apply cleaning and standardization transformations
3. Generate output files in `data/03_output/`

## Data Standards

The output data is standardized to Darwin Core terms for biodiversity data publishing. Key transformations include:

- Event data: Standardized sampling events with temporal, spatial, and protocol information
- Sample data: Taxonomic specimens linked to events with identification details
- Coordinate precision and uncertainty calculations
- Time zone conversions to UTC
- Consolidated personnel information (recordedBy, identifiedBy) with ORCID identifiers

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Project Background

This repository contains data processing scripts for the TANGO_1 Antarctic expedition. The expedition collected biodiversity data using various sampling methods including ROV, SCUBA, Niskin bottles, and drone aerial mapping in locations around the Antarctic Peninsula including Dodman Island, Blaiklock Island, and Grandidier Channel.
