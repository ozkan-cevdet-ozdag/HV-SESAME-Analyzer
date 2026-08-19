# HV-SESAME Analyzer

HV-SESAME Analyzer is a MATLAB-based graphical application developed for automated quality assessment of Horizontal-to-Vertical Spectral Ratio (HVSR) measurements according to the SESAME (2004) recommendations.

The software is designed for project-scale quality control of HVSR datasets processed using Geopsy. It reads paired `.hv` and `.log` files, evaluates the SESAME reliability and clear-peak criteria, calculates quality scores, assigns quality classes, and provides project-level visualization and reporting tools.

The software was developed in connection with the manuscript:

"HV-SESAME Analyzer: An Automated MATLAB-Based Software for Standardized SESAME Quality Assessment of Project-Scale HVSR Datasets"

## Main Features

HV-SESAME Analyzer provides:

- Direct import of paired Geopsy `.hv` and `.log` files
- Automated evaluation of the nine SESAME quality criteria (V1–V9)
- Separate evaluation of Reliability Criteria (V1–V3) and Clear-Peak Criteria (V4–V9)
- Calculation of normalized Reliability Score (RS)
- Calculation of normalized Clear-Peak Score (CPS)
- Calculation of a weighted Quality Score (QS)
- Classification of measurements as Accepted, Controlled Acceptance, or Rejected
- Interactive visualization of individual H/V curves
- Criterion-level pass/fail inspection
- Project-level quality statistics
- Standardized PDF report generation
- GIS-compatible shapefile export
- Google Earth KMZ export
- Project saving and reloading
- Optional import of station coordinates for spatial visualization

## SESAME Quality Assessment

Each SESAME criterion is evaluated automatically and assigned a binary result:

- PASS = 1
- FAIL = 0

### Reliability Criteria

The Reliability group consists of criteria V1–V3.

The normalized Reliability Score is:

RS = (V1 + V2 + V3) / 3

The Reliability group is considered satisfied only when all three criteria are fulfilled.

### Clear-Peak Criteria

The Clear-Peak group consists of criteria V4–V9.

The normalized Clear-Peak Score is:

CPS = (V4 + V5 + V6 + V7 + V8 + V9) / 6

In accordance with the SESAME (2004) recommendations, the Clear-Peak group is considered satisfied when at least five of the six clear-peak criteria are fulfilled.

### Quality Score

For project-level reporting and visualization, the software calculates:

QS = 0.40 × RS + 0.60 × CPS

The Quality Score is a descriptive metric and is not used as the threshold for final quality classification.

### Final Quality Classification

The final classification is determined from the group-level Reliability and Clear-Peak assessments:

- Accepted: both the Reliability and Clear-Peak groups satisfy their respective requirements.
- Controlled Acceptance: only one of the two criterion groups satisfies its requirement.
- Rejected: neither criterion group satisfies its requirement.

These three quality classes are implemented as a software-level decision framework for project-oriented reporting and do not constitute additional SESAME criteria or modifications to the original SESAME recommendations.

## Requirements

The source-code version of HV-SESAME Analyzer requires:

- MATLAB R2026a
- Microsoft Windows 11 (64-bit) was used for development and testing
- Geopsy-generated `.hv` and `.log` files

No additional MATLAB toolboxes are required for routine operation.

Ghostscript is optional and is used only for automatically combining multiple report pages into a single PDF document. If Ghostscript is not installed, the report pages can still be generated individually.

## Repository Contents

The repository contains:

- `HV_SESAME_ANALYZER_V1.m` — main MATLAB source code
- `README.md` — software description and quick-test instructions
- `User_Guide.md` — detailed user instructions
- `Example Data/` — example Geopsy `.hv` and `.log` files for testing
- `LICENSE` — open-source software license
- `CITATION.cff` — citation information

## Quick Test

A small example dataset is included in the `Example Data` directory so that the main workflow can be tested without preparing a new HVSR dataset.

### Running the Quick Test

1. Download or clone this repository.

2. Open MATLAB R2026a.

3. Set the downloaded repository directory as the MATLAB Current Folder.

4. Run:

   `HV_SESAME_ANALYZER_V1.m`

5. In the graphical user interface, select the project-analysis workflow.

6. When prompted for the input data, select the paired `.hv` and `.log` files provided in the `Example Data` directory.

7. If spatial visualization is required, use the example coordinate information provided with the example dataset and define the appropriate UTM zone when prompted.

8. Start the analysis.

The software will automatically:

- validate the selected input files,
- extract the required parameters from the Geopsy outputs,
- evaluate SESAME criteria V1–V9,
- calculate RS, CPS, and QS,
- determine the Reliability and Clear-Peak group-level results,
- assign the final quality class, and
- display the results within the graphical interface.

The individual H/V curves and criterion-level PASS/FAIL results can then be inspected through the application interface. Project reports and spatial outputs can also be generated using the corresponding export functions.

## Input Data

HV-SESAME Analyzer operates on output files generated by Geopsy.

For each measurement, a corresponding pair of files is required:

- `.hv` — H/V spectral-ratio results
- `.log` — processing information required for the SESAME quality assessment

The base filenames of the `.hv` and `.log` files should correspond to the same measurement.

Optional station-coordinate information can be imported for project mapping and GIS/KMZ generation.

## Output Products

Depending on the selected workflow and available coordinate information, HV-SESAME Analyzer can generate:

- station-level SESAME quality-assessment results,
- Reliability Score (RS),
- Clear-Peak Score (CPS),
- weighted Quality Score (QS),
- Accepted / Controlled Acceptance / Rejected classifications,
- project-level statistical summaries,
- PDF reports*,
- GIS-compatible shapefiles*,
- Google Earth KMZ files*, and
- reusable project files*.

* All example outputs can be found at "Example Data" folder.
  
## Reproducibility

The software preserves criterion-level results for each measurement, allowing the final classification to be traced back to the corresponding SESAME V1–V9 evaluations.

The example dataset supplied with this repository is intended to allow users and reviewers to reproduce the basic software workflow and verify the automated quality-assessment procedure.

## Documentation

Additional instructions for using the software are available in:

`HV_SESAME_Analyzer_V1_User_Guide.pdf`

## Source Code Availability

The complete MATLAB source code is provided openly in this repository as individual source files and can be downloaded without authentication.

The software is intended to support transparent and reproducible application of the SESAME quality-assessment procedure to Geopsy-generated HVSR datasets.

## License

HV-SESAME Analyzer is distributed under the MIT License.

See the `LICENSE` file for details.

## Citation

Citation metadata are provided in the `CITATION.cff` file included in this repository.

If you use HV-SESAME Analyzer in scientific research, please cite the associated publication once the final bibliographic information becomes available.

## Author

Özkan Cevdet Özdağ, PhD
Assistant Professor
Department of Geophysical Engineering  
Dokuz Eylül University  
Türkiye

## References

SESAME Project (2004). Guidelines for the implementation of the H/V spectral ratio technique on ambient vibrations: measurements, processing and interpretation. SESAME European Research Project, Deliverable D23.12.

Wathelet, M., Chatelain, J.-L., Cornou, C., Di Giulio, G., Guillier, B., Ohrnberger, M., Savvaidis, A. (2020). Geopsy: A user-friendly open-source tool set for ambient vibration processing. Seismological Research Letters, 91, 1878–1889.
