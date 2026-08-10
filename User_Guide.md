# HV-SESAME Analyzer — User Guide

## 1. Overview

HV-SESAME Analyzer is a MATLAB-based graphical application developed for automated quality assessment of Horizontal-to-Vertical Spectral Ratio (HVSR) measurements according to the SESAME (2004) recommendations.

The software is designed primarily for project-scale HVSR investigations processed using Geopsy. It imports paired `.hv` and `.log` files, extracts the parameters required for quality assessment, evaluates the SESAME reliability and clear-peak criteria, and assigns a quality classification to each measurement.

HV-SESAME Analyzer is intended as a quality-assurance and decision-support environment. It does not replace expert geological or geophysical interpretation of HVSR curves.

---

## 2. System Requirements

The current version was developed and tested using:

- MATLAB R2026a
- Microsoft Windows 11 (64-bit)

No additional MATLAB toolboxes are required for routine operation.

Ghostscript is optional. It is used to automatically combine multiple report pages into a single PDF document. If Ghostscript is unavailable, individual report pages can still be generated.

---

## 3. Starting the Application

Download or clone the repository and open MATLAB.

Run:

`HV_SESAME_ANALYZER_V1.m`

The graphical user interface will open automatically.

---

## 4. Required Input Files

Each HVSR measurement requires two corresponding Geopsy output files:

- `.hv` — contains the calculated H/V spectral ratio
- `.log` — contains processing parameters and measurement metadata

The `.hv` and `.log` files belonging to the same measurement should use consistent station/file naming.

Example:

`Station01.hv`

`Station01.log`

HV-SESAME Analyzer validates the selected files before performing the quality assessment.

---

## 5. Coordinate Data

Coordinate information is optional.

A coordinate file can be imported when spatial visualization, GIS export, or Google Earth output is required.

The coordinate file should contain:

`X    Y    Z    Name`

where:

- `X` = UTM Easting
- `Y` = UTM Northing
- `Z` = elevation
- `Name` = station identifier

Example:

`450123.55    4578123.21    105.3    Station01`

The appropriate UTM zone and hemisphere must be selected in the application before spatial export.

Station names in the coordinate file should correspond to the measurement names used in the imported dataset.

---

## 6. Basic Workflow

A typical HV-SESAME Analyzer workflow consists of the following steps:

1. Start HV-SESAME Analyzer.
2. Select the Geopsy `.hv` files.
3. Select the corresponding `.log` files.
4. Import the coordinate file if spatial outputs are required.
5. Define the appropriate UTM zone and hemisphere.
6. Run the automated quality assessment.
7. Review station-level HVSR curves and SESAME criterion results.
8. Examine project-level quality statistics.
9. Generate the required reports and spatial outputs.
10. Save the project if the analysis will be reviewed later.

---

## 7. SESAME Quality Assessment

HV-SESAME Analyzer evaluates nine SESAME quality criteria.

### 7.1 Reliability Criteria

The reliability assessment consists of criteria V1–V3.

#### V1 — Window Length

The selected analysis window must be sufficiently long relative to the fundamental resonance frequency.

The criterion is evaluated using:

`f0 > 10 / Iw`

where:

- `f0` = fundamental resonance frequency
- `Iw` = analysis window length

#### V2 — Number of Significant Cycles

The number of significant cycles is calculated as:

`Nc = Iw × Nw × f0`

where:

- `Iw` = window length
- `Nw` = number of accepted windows
- `f0` = fundamental resonance frequency

The criterion is satisfied when:

`Nc > 200`

#### V3 — Spectral Stability

V3 evaluates the stability of the H/V curve around the fundamental resonance frequency according to the applicable SESAME threshold.

---

### 7.2 Clear-Peak Criteria

The clear-peak assessment consists of criteria V4–V9.

#### V4 and V5 — Spectral Minima

The software evaluates the spectral minima before and after the fundamental resonance peak.

The corresponding condition is:

`Amin < A0 / 2`

where:

- `Amin` = spectral minimum
- `A0` = amplitude at the fundamental resonance peak

#### V6 — Peak Amplitude

The resonance peak must satisfy:

`A0 > 2`

#### V7 — Dominant Spectral Maximum

The dominant H/V maximum is evaluated relative to the estimated fundamental resonance frequency.

#### V8 — Frequency Stability

The stability of the estimated fundamental resonance frequency is evaluated according to the corresponding SESAME limit.

#### V9 — Amplitude Stability

The variability of the H/V amplitude at the fundamental resonance frequency is evaluated according to the applicable SESAME threshold.

---

## 8. Quality Scores

For each measurement, HV-SESAME Analyzer calculates three summary scores.

### Reliability Score

`RS = (V1 + V2 + V3) / 3`

### Clear-Peak Score

`CPS = (V4 + V5 + V6 + V7 + V8 + V9) / 6`

### Quality Score

`QS = 0.40 × RS + 0.60 × CPS`

The Quality Score provides a continuous summary of criterion satisfaction.

It is not used as the threshold for determining the final quality class.

---

## 9. Final Quality Classification

The final classification is determined from the complete reliability and clear-peak assessments.

### Accepted

All Reliability Criteria (V1–V3) and all Clear-Peak Criteria (V4–V9) are satisfied.

### Controlled Acceptance

One complete criterion group is satisfied while the other criterion group is not fully satisfied.

Measurements in this category should be reviewed by the user before geological or engineering interpretation.

### Rejected

Neither the Reliability Criteria group nor the Clear-Peak Criteria group is fully satisfied.

The final classification should be interpreted as a quality-control result rather than a substitute for expert scientific interpretation.

---

## 10. Station-Level Inspection

Individual measurements can be inspected through the graphical interface.

For each station, the software provides information including:

- HVSR curve
- Fundamental resonance frequency (`f0`)
- Resonance amplitude (`A0`)
- SESAME criterion results
- Reliability Score
- Clear-Peak Score
- Quality Score
- Final quality classification

This view enables the user to identify which individual criteria control the final classification.

---

## 11. Project-Level Assessment

For datasets containing multiple measurements, HV-SESAME Analyzer summarizes the results at the project scale.

Project-level information includes:

- Number of processed measurements
- Distribution of quality classes
- Criterion-level pass/fail statistics
- Spatial distribution of quality classifications
- Station-level assessment results

These summaries are intended to facilitate quality assurance in engineering-scale and regional HVSR investigations.

---

## 12. Output Products

Depending on the available project information, HV-SESAME Analyzer can generate several output products.

### PDF Reports

Standardized reports can include:

- Project-level quality summaries
- Quality-class distributions
- SESAME criterion statistics
- Project maps
- Station-level assessment results
- HVSR curves and associated parameters

Ghostscript can be used to combine individual pages into a single PDF document.

### GIS Output

GIS-compatible shapefiles can be generated when valid coordinate information is available.

Spatial attributes preserve the quality-assessment information associated with each measurement.

### Google Earth Output

KMZ files can be generated for visualization of measurement locations and quality classifications in Google Earth.

### Project Files

Analysis sessions can be saved for subsequent review and continued evaluation.

---

## 13. Example Dataset

An example dataset is included in the repository.

The example files can be used to:

1. Test the application.
2. Verify file import.
3. Examine the SESAME assessment workflow.
4. Explore station-level results.
5. Test project-level reporting and export functions.

Users are encouraged to test the software with the supplied example data before processing their own project datasets.

---

## 14. Recommended Use

HV-SESAME Analyzer should be used as a quality-assurance tool within a broader HVSR interpretation workflow.

An Accepted classification indicates that the implemented SESAME quality conditions have been satisfied. It does not by itself establish the geological origin of an observed spectral peak.

Similarly, Controlled Acceptance identifies measurements requiring additional expert review rather than automatically defining them as suitable or unsuitable for geological interpretation.

Users should consider geological setting, acquisition conditions, spectral characteristics, complementary geophysical information, and other relevant site information when interpreting HVSR results.

---

## 15. Reproducibility

The software applies the same automated assessment procedure to every imported measurement.

For each measurement, the workflow preserves the relationship among:

- Original Geopsy input files
- Extracted processing parameters
- Individual SESAME criterion results
- Quality scores
- Final quality classification
- Spatial information, when available

This structure is intended to support transparent and reproducible project-scale quality assessment.

---

## 16. Limitations

The current release:

- Is designed for HVSR outputs generated by Geopsy.
- Requires paired `.hv` and `.log` files.
- Implements the SESAME (2004) quality criteria.
- Does not perform raw ambient-vibration signal preprocessing.
- Does not calculate the original H/V spectrum from raw seismic recordings.
- Does not replace expert geological or geophysical interpretation.

Future versions may expand support for additional HVSR processing formats and quality-assessment approaches.

---

## 17. Citation

If HV-SESAME Analyzer is used in scientific research or engineering applications, please cite the software.

Citation metadata are provided in:

`CITATION.cff`

Citation information for the associated scientific publication will be added following publication.

---

## 18. License

HV-SESAME Analyzer is distributed under the MIT License.

See the `LICENSE` file included in this repository for details.

---

## 19. Author

Özkan Cevdet Özdağ, Ph.D.  
Assistant Professor  
Department of Geophysical Engineering  
Faculty of Engineering  
Dokuz Eylül University  
İzmir, Türkiye

---

## 20. References

SESAME Project (2004). Guidelines for the implementation of the H/V spectral ratio technique on ambient vibrations: Measurements, processing and interpretation.

Wathelet, M., Chatelain, J.-L., Cornou, C., Di Giulio, G., Guillier, B., Ohrnberger, M., and Savvaidis, A. (2020). Geopsy: A user-friendly open-source tool set for ambient vibration processing. Seismological Research Letters, 91(3), 1878–1889.
