function spectrum = hvsa_parse_hv(filename)
%HVSA_PARSE_HV Read Geopsy HVSR spectrum using documented text labels.
%   This parser is designed from the Geopsy text format, not fixed row numbers.
%   It validates mandatory metadata and four numerical spectrum columns.
%
%   The frequency-range maxima in the Geopsy header are retained, even when
%   the reported f0 is not the global maximum of the displayed mean curve.

lines = hvsa_read_text_lines(filename);
meta = struct('windows',[], 'f0',[], 'windowsForF0',[], ...
              'f0Windows',[], 'amplitude',[]);
frequencyHeader = 0;

for k = 1:numel(lines)
    item = strtrim(lines{k});
    if ~startsWith(item,'#')
        continue;
    end
    item = strtrim(regexprep(item,'^#\s*',''));
    if startsWith(lower(item),'frequency')
        frequencyHeader = k;
        break;
    end
    meta.windows = readField(item,'number of windows',meta.windows);
    meta.f0 = readField(item,'f0 from average',meta.f0);
    meta.windowsForF0 = readField(item,'number of windows for f0',meta.windowsForF0);
    meta.f0Windows = readField(item,'f0 from windows',meta.f0Windows);
    meta.amplitude = readField(item,'peak amplitude',meta.amplitude);
end

if frequencyHeader == 0
    error('HVSA:MissingTable','Missing Geopsy frequency-table header in %s.',filename);
end
mandatory = {'windows','f0','f0Windows','amplitude'};
for j = 1:numel(mandatory)
    if isempty(meta.(mandatory{j}))
        error('HVSA:MissingMetadata','Missing Geopsy header field %s in %s.',mandatory{j},filename);
    end
end
if numel(meta.windows)~=1 || numel(meta.f0)~=1 || numel(meta.amplitude)~=1 || numel(meta.f0Windows)~=3
    error('HVSA:MetadataShape','Unexpected number of values in Geopsy header: %s.',filename);
end
if meta.windows < 1 || floor(meta.windows) ~= meta.windows || ...
        ~(isfinite(meta.f0) && meta.f0 > 0 && isfinite(meta.amplitude) && meta.amplitude > 0)
    error('HVSA:InvalidMetadata','Invalid windows, peak frequency, or amplitude in %s.',filename);
end
winStats = meta.f0Windows;
if any(~isfinite(winStats)) || winStats(2)>winStats(1) || winStats(1)>winStats(3)
    error('HVSA:BadFrequencyStatistics','Inconsistent f0-from-windows statistics in %s.',filename);
end

samples = zeros(0,4);
for k = frequencyHeader+1:numel(lines)
    row = strtrim(lines{k});
    if isempty(row)
        continue;
    end
    if startsWith(row,'#')
        break;
    end
    nums = sscanf(row,'%f').';
    if numel(nums) ~= 4 || any(~isfinite(nums))
        error('HVSA:BadSpectrumRow','Invalid spectrum row at line %d in %s.',k,filename);
    end
    samples(end+1,:) = nums; %#ok<AGROW>
end
if size(samples,1)<3 || any(samples(:,1)<=0) || any(diff(samples(:,1))<=0) || any(samples(:,2:4)<=0,'all')
    error('HVSA:InvalidSpectrum','Spectral frequencies/amplitudes are invalid in %s.',filename);
end

spectrum.file = filename;
spectrum.nWindows = meta.windows;
spectrum.nWindowsForF0 = meta.windowsForF0;
spectrum.f0 = meta.f0;
spectrum.A0 = meta.amplitude;
spectrum.f0WindowMean = winStats(1);
spectrum.f0WindowLower = winStats(2);
spectrum.f0WindowUpper = winStats(3);
spectrum.freq = samples(:,1);
spectrum.meanHV = samples(:,2);
spectrum.lowHV = samples(:,3);
spectrum.highHV = samples(:,4);
end

function numbers = readField(line,label,numbers)
if ~startsWith(lower(line),label)
    return;
end
remainder = line(numel(label)+1:end);
if isempty(remainder) || ~ismember(remainder(1),[' ' sprintf('\t') '='])
    return;
end
suffix = strtrim(remainder);
if startsWith(suffix,'=')
    suffix = strtrim(suffix(2:end));
end
if isempty(regexp(suffix,'^[+-]?(?:\d|\.)','once'))
    return;
end
numbers = sscanf(suffix,'%f').';
end

function lines = hvsa_read_text_lines(filename)
fid = fopen(filename,'rt');
if fid < 0
    error('HVSA:CannotOpen','Cannot open %s.',filename);
end
cleanup = onCleanup(@()fclose(fid)); %#ok<NASGU>
lines = cell(0,1);
while ~feof(fid)
    item = fgetl(fid);
    if ischar(item)
        lines{end+1,1} = item; %#ok<AGROW>
    end
end
end
