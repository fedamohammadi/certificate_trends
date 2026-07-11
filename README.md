##  Postsecondary Certificate Trends

## 📁 Project Structure

```
certificate_trends/
│
├── code/          # Stata do-files for panel construction and descriptive analysis
│
├── data/
│   ├── raw/       # Original IPEDS Completions (C_A) and Institutional Characteristics (HD) files
│   └── clean/     # Harmonized institution × CIP × award-level panel, 2000-2024
│
├── docs/          # Progress reports and the final descriptive report (PDFs)
│
├── output/
│   ├── figures/   # Time-series charts and comparison plots
│   └── tables/    # Summary tables in CSV format
│
├── .gitignore                # Files and folders excluded from version control
├── certificate_trends.Rproj  # RStudio project file
└── README.md
```


## Reproducing the panel

1. Download the IPEDS Completions (`C{year}_A`) and Institutional Characteristics (`HD{year}`) Stata files for 2000-2024 from https://nces.ed.gov/ipeds/use-the-data
2. Place all downloaded CSVs in `data/raw/ipeds/`
3. Update the `global root` path in `code/02_build_panel.do` to your local repo path
4. Run `code/02_build_panel.do` to build the harmonized panel
5. Run `code/03_descriptives.do` to produce the tables and figures

The final panel matches published NCES Digest of Education Statistics totals within 2% for every year.



