HV-SESAME Analyzer GIS Export
================================

Export date: 2026-08-19 12:11:37
Coordinate system: WGS84 / UTM Zone 36N
Export mode: Accepted + Controlled Acceptance

Included stations: 28
Original station count: 32

Included status classes:
  - Accepted
  - Controlled Acceptance

Excluded status classes:
  - Rejected

Note:
Rejected stations are intentionally excluded from this GIS layer to prevent
low-quality H/V results from being used directly in interpolation or mapping.

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
