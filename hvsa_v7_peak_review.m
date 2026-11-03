function out = hvsa_v7_peak_review(freq,lowHV,highHV,f0)
%HVSA_V7_PEAK_REVIEW Reviewer 3 / Comment 1: transparent V7 peak-selection audit.
%
% READ-ONLY SCIENTIFIC DIAGNOSTIC. DOES NOT REPLACE hvsa_evaluate_sesame.
% Does not smooth, resample, interpolate, extrapolate, or modify the input.
% All peaks are selected at ORIGINAL measured frequency samples.
%
% V7 in SESAME (2004, section 3.3.1, criterion iv) requires the peaks
% of the mean +/- one-SD curves to be within +/-5%% of selected Geopsy f0.
% SESAME does NOT specify a unique algorithm for competing local peaks.
%
% Two explicit policies are compared:
% (1) v1.1.3: absolute maximum in the entire supplied frequency band;
%     ties -> earliest frequency sample; endpoint can be selected.
% (2) Audit candidate: highest strictly INTERIOR local maximum of each
%     original SD-envelope curve. Plateaus: middle sample (earlier middle
%     for even-length plateau). Same-height alternatives: earliest sample.
%     Boundary samples are not interior peaks.
%
% If candidate and baseline disagree, if global maximum is at a boundary,
% if an interior peak cannot be identified, or if tie/plateau ambiguity
% occurs, manual expert review is explicitly recommended. Candidate is NOT
% automatically accepted into the application classification.
%
% NOT a geological identification of fundamental frequency or secondary peaks.

f = freq(:); lo = lowHV(:); hi = highHV(:);
if ~isnumeric(f0) || ~isscalar(f0) || ~isfinite(f0) || f0<=0 || ...
        numel(f)<3 || numel(f)~=numel(lo) || numel(f)~=numel(hi) || ...
        any(~isfinite([f;lo;hi])) || any(f<=0) || ...
        any(diff(f)<=0) || any([lo;hi]<=0)
    error('HVSA:V7InvalidInput','Invalid V7 frequency/amplitude vectors or f0.');
end

[gLoAmp,gLo] = max(lo); %#ok<ASGLU>
[gHiAmp,gHi] = max(hi); %#ok<ASGLU>
[loIdx,loWidths] = local_maxima_original_samples(lo);
[hiIdx,hiWidths] = local_maxima_original_samples(hi);
[pLo,wLo,tLo] = dominant_interior(lo,loIdx,loWidths);
[pHi,wHi,tHi] = dominant_interior(hi,hiIdx,hiWidths);

inside = @(x) isfinite(x) && abs(x-f0) <= 0.05*f0;
baseline = inside(f(gLo)) && inside(f(gHi));
if isfinite(pLo) && isfinite(pHi)
    candidate = inside(f(pLo)) && inside(f(pHi));
    candidateStatus = ternary(candidate,'PASS','FAIL');
else
    candidate = false;
    candidateStatus = 'NO_INTERIOR_PEAK';
end
boundary = any([gLo,gHi]==1) || any([gLo,gHi]==numel(f));
plateauOrTie = (wLo>1 || wHi>1 || tLo || tHi);
changed = ~strcmp(candidateStatus,'NO_INTERIOR_PEAK') && (baseline~=candidate);
reasons = {};
if boundary, reasons{end+1} = 'GLOBAL_MAXIMUM_AT_BAND_EDGE'; end %#ok<AGROW>
if strcmp(candidateStatus,'NO_INTERIOR_PEAK')
    reasons{end+1} = 'NO_INTERIOR_LOCAL_MAXIMUM'; %#ok<AGROW>
end
if changed, reasons{end+1} = 'GLOBAL_INTERIOR_V7_CONFLICT'; end %#ok<AGROW>
if plateauOrTie, reasons{end+1} = 'PLATEAU_OR_TIED_DOMINANT_LOCAL_MAXIMUM'; end %#ok<AGROW>
if isempty(reasons), reasons = {'NONE'}; end

out = struct();
out.f0 = f0;
out.v7LowerLimit = 0.95*f0;
out.v7UpperLimit = 1.05*f0;
out.originalGlobalLowFrequency = f(gLo);
out.originalGlobalHighFrequency = f(gHi);
out.originalGlobalPass = logical(baseline);
out.highestInteriorLowFrequency = idx_or_nan(f,pLo);
out.highestInteriorHighFrequency = idx_or_nan(f,pHi);
out.highestInteriorDecision = candidateStatus;
out.highestInteriorPassIfAssessable = candidate;
out.interiorLowPeakCount = numel(loIdx);
out.interiorHighPeakCount = numel(hiIdx);
out.originalGlobalAtBandEdge = boundary;
out.interiorDominantPlateauOrTie = plateauOrTie;
out.globalInteriorVerdictConflict = changed;
out.manualReviewRecommended = boundary || plateauOrTie || changed || ...
    strcmp(candidateStatus,'NO_INTERIOR_PEAK');
out.reviewReason = strjoin(reasons,';');
out.selectionPolicy = ['Baseline: whole-band global maximum. ' ...
    'Candidate: highest interior local maximum (no interpolation).'];
out.sesameSelectionPrescribed = false;
out.originalDataModified = false;
end

function [peaks,widths] = local_maxima_original_samples(a)
% Strict interior local maxima; contiguous exact flat plateau is one peak.
peaks = zeros(0,1); widths = zeros(0,1);
n = numel(a); k = 2;
while k<n
    z = k;
    while z<n && a(z+1)==a(k)
        z=z+1;
    end
    if a(k)>a(k-1) && z<n && a(z)>a(z+1)
        peaks(end+1,1) = floor((k+z)/2); %#ok<AGROW>
        widths(end+1,1) = z-k+1; %#ok<AGROW>
    end
    k = max(k+1,z+1);
end
end

function [p,w,hasTie] = dominant_interior(a,indices,widths)
p=NaN; w=0; hasTie=false;
if isempty(indices), return; end
v=a(indices); maxv=max(v);
selected=find(v==maxv);
% local_maxima returns indices in ascending frequency order.
p=indices(selected(1));
w=widths(selected(1));
hasTie=numel(selected)>1;
end

function x = idx_or_nan(v,i)
if isfinite(i), x=v(i); else, x=NaN; end
end

function y = ternary(cond,onTrue,onFalse)
if cond, y=onTrue; else, y=onFalse; end
end
