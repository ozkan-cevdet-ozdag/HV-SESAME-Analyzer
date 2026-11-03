function result = hvsa_evaluate_sesame(spectrum,windows)
%HVSA_EVALUATE_SESAME SESAME (2004) V1-V9 from labelled Geopsy data.
%   Original implementation based on the published quantitative conditions.
%   No spectral processing, alternative peak recognition or geological
%   plausibility interpretation is performed here.
%
%   In the accepted intermediate class, exactly one criterion group passes;
%   that class is application-specific, not a SESAME acceptance category.

if spectrum.nWindows ~= windows.count
    error('HVSA:WindowMismatch','HV window count (%d) differs from LOG (%d).', ...
          spectrum.nWindows,windows.count);
end
f0 = spectrum.f0;
f = spectrum.freq;
meanA = spectrum.meanHV;
lo = spectrum.lowHV;
hi = spectrum.highHV;
A0 = spectrum.A0;

% The plotted low/high curves delimit a multiplicative amplitude factor.
variability = hi./meanA;
if any(~isfinite(variability)) || any(variability<=0)
    error('HVSA:InvalidVariability','Invalid H/V variability factor.');
end

% SESAME statistical frequency spread comes ONLY from window-peak statistics.
sigmaF = spectrum.f0WindowMean - spectrum.f0WindowLower;
[epsilonF,thetaA] = hvsa_thresholds(f0);

mask = (f>0.5*f0 & f<2*f0);
if ~any(mask)
    % No evidence to establish the within-band stability criterion.
    isStableAmplitude = false;
else
    if f0 >= 0.5
        amplitudeLimit = 2;
    else
        amplitudeLimit = 3;
    end
    isStableAmplitude = all(variability(mask)<amplitudeLimit);
end

lowerSide = (f>=f0/4 & f<=f0);
upperSide = (f>=f0 & f<=4*f0);
peakLower = hvsa_global_peak(f,lo);
peakUpper = hvsa_global_peak(f,hi);
withinFivePercent = @(peakFrequency) abs(peakFrequency-f0)<=0.05*f0;

% Geopsy peak estimate may not be at the absolute highest plotted sample.
% V9 samples the multiplicative variability at the selected f0, not at a
% different global maximum of the mean H/V curve.
[~,selectedRow] = min(abs(f-f0));
flags = [ ...
    all(f0 > 10./windows.lengths), ...          % V1
    f0 * windows.totalDuration > 200, ...      % V2
    isStableAmplitude, ...                      % V3
    any(meanA(lowerSide)<A0/2), ...            % V4
    any(meanA(upperSide)<A0/2), ...            % V5
    A0 > 2, ...                                 % V6
    withinFivePercent(peakLower.frequency) && withinFivePercent(peakUpper.frequency), ... % V7
    sigmaF < epsilonF, ...                      % V8
    variability(selectedRow) < thetaA ...      % V9
];
crit = struct();
for n = 1:9
    crit.(sprintf('V%d',n)) = logical(flags(n));
end
crit.reliable = all(flags(1:3));
crit.clear = nnz(flags(4:9)) >= 5;
crit.controlled = xor(crit.reliable,crit.clear);
crit.allPass = crit.reliable && crit.clear;

result = struct();
result.f0 = f0;
result.T0 = 1/f0;
result.A0 = A0;
result.sf = sigmaF;          % Existing app and HSAP field, retained.
result.sigma_f = sigmaF;
result.f0WindowMean = spectrum.f0WindowMean;
result.f0WindowLower = spectrum.f0WindowLower;
result.f0WindowUpper = spectrum.f0WindowUpper;
result.nc = f0 * windows.totalDuration;
result.Iw = windows.lengths;
result.tab = [f meanA lo hi variability];
result.f0a = 1.05*f0;
result.f0b = 0.95*f0;
result.criteria = crit;
result.criterionThresholds = struct('epsilon',epsilonF,'theta',thetaA);
% Reviewer 3, Comment 1: retain the original conservative global-maximum
% V7 verdict, but expose a separate reproducible interior-peak diagnostic.
% This diagnostic NEVER replaces flags(7), modifies source samples or
% automatically changes the three-class decision. Uncertain cases require
% expert inspection before geological interpretation.
v7Audit = hvsa_v7_peak_review(f,lo,hi,f0);
assert(v7Audit.originalGlobalPass == flags(7), ...
       'HVSA:V7AuditMismatch', ...
       'Reviewer V7 diagnostic disagrees with baseline V7 calculation.');
result.peakDiagnostics = struct('low',peakLower,'high',peakUpper, ...
    'selection','Global maximum of each standard-deviation curve; first sample for ties', ...
    'multiplePeakInterpretationPerformed',false, ...
    'v7Audit',v7Audit, ...
    'manualReviewRecommended',v7Audit.manualReviewRecommended, ...
    'reviewReason',v7Audit.reviewReason);

end
