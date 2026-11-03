function [epsilonF,thetaA] = hvsa_thresholds(f0)
%HVSA_THRESHOLDS SESAME (2004), interpretation diagram Section 2.1.
%   Lower boundaries included: [0.2, 0.5, 1.0, 2.0] Hz.
validateattributes(f0,{'numeric'},{'scalar','finite','positive'});
if f0 < 0.2
    epsilonF = 0.25*f0; thetaA = 3.0;
elseif f0 < 0.5
    epsilonF = 0.20*f0; thetaA = 2.5;
elseif f0 < 1.0
    epsilonF = 0.15*f0; thetaA = 2.0;
elseif f0 < 2.0
    epsilonF = 0.10*f0; thetaA = 1.78;
else
    epsilonF = 0.05*f0; thetaA = 1.58;
end
end
