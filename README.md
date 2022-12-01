This repository includes reports of the projects scanned and implementation of the approach used in the paper `Detecting Outdated Code Element References in Software Repository Documentation`. To scan for outdated code element references in other GitHub projects, follow the steps below:

### Setup
1. Add a list of GitHub projects to scan in `new_projects.txt`
2. Clone the projects with `bash src/clone_projects.sh`

### Normal analysis
1. Run the analysis with `bash src/normal_analysis.sh`
2. Generate the report with `python3 src/normal_report.py`

### Extended analysis
1. Run the extended analysis with `bash src/extended_analysis.sh`
2. Generate the extended report with `python3 src/extended_report.py`
