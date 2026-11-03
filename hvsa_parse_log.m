function windows = hvsa_parse_log(filename)
%HVSA_PARSE_LOG Read selected Geopsy time windows and their lengths.
%   Identifies the 'Time Windows' section and parses the rows following
%   the '# Start time ... Window length' header. Does not use fixed row
%   numbers or regular-expression word-boundary assumptions.
%
%   Returns fields: file, lengths, count, totalDuration, declaredCount.
%
fid = fopen(filename,'rt');
if fid < 0
    error('HVSA:CannotOpen','Cannot open %s.',filename);
end
cleanup = onCleanup(@()fclose(fid)); %#ok<NASGU>

lengths = zeros(0,1);
inWindowSection = false;
inDataTable = false;
declaredCount = NaN;

while ~feof(fid)
    rawLine = fgetl(fid);
    if ~ischar(rawLine)
        break;
    end
    line = strtrim(rawLine);
    lineLower = lower(line);

    % This label distinguishes the selected-window table from the
    % parameters and the earlier 'Windowing Log' section.
    if ~inWindowSection
        if strcmpi(line,'### Time Windows ###')
            inWindowSection = true;
        end
        continue;
    end

    if strcmpi(line,'### End Time Windows ###')
        break;
    end

    if ~inDataTable
        if startsWith(lineLower,'# number')
            equalsAt = strfind(line,'=');
            if ~isempty(equalsAt)
                declaredCount = str2double(strtrim(line(equalsAt(1)+1:end)));
            end
        elseif startsWith(line,'#') && ...
                contains(lineLower,'start time') && ...
                contains(lineLower,'window length')
            inDataTable = true;
        end
        continue;
    end

    if isempty(line) || startsWith(line,'#')
        continue;
    end

    fields = strsplit(line);  % Timestamp, timestamp, duration (seconds).
    if numel(fields) ~= 3
        error('HVSA:BadLogRow', ...
            'Expected 3 columns in selected-window row: %s (%s).',line,filename);
    end
    seconds = str2double(fields{3});
    if ~(isfinite(seconds) && seconds > 0)
        error('HVSA:BadWindowLength', ...
            'Invalid selected-window duration in %s: %s.',filename,line);
    end
    lengths(end+1,1) = seconds; %#ok<AGROW>
end

if ~inWindowSection
    error('HVSA:MissingWindowSection', ...
        'Geopsy LOG does not contain a Time Windows section: %s.',filename);
end
if ~inDataTable
    error('HVSA:MissingWindowHeader', ...
        'Geopsy LOG is missing the selected-window column header: %s.',filename);
end
if isempty(lengths)
    error('HVSA:NoSelectedWindows', ...
        'No selected-window rows found in Geopsy LOG %s.',filename);
end
if isfinite(declaredCount) && declaredCount ~= numel(lengths)
    error('HVSA:DeclaredWindowMismatch', ...
        'Geopsy LOG declares %d windows, but %d rows were parsed in %s.', ...
        declaredCount,numel(lengths),filename);
end

windows.file = filename;
windows.lengths = lengths;
windows.count = numel(lengths);
windows.totalDuration = sum(lengths);
windows.declaredCount = declaredCount;
end
