function peak = hvsa_global_peak(frequency,amplitude)
%HVSA_GLOBAL_PEAK Deterministic maximum over the supplied spectral band.
%   First of any equal-valued maxima is selected. This is NOT a physical
%   identification of the fundamental resonance on a multi-peak curve.

if numel(frequency)~=numel(amplitude) || isempty(frequency) || any(~isfinite(amplitude))
    error('HVSA:BadPeakInput','Peak search requires finite matched vectors.');
end
[maxAmplitude,index] = max(amplitude);
peak.index = index;
peak.frequency = frequency(index);
peak.amplitude = maxAmplitude;
peak.numberOfEqualMaxima = nnz(amplitude==maxAmplitude);
peak.hasTiedMaximum = peak.numberOfEqualMaxima>1;
peak.isEndpoint = index==1 || index==numel(amplitude);
end
