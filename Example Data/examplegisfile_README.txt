HV-SESAME Analyzer GIS Export
================================

Export date: 2026-11-03 13:41:41
Coordinate system: WGS84 / UTM Zone 36N
Export mode: All Stations

Included stations: 32
Original station count: 32

Included status classes:
  - Accepted
  - Controlled Acceptance
  - Rejected

Note:
This export includes rejected stations. Use the Status field to filter them
before interpolation or thematic mapping if required.

Attributes:
  Name      : Station name
  Status    : Accepted, Controlled or Rejected
  f0_Hz     : H/V peak frequency in Hz
  T0_s      : H/V peak period in seconds
  A0        : H/V peak amplitude
  RelPct    : Reliability score in percent
  ClrPct    : Clear Peak score in percent
  RelClass  : Reliability class
  ClrClass  : Clear Peak class
  X_UTM     : UTM Easting
  Y_UTM     : UTM Northing
  Z         : Elevation
  V1-V9     : Individual SESAME criterion results (1=PASS, 0=FAIL)
              Values are numeric in both CSV and Shapefile DBF.
              Criterion codes represent the nine checks in SESAME (2004).
  Note      : Display maps show the supplied input X/Y coordinates in kilometres.
              CSV and Shapefile retain the input UTM coordinates.
