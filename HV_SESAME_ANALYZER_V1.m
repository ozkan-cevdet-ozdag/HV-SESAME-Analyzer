function HV_SESAME_ANALYZER_V1
% HV_SESAME_ANALYZER_V1
% Modern GUI-based H/V SESAME analysis tool.
%
% Features:
%   - Single-window folder, coordinate file, and UTM zone selection
%   - Batch .hv/.log analysis
%   - Reliability = V1,V2,V3
%   - Clear Peak = V4,V5,V6,V7,V8,V9
%   - Accepted / Controlled Acceptance / Rejected classification
%   - Station list on the left
%   - H/V plot in the center
%   - Criteria panel on the right
%   - KMZ output with green/yellow/red pins
%   - PDF report using print()-based output
%
% Note:
%   Multi-page PDF output is produced page by page.
%   If Ghostscript is installed, pages are automatically merged into one PDF.
%   If Ghostscript is not available, separate PDF pages are saved.
%   Ghostscript can be installed from
%   "https://ghostscript.com/releases/gsdnld.html"
%
% Expected coordinate TXT/DAT format(seperated tab):
%   X   Y   Z   Name
%   450123.55   4578123.21   105.3   m1
%
% GEOPSY .hv and .log files must be in the same folder and have matching names:
%   m1.hv  m1.log

clc;

% ============================================================
% FORCE APPLICATION LIGHT THEME
% Prevents MATLAB Dark Mode from changing GUI, axes, and PDF colors.
% ============================================================
forceLightTheme();

APP = struct();
APP.rootDir = '';
APP.coordFile = '';
APP.utmZone = '35N';
APP.coordTable = table();
APP.results = [];
APP.finalTable = table();
APP.latlonTable = table();

APP = createMainGUI(APP);

end

%% ========================================================================
function forceLightTheme()
% Force a stable light visual theme independent of MATLAB Appearance setting.
% This is important for MATLAB R2026 dark mode and for consistent PDF export.

try
    set(groot,'defaultFigureColor',[0.96 0.97 0.98]);
    set(groot,'defaultFigureInvertHardcopy','off');

    set(groot,'defaultAxesColor','white');
    set(groot,'defaultAxesXColor','black');
    set(groot,'defaultAxesYColor','black');
    set(groot,'defaultAxesZColor','black');
    set(groot,'defaultAxesGridColor',[0.70 0.70 0.70]);
    set(groot,'defaultAxesMinorGridColor',[0.85 0.85 0.85]);
    set(groot,'defaultAxesBox','on');

    set(groot,'defaultTextColor','black');

    set(groot,'defaultUicontrolBackgroundColor','white');
    set(groot,'defaultUicontrolForegroundColor','black');
    set(groot,'defaultUipanelBackgroundColor',[0.96 0.97 0.98]);

    try
        set(groot,'defaultUitableBackgroundColor',[1 1 1; 0.97 0.98 0.99]);
        set(groot,'defaultUitableForegroundColor','black');
    catch
    end

    set(groot,'defaultLegendColor','white');
    set(groot,'defaultLegendTextColor','black');
    set(groot,'defaultLegendEdgeColor',[0.80 0.80 0.80]);
catch
    % Some default properties may not exist in all MATLAB versions.
end

end

%% ========================================================================
function applyLightThemeToFigure(figHandle)
% Apply light colors to an existing figure and its current children.

if isempty(figHandle) || ~ishandle(figHandle)
    return;
end

try
    set(figHandle,'Color',[0.96 0.97 0.98],'InvertHardcopy','off');
catch
end

try
    axList = findall(figHandle,'Type','axes');
    for k = 1:numel(axList)
        set(axList(k), ...
            'Color','white', ...
            'XColor','black', ...
            'YColor','black', ...
            'ZColor','black', ...
            'GridColor',[0.70 0.70 0.70], ...
            'MinorGridColor',[0.85 0.85 0.85]);
    end
catch
end

try
    txtList = findall(figHandle,'Type','uicontrol');
    for k = 1:numel(txtList)
        styleVal = '';
        try
            styleVal = get(txtList(k),'Style');
        catch
        end

        if strcmpi(styleVal,'pushbutton') || strcmpi(styleVal,'edit') || strcmpi(styleVal,'listbox')
            set(txtList(k),'ForegroundColor','black');
        end
    end
catch
end

end

%% ========================================================================
function applyPublicationGUIFonts(fig,APP)
% EXTRA-LARGE screenshot preset (publication Figure 3), display only.
% The analysis engine, SESAME parameters, station classifications, source
% spectral samples and output-generation functions remain unchanged.
% Best viewed on a 1920x1080 or larger monitor with the main window maximized.

try
    set(fig,'WindowState','maximized');
catch
end

% All fonts below are point sizes, not normalized scaling values.
sections = findall(fig,'Type','uipanel');
if ~isempty(sections)
    set(sections,'FontUnits','points','FontSize',15,'FontWeight','bold');
end

controls = findall(fig,'Type','uicontrol');
for ii=1:numel(controls)
    type = lower(get(controls(ii),'Style'));
    switch type
        case 'text'
            set(controls(ii),'FontUnits','points','FontSize',15);
        case 'pushbutton'
            set(controls(ii),'FontUnits','points','FontSize',15);
        case 'edit'
            set(controls(ii),'FontUnits','points','FontSize',15);
        case 'listbox'
            set(controls(ii),'FontUnits','points','FontSize',15);
    end
end

% Special controls receive deliberate sizes to prevent clipping and keep
% priority on the key SESAME results used for the published GUI screenshot.
set([APP.critNameText(:);APP.critStatusText(:)],'FontSize',15,'FontWeight','bold');
set(APP.critDescText(:),'FontSize',14);
set([APP.txtAcceptedLabel APP.txtControlledLabel APP.txtRejectedLabel], ...
    'FontSize',12.5,'FontWeight','bold');
set([APP.txtAcceptedCount APP.txtControlledCount APP.txtRejectedCount], ...
    'FontSize',22,'FontWeight','bold');
set([APP.txtStationName APP.txtOverallStatus],'FontSize',15,'FontWeight','bold');
set([APP.txtReliable APP.txtClear],'FontSize',13.5);
set([APP.txtReliabilityProgress APP.txtClearProgress], 'FontSize',13.5);
set([APP.txtReliabilityScore APP.txtClearScore], 'FontSize',12.5,'FontWeight','bold');
set([APP.lblF0 APP.lblT0 APP.lblA0], 'FontSize',12.5);
set([APP.valF0 APP.valT0 APP.valA0], 'FontSize',13.5);
set(APP.txtStationHint,'FontSize',12.5);
set(APP.btnAbout,'FontSize',13.5);

% H/V plot tick labels and axis labels use explicit point sizes. Individual
% plot annotations are assigned by the local hvsa_plot_spectrum function.
set(APP.ax,'FontUnits','points','FontSize',16);
xlabel(APP.ax,'Frequency (Hz)','FontSize',16);
ylabel(APP.ax,'H/V amplitude','FontSize',16);
title(APP.ax,'Select a station from the list after analysis.','FontSize',16);
end

%% ========================================================================
function APP = createMainGUI(APP)

fig = figure('Name','HV-SESAME Analyzer V1', ...
    'NumberTitle','off', ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'Units','normalized', ...
    'Position',[0.06 0.06 0.88 0.86], ...
    'Color',[0.96 0.97 0.98], ...
    'InvertHardcopy','off');

APP.fig = fig;

% -------------------- Workflow bar --------------------
% The top area is intentionally designed as a step-by-step workflow:
% 1) Select data folder -> 2) Select coordinates -> 3) Set UTM zone -> 4) Run analysis -> 5) Export outputs

APP.pnlWorkflow = uipanel('Parent',fig, ...
    'Title','Workflow', ...
    'Units','normalized', ...
    'Position',[0.015 0.852 0.965 0.133], ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'FontWeight','bold');

APP.step1 = uipanel('Parent',APP.pnlWorkflow, ...
    'Title','1  Data Folder', ...
    'Units','normalized', ...
    'Position',[0.010 0.10 0.165 0.82], ...
    'BackgroundColor',[0.93 0.96 1.00], ...
     'FontWeight','bold');

APP.btnFolder = uicontrol('Parent',APP.step1,'Style','pushbutton', ...
    'Units','normalized','Position',[0.08 0.17 0.84 0.63], ...
    'String','Select Folder','FontWeight','bold', ...
    'Callback',@(~,~)cbOpenFolder());

APP.step2 = uipanel('Parent',APP.pnlWorkflow, ...
    'Title','2  Coordinates', ...
    'Units','normalized', ...
    'Position',[0.185 0.10 0.175 0.82], ...
    'BackgroundColor',[0.94 0.94 0.94], ...
     'FontWeight','bold');

APP.btnCoords = uicontrol('Parent',APP.step2,'Style','pushbutton', ...
    'Units','normalized','Position',[0.08 0.17 0.84 0.63], ...
    'String','Select Coordinates','FontWeight','bold', ...
    'Enable','off', ...
    'Callback',@(~,~)cbOpenCoords());

APP.step3 = uipanel('Parent',APP.pnlWorkflow, ...
    'Title','3  UTM Zone (WGS 84)', ...
    'Units','normalized', ...
    'Position',[0.370 0.10 0.130 0.82], ...
    'BackgroundColor',[0.94 0.94 0.94], ...
     'FontWeight','bold');

APP.edtZone = uicontrol('Parent',APP.step3,'Style','edit', ...
    'Units','normalized','Position',[0.18 0.17 0.64 0.63], ...
    'String',APP.utmZone, ...
    'BackgroundColor','white', ...
    'Enable','off');

APP.step4 = uipanel('Parent',APP.pnlWorkflow, ...
    'Title','4  Analysis', ...
    'Units','normalized', ...
    'Position',[0.510 0.10 0.130 0.82], ...
    'BackgroundColor',[0.94 0.94 0.94], ...
     'FontWeight','bold');

APP.btnRun = uicontrol('Parent',APP.step4,'Style','pushbutton', ...
    'Units','normalized','Position',[0.12 0.17 0.76 0.63], ...
    'String','Run','FontWeight','bold', ...
    'BackgroundColor',[0.75 0.88 1.0], ...
    'Enable','off', ...
    'Callback',@(~,~)cbRun());

APP.step5 = uipanel('Parent',APP.pnlWorkflow, ...
    'Title','5  Outputs', ...
    'Units','normalized', ...
    'Position',[0.650 0.10 0.170 0.82], ...
    'BackgroundColor',[0.94 0.94 0.94], ...
     'FontWeight','bold');

APP.btnPDF = uicontrol('Parent',APP.step5,'Style','pushbutton', ...
    'Units','normalized','Position',[0.03 0.17 0.43 0.63], ...
    'String','PDF Report','FontWeight','bold', ...
    'Enable','off', ...
    'Callback',@(~,~)cbExportPDF());

APP.btnKMZ = uicontrol('Parent',APP.step5,'Style','pushbutton', ...
    'Units','normalized','Position',[0.49 0.17 0.21 0.63], ...
    'String','KMZ','FontWeight','bold', ...
    'Enable','off', ...
    'Callback',@(~,~)cbExportKMZ());

APP.btnGIS = uicontrol('Parent',APP.step5,'Style','pushbutton', ...
    'Units','normalized','Position',[0.73 0.17 0.24 0.63], ...
    'String','GIS','FontWeight','bold', ...
    'Enable','off', ...
    'Callback',@(~,~)cbExportGIS());

APP.step6 = uipanel('Parent',APP.pnlWorkflow, ...
    'Title','6  Project', ...
    'Units','normalized', ...
    'Position',[0.830 0.10 0.100 0.82], ...
    'BackgroundColor',[0.94 0.94 0.94], ...
     'FontWeight','bold');

APP.btnLoadProject = uicontrol('Parent',APP.step6,'Style','pushbutton', ...
    'Units','normalized','Position',[0.06 0.17 0.42 0.63], ...
    'String','Load','FontWeight','bold', ...
    'Enable','on', ...
    'Callback',@(~,~)cbLoadProject());

APP.btnSaveProject = uicontrol('Parent',APP.step6,'Style','pushbutton', ...
    'Units','normalized','Position',[0.52 0.17 0.42 0.63], ...
    'String','Save','FontWeight','bold', ...
    'Enable','off', ...
    'Callback',@(~,~)cbSaveProject());

APP.btnAbout = uicontrol('Parent',APP.pnlWorkflow,'Style','pushbutton', ...
    'Units','normalized','Position',[0.935 0.23 0.055 0.48], ...
    'String','About/Help','FontWeight','bold', ...
    'Callback',@(~,~)cbAbout());

% -------------------- Bottom logger --------------------
APP.pnlLogger = uipanel('Parent',fig,'Title','Status', ...
    'Units','normalized','Position',[0.015 0.015 0.965 0.060], ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'FontWeight','bold');

APP.txtStatus = uicontrol('Parent',APP.pnlLogger,'Style','edit', ...
    'Units','normalized','Position',[0.010 0.12 0.980 0.72], ...
    'String','Step 1: Select the *.hv and *.log data folder.', ...
    'BackgroundColor','white', ...
    'ForegroundColor',[0.10 0.10 0.10], ...
    'HorizontalAlignment','left', ...
    'Max',2, ...
    'Min',0, ...
    'Enable','inactive');

% -------------------- Left station panel --------------------
APP.pnlLeft = uipanel('Parent',fig,'Title','Stations', ...
    'Units','normalized','Position',[0.015 0.095 0.245 0.740], ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'FontWeight','bold');

% Station count cards
APP.cardAccepted = uipanel('Parent',APP.pnlLeft, ...
    'Title','', ...
    'Units','normalized','Position',[0.03 0.865 0.29 0.115], ...
    'BackgroundColor',[0.90 0.98 0.92], ...
    'BorderType','line');

APP.txtAcceptedCount = uicontrol('Parent',APP.cardAccepted,'Style','text', ...
    'Units','normalized','Position',[0.05 0.43 0.90 0.52], ...
    'String','0', ...
    'BackgroundColor',[0.90 0.98 0.92], ...
    'ForegroundColor',[0.00 0.35 0.10], ...
    'FontSize',13, ...
    'FontWeight','bold');

APP.txtAcceptedLabel = uicontrol('Parent',APP.cardAccepted,'Style','text', ...
    'Units','normalized','Position',[0.05 0.07 0.90 0.30], ...
    'String','ACCEPTED', ...
    'BackgroundColor',[0.90 0.98 0.92], ...
    'ForegroundColor',[0.00 0.35 0.10], ...
    'FontSize',8, ...
    'FontWeight','bold');

APP.cardControlled = uipanel('Parent',APP.pnlLeft, ...
    'Title','', ...
    'Units','normalized','Position',[0.355 0.865 0.29 0.115], ...
    'BackgroundColor',[1.00 0.96 0.84], ...
    'BorderType','line');

APP.txtControlledCount = uicontrol('Parent',APP.cardControlled,'Style','text', ...
    'Units','normalized','Position',[0.05 0.43 0.90 0.52], ...
    'String','0', ...
    'BackgroundColor',[1.00 0.96 0.84], ...
    'ForegroundColor',[0.65 0.38 0.00], ...
    'FontSize',13, ...
    'FontWeight','bold');

APP.txtControlledLabel = uicontrol('Parent',APP.cardControlled,'Style','text', ...
    'Units','normalized','Position',[0.05 0.07 0.90 0.30], ...
    'String','CONTROLLED', ...
    'BackgroundColor',[1.00 0.96 0.84], ...
    'ForegroundColor',[0.65 0.38 0.00], ...
    'FontSize',8, ...
    'FontWeight','bold');

APP.cardRejected = uipanel('Parent',APP.pnlLeft, ...
    'Title','', ...
    'Units','normalized','Position',[0.68 0.865 0.29 0.115], ...
    'BackgroundColor',[1.00 0.90 0.90], ...
    'BorderType','line');

APP.txtRejectedCount = uicontrol('Parent',APP.cardRejected,'Style','text', ...
    'Units','normalized','Position',[0.05 0.43 0.90 0.52], ...
    'String','0', ...
    'BackgroundColor',[1.00 0.90 0.90], ...
    'ForegroundColor',[0.60 0.00 0.00], ...
    'FontSize',13, ...
    'FontWeight','bold');

APP.txtRejectedLabel = uicontrol('Parent',APP.cardRejected,'Style','text', ...
    'Units','normalized','Position',[0.05 0.07 0.90 0.30], ...
    'String','REJECTED', ...
    'BackgroundColor',[1.00 0.90 0.90], ...
    'ForegroundColor',[0.60 0.00 0.00], ...
    'FontSize',8, ...
    'FontWeight','bold');

APP.txtStationHint = uicontrol('Parent',APP.pnlLeft,'Style','text', ...
    'Units','normalized','Position',[0.03 0.810 0.94 0.045], ...
    'String','Select a station to inspect details', ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'ForegroundColor',[0.25 0.30 0.35], ...
    'HorizontalAlignment','left', ...
    'FontSize',8.5);

APP.lstStations = uicontrol('Parent',APP.pnlLeft,'Style','listbox', ...
    'Units','normalized','Position',[0.03 0.035 0.94 0.765], ...
    'String',{'No analysis results yet'}, ...
    'BackgroundColor','white', ...
    'ForegroundColor',[0.10 0.10 0.10], ...
    'FontName','Consolas', ...
    'FontSize',9, ...
    'Value',1, ...
    'Callback',@(src,event)cbSelectStation());

% Kept only for backward compatibility with older callback names
APP.tblStations = [];

% -------------------- Center graph panel --------------------
APP.pnlPlot = uipanel('Parent',fig,'Title','H/V Spectral Ratio', ...
    'Units','normalized','Position',[0.270 0.095 0.425 0.740], ...
    'BackgroundColor',[0.96 0.97 0.98], ... 
    'FontWeight','bold');


APP.ax = axes('Parent',APP.pnlPlot, ...
    'Units','normalized','Position',[0.10 0.12 0.85 0.82]);
grid(APP.ax,'on');
title(APP.ax,'Select a station from the list after analysis.');
xlabel(APP.ax,'Frequency [Hz]');
ylabel(APP.ax,'Amplitude H/V');
set(APP.ax,'XScale','log');

% -------------------- Right criteria panel --------------------
APP.pnlRight = uipanel('Parent',fig,'Title','Criteria and Summary', ...
    'Units','normalized','Position',[0.705 0.095 0.275 0.740], ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'FontWeight','bold');

% Status card
APP.pnlStationSummary = uipanel('Parent',APP.pnlRight, ...
    'Title','Station Summary', ...
    'Units','normalized','Position',[0.04 0.803 0.92 0.167], ...
    'BackgroundColor','white', ...
    'FontWeight','bold');

APP.txtStationName = uicontrol('Parent',APP.pnlStationSummary,'Style','text', ...
    'Units','normalized','Position',[0.05 0.70 0.90 0.20], ...
    'String','No station selected', ...
    'BackgroundColor','white', ...
    'HorizontalAlignment','left', ...
    'FontSize',10, ...
    'FontWeight','bold');

APP.txtOverallStatus = uicontrol('Parent',APP.pnlStationSummary,'Style','text', ...
    'Units','normalized','Position',[0.05 0.43 0.90 0.22], ...
    'String','Status: -', ...
    'BackgroundColor',[0.93 0.93 0.93], ...
    'HorizontalAlignment','center', ...
    'FontSize',9, ...
    'FontWeight','bold');

APP.txtReliable = uicontrol('Parent',APP.pnlStationSummary,'Style','text', ...
    'Units','normalized','Position',[0.05 0.18 0.42 0.16], ...
    'String','Reliability: -', ...
    'BackgroundColor','white', ...
    'HorizontalAlignment','left', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

APP.txtClear = uicontrol('Parent',APP.pnlStationSummary,'Style','text', ...
    'Units','normalized','Position',[0.52 0.18 0.43 0.16], ...
    'String','Clear Peak: -', ...
    'BackgroundColor','white', ...
    'HorizontalAlignment','left', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

% Reliability and Clear Peak progress bars
APP.pnlProgress = uipanel('Parent',APP.pnlRight, ...
    'Title','Evaluation Scores', ...
    'Units','normalized','Position',[0.04 0.603 0.92 0.188], ...
    'BackgroundColor','white', ...
    'FontWeight','bold');

APP.txtReliabilityProgress = uicontrol('Parent',APP.pnlProgress,'Style','text', ...
    'Units','normalized','Position',[0.05 0.73 0.60 0.18], ...
    'String','Reliability (V1-V3)', ...
    'BackgroundColor','white', ...
    'HorizontalAlignment','left', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

APP.txtReliabilityScore = uicontrol('Parent',APP.pnlProgress,'Style','text', ...
    'Units','normalized','Position',[0.65 0.73 0.30 0.18], ...
    'String','0/3', ...
    'BackgroundColor','white', ...
    'HorizontalAlignment','right', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

APP.axReliabilityBar = axes('Parent',APP.pnlProgress, ...
    'Units','normalized','Position',[0.05 0.49 0.90 0.22]);
axis(APP.axReliabilityBar,'off');

APP.txtClearProgress = uicontrol('Parent',APP.pnlProgress,'Style','text', ...
    'Units','normalized','Position',[0.05 0.27 0.60 0.18], ...
    'String','Clear Peak (V4-V9)', ...
    'BackgroundColor','white', ...
    'HorizontalAlignment','left', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

APP.txtClearScore = uicontrol('Parent',APP.pnlProgress,'Style','text', ...
    'Units','normalized','Position',[0.65 0.27 0.30 0.18], ...
    'String','0/6', ...
    'BackgroundColor','white', ...
    'HorizontalAlignment','right', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

APP.axClearBar = axes('Parent',APP.pnlProgress, ...
    'Units','normalized','Position',[0.05 0.035 0.90 0.22]);
axis(APP.axClearBar,'off');

% Parameter cards
APP.pnlParamCards = uipanel('Parent',APP.pnlRight, ...
    'Title','Peak Parameters', ...
    'Units','normalized','Position',[0.04 0.477 0.92 0.114], ...
    'BackgroundColor','white', ...
    'FontWeight','bold');

% Peak parameter mini cards: centered label + centered value
APP.cardF0 = uipanel('Parent',APP.pnlParamCards, ...
    'Title','', ...
    'Units','normalized','Position',[0.04 0.14 0.28 0.72], ...
    'BackgroundColor',[0.94 0.97 1.00], ...
    'BorderType','line');

APP.lblF0 = uicontrol('Parent',APP.cardF0,'Style','text', ...
    'Units','normalized','Position',[0.05 0.56 0.90 0.34], ...
    'String','f₀', ...
    'BackgroundColor',[0.94 0.97 1.00], ...
    'ForegroundColor',[0.05 0.20 0.45], ...
    'HorizontalAlignment','center', ...
    'FontSize',9, ...
    'FontWeight','bold');

APP.valF0 = uicontrol('Parent',APP.cardF0,'Style','text', ...
    'Units','normalized','Position',[0.05 0.14 0.90 0.40], ...
    'String','-', ...
    'BackgroundColor',[0.94 0.97 1.00], ...
    'ForegroundColor',[0.05 0.20 0.45], ...
    'HorizontalAlignment','center', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

APP.cardT0 = uipanel('Parent',APP.pnlParamCards, ...
    'Title','', ...
    'Units','normalized','Position',[0.36 0.14 0.28 0.72], ...
    'BackgroundColor',[0.94 1.00 0.96], ...
    'BorderType','line');

APP.lblT0 = uicontrol('Parent',APP.cardT0,'Style','text', ...
    'Units','normalized','Position',[0.05 0.56 0.90 0.34], ...
    'String','T₀', ...
    'BackgroundColor',[0.94 1.00 0.96], ...
    'ForegroundColor',[0.05 0.35 0.18], ...
    'HorizontalAlignment','center', ...
    'FontSize',9, ...
    'FontWeight','bold');

APP.valT0 = uicontrol('Parent',APP.cardT0,'Style','text', ...
    'Units','normalized','Position',[0.05 0.14 0.90 0.40], ...
    'String','-', ...
    'BackgroundColor',[0.94 1.00 0.96], ...
    'ForegroundColor',[0.05 0.35 0.18], ...
    'HorizontalAlignment','center', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

APP.cardA0 = uipanel('Parent',APP.pnlParamCards, ...
    'Title','', ...
    'Units','normalized','Position',[0.68 0.14 0.28 0.72], ...
    'BackgroundColor',[0.97 0.94 1.00], ...
    'BorderType','line');

APP.lblA0 = uicontrol('Parent',APP.cardA0,'Style','text', ...
    'Units','normalized','Position',[0.05 0.56 0.90 0.34], ...
    'String','A₀', ...
    'BackgroundColor',[0.97 0.94 1.00], ...
    'ForegroundColor',[0.35 0.10 0.55], ...
    'HorizontalAlignment','center', ...
    'FontSize',9, ...
    'FontWeight','bold');

APP.valA0 = uicontrol('Parent',APP.cardA0,'Style','text', ...
    'Units','normalized','Position',[0.05 0.14 0.90 0.40], ...
    'String','-', ...
    'BackgroundColor',[0.97 0.94 1.00], ...
    'ForegroundColor',[0.35 0.10 0.55], ...
    'HorizontalAlignment','center', ...
    'FontSize',8.5, ...
    'FontWeight','bold');

% Criteria list without grid lines
APP.pnlCriteriaList = uipanel('Parent',APP.pnlRight, ...
    'Title','SESAME Criteria', ...
    'Units','normalized','Position',[0.04 0.030 0.92 0.435], ...
    'BackgroundColor','white', ...
    'FontWeight','bold');

APP.critNameText = zeros(9,1);
APP.critDescText = zeros(9,1);
APP.critStatusText = zeros(9,1);

for kk = 1:9
    yPos = 0.90 - (kk-1)*0.098;

    APP.critNameText(kk) = uicontrol('Parent',APP.pnlCriteriaList,'Style','text', ...
        'Units','normalized','Position',[0.04 yPos 0.13 0.070], ...
        'String',sprintf('V%d',kk), ...
        'BackgroundColor',[0.92 0.94 0.96], ...
        'HorizontalAlignment','center', ...
        'FontWeight','bold', ...
        'FontSize',8);

    APP.critDescText(kk) = uicontrol('Parent',APP.pnlCriteriaList,'Style','text', ...
        'Units','normalized','Position',[0.20 yPos 0.50 0.070], ...
        'String','-', ...
        'BackgroundColor','white', ...
        'HorizontalAlignment','left', ...
        'FontSize',8);

    APP.critStatusText(kk) = uicontrol('Parent',APP.pnlCriteriaList,'Style','text', ...
        'Units','normalized','Position',[0.73 yPos 0.23 0.070], ...
        'String','-', ...
        'BackgroundColor',[0.93 0.93 0.93], ...
        'HorizontalAlignment','center', ...
        'FontWeight','bold', ...
        'FontSize',8);
end

applyLightThemeToFigure(fig);

% Publication screenshot preset: GUI fonts only (no SESAME calculations).
applyPublicationGUIFonts(fig,APP);

guidata(fig,APP);


updateWorkflowState(fig);

% -------------------- Callbacks --------------------
    function updateWorkflowState(figHandle)
        APP = guidata(figHandle);

        hasFolder = ~isempty(APP.rootDir) && isfolder(APP.rootDir);
        hasCoords = ~isempty(APP.coordFile) && ~isempty(APP.coordTable);
        hasResults = ~isempty(APP.results);

        % Reset all step colors
        set(APP.step1,'BackgroundColor',[0.93 0.96 1.00]);
        set(APP.step2,'BackgroundColor',[0.94 0.94 0.94]);
        set(APP.step3,'BackgroundColor',[0.94 0.94 0.94]);
        set(APP.step4,'BackgroundColor',[0.94 0.94 0.94]);
        set(APP.step5,'BackgroundColor',[0.94 0.94 0.94]);
        set(APP.step6,'BackgroundColor',[0.94 0.94 0.94]);

        set(APP.btnCoords,'Enable','off');
        set(APP.edtZone,'Enable','off');
        set(APP.btnRun,'Enable','off');
        set(APP.btnPDF,'Enable','off');
        set(APP.btnKMZ,'Enable','off');
        set(APP.btnGIS,'Enable','off');
        set(APP.btnLoadProject,'Enable','on');
        set(APP.btnSaveProject,'Enable','off');

        if hasFolder
            set(APP.step1,'BackgroundColor',[0.80 0.94 0.80]); % completed
            set(APP.step2,'BackgroundColor',[0.93 0.96 1.00]); % current
            set(APP.btnCoords,'Enable','on');
        end

        if hasFolder && hasCoords
            set(APP.step2,'BackgroundColor',[0.80 0.94 0.80]);
            set(APP.step3,'BackgroundColor',[0.93 0.96 1.00]);
            set(APP.edtZone,'Enable','on');
            set(APP.step4,'BackgroundColor',[0.93 0.96 1.00]);
            set(APP.btnRun,'Enable','on');
        end

        if hasResults
            set(APP.step3,'BackgroundColor',[0.80 0.94 0.80]);
            set(APP.step4,'BackgroundColor',[0.80 0.94 0.80]);
            set(APP.step5,'BackgroundColor',[0.93 0.96 1.00]);
            set(APP.step6,'BackgroundColor',[0.93 0.96 1.00]);
            set(APP.btnPDF,'Enable','on');
            set(APP.btnKMZ,'Enable','on');
            set(APP.btnGIS,'Enable','on');
            set(APP.btnSaveProject,'Enable','on');
        end

        guidata(figHandle,APP);
    end

    function cbOpenFolder()
        APP = guidata(fig);
        d = uigetdir(pwd,'Select folder containing .hv and .log files');
        if isequal(d,0); return; end
        APP.rootDir = d;
        set(APP.txtStatus,'String',['Step 1 completed: folder selected. Step 2: Now select the coordinate file with seperated by tab (X, Y, Z, Station Name).']);
        guidata(fig,APP);
        updateWorkflowState(fig);
    end

    function cbOpenCoords()
        APP = guidata(fig);
        [f,p] = uigetfile({'*.txt;*.dat','Text Files (*.txt, *.dat)'}, ...
            'Select coordinate file (X Y Z Name)');
        if isequal(f,0); return; end
        APP.coordFile = fullfile(p,f);
        try
            APP.coordTable = readCoordinates(APP.coordFile);
            set(APP.txtStatus,'String','Step 2 completed: coordinate file loaded. Step 3: Check UTM zone and run analysis.');
        catch ME
            errordlg(ME.message,'Coordinate Reading Error');
        end
        guidata(fig,APP);
        updateWorkflowState(fig);
    end

    function cbRun()
        APP = guidata(fig);
        APP.utmZone = strtrim(get(APP.edtZone,'String'));

        if isempty(APP.rootDir) || ~isfolder(APP.rootDir)
            errordlg('Select the .hv/.log folder first.','Missing Information');
            return;
        end

        if isempty(APP.coordFile) || isempty(APP.coordTable)
            errordlg('Select the coordinate file first.','Missing Information');
            return;
        end

        set(APP.txtStatus,'String','Analysis is running...');
        drawnow;

        try
            [APP.results, APP.finalTable, APP.latlonTable] = runBatchAnalysis(APP.rootDir, APP.coordTable, APP.utmZone);
            updateStationTable(APP);
            set(APP.txtStatus,'String',sprintf('Analysis completed. Total stations: %d.',numel(APP.results)));
            guidata(fig,APP);
            updateWorkflowState(fig);
        catch ME
            errordlg(ME.message,'Analysis Error');
            set(APP.txtStatus,'String','Analysis error.');
        end
    end

    function cbSelectStation()
        APP = guidata(fig);
        if isempty(APP.results)
            return;
        end

        row = get(APP.lstStations,'Value');

        if isempty(row) || row < 1 || row > numel(APP.results)
            return;
        end

        showStation(APP,row);
    end

    function cbExportPDF()
        APP = guidata(fig);
        if isempty(APP.results) || isempty(APP.finalTable)
            errordlg('Run the analysis first.','Missing Data');
            return;
        end

        [f,p] = uiputfile('*.pdf','Save PDF report');
        if isequal(f,0); return; end
        outPdf = fullfile(p,f);

        set(APP.txtStatus,'String','Generating PDF report...');
        drawnow;

        try
            createPDFReportCompat(APP.finalTable, APP.results, outPdf);
            set(APP.txtStatus,'String',['PDF report completed: ' outPdf]);
        catch ME
            errordlg(ME.message,'PDF Error');
            set(APP.txtStatus,'String','PDF report could not be generated.');
        end
    end

    function cbExportKMZ()
        APP = guidata(fig);
        if isempty(APP.latlonTable)
            errordlg('Run the analysis first.','Missing Data');
            return;
        end

        [f,p] = uiputfile('*.kmz','Save KMZ file');
        if isequal(f,0); return; end
        outKmz = fullfile(p,f);

        try
            createKMZ(APP.latlonTable,outKmz);
            set(APP.txtStatus,'String',['KMZ saved: ' outKmz]);
        catch ME
            errordlg(ME.message,'KMZ Error');
        end
    end

    function cbExportGIS()
        APP = guidata(fig);
        if isempty(APP.finalTable)
            errordlg('Run the analysis first.','Missing Data');
            return;
        end

        includeChoice = questdlg( ...
            sprintf(['Select stations to include in the GIS layer:\n\n' ...
            'Recommended: Accepted + Controlled Acceptance\n' ...
            'Use All Stations only if you want rejected stations in the GIS attribute table.']), ...
            'Export GIS Layers', ...
            'Accepted + Controlled', 'All Stations', 'Cancel', ...
            'Accepted + Controlled');

        if isempty(includeChoice) || strcmp(includeChoice,'Cancel')
            return;
        end

        [f,p] = uiputfile({'*.shp','ESRI Shapefile (*.shp)'}, ...
            'Save GIS shapefile as', 'HVSR_Stations.shp');

        if isequal(f,0)
            return;
        end

        shpFile = fullfile(p,f);

        try
            createGISExport(APP.finalTable, APP.utmZone, shpFile, includeChoice);
            set(APP.txtStatus,'String',['GIS layers exported: ' shpFile]);
        catch ME
            errordlg(ME.message,'GIS Export Error');
            set(APP.txtStatus,'String','GIS export could not be completed.');
        end
    end

    function cbSaveProject()
        APP = guidata(fig);

        if isempty(APP.results) || isempty(APP.finalTable)
            errordlg('Run or load an analysis before saving a project.','Missing Data');
            return;
        end

        [f,p] = uiputfile({'*.hsap','HSAP Project (*.hsap)'; '*.mat','MAT-file (*.mat)'}, ...
            'Save HSAP project');

        if isequal(f,0)
            return;
        end

        projectFile = fullfile(p,f);

        project = struct();
        project.version = 'HV-SESAME Analyzer V1';
        project.savedOn = datestr(now,'yyyy-mm-dd HH:MM:SS');
        project.rootDir = APP.rootDir;
        project.coordFile = APP.coordFile;
        project.utmZone = APP.utmZone;
        project.coordTable = APP.coordTable;
        project.results = APP.results;
        project.finalTable = APP.finalTable;
        project.latlonTable = APP.latlonTable;

        try
            save(projectFile,'project','-mat');
            set(APP.txtStatus,'String',['Project saved: ' projectFile]);
        catch ME
            errordlg(ME.message,'Save Project Error');
            set(APP.txtStatus,'String','Project could not be saved.');
        end
    end

    function cbLoadProject()
        APP = guidata(fig);

        [f,p] = uigetfile({'*.hsap;*.mat','HSAP Project (*.hsap, *.mat)'}, ...
            'Load HSAP project');

        if isequal(f,0)
            return;
        end

        projectFile = fullfile(p,f);

        try
            S = load(projectFile,'-mat');

            if ~isfield(S,'project')
                error('Selected file does not contain a valid HSAP project structure.');
            end

            project = S.project;

            requiredFields = {'rootDir','coordFile','utmZone','coordTable','results','finalTable','latlonTable'};
            for q = 1:numel(requiredFields)
                if ~isfield(project,requiredFields{q})
                    error('Project file is missing required field: %s',requiredFields{q});
                end
            end

            APP.rootDir = project.rootDir;
            APP.coordFile = project.coordFile;
            APP.utmZone = project.utmZone;
            APP.coordTable = project.coordTable;
            APP.results = project.results;
            APP.finalTable = project.finalTable;
            APP.latlonTable = project.latlonTable;

            set(APP.edtZone,'String',APP.utmZone);

            guidata(fig,APP);
            updateStationTable(APP);
            updateWorkflowState(fig);

            APP = guidata(fig);
            if ~isempty(APP.results)
                showStation(APP,1);
            end

            set(APP.txtStatus,'String',['Project loaded: ' projectFile]);

        catch ME
            errordlg(ME.message,'Load Project Error');
            set(APP.txtStatus,'String','Project could not be loaded.');
        end
    end

    function cbAbout()
        msg = sprintf(['HV-SESAME Analyzer V1\n\n' ...
            'H/V Spectral Ratio SESAME Reliability and Clarity Tool\n' ...
            'Outputs: PDF Report + KMZ Mapping + GIS Layers + Project Save/Load\n\n' ...
            'Status classes:\n' ...
            'Green  : Accepted\n' ...
            'Yellow : Controlled Acceptance\n' ...
            'Red    : Rejected\n' ...
            'Desinged by Dr. Özkan Cevdet Özdağ\n' ...
            'cevdet.ozdag@deu.edu.tr\n']);
        msgbox(msg,'About');
    end

end

%% ========================================================================
function [allResults, finalTable, latlonTable] = runBatchAnalysis(rootDir, coordTable, utmZone)

hvList = dir(fullfile(rootDir,'*.hv'));
if isempty(hvList)
    error('No .hv file was found in the selected folder.');
end

% Natural sorting: m1, m2, ..., m10, m11
[~, hvOrd] = sortStationNames({hvList.name});
hvList = hvList(hvOrd);

allResults = [];

for k = 1:numel(hvList)
    [~,baseName,~] = fileparts(hvList(k).name);

    hvFile = fullfile(rootDir,hvList(k).name);
    logFile = fullfile(rootDir,[baseName '.log']);

    if ~isfile(logFile)
        warning('%s: .log file not found, skipped.',baseName);
        continue;
    end

    try
        res = runSesameCheck(hvFile,logFile);
        res.stationName = baseName;
        allResults = [allResults; res]; %#ok<AGROW>
    catch ME
        warning('%s analysis error: %s',baseName,ME.message);
    end
end

if isempty(allResults)
    error('No analyzable file was found.');
end

% Natural sorting of results
[~, resOrd] = sortStationNames({allResults.stationName});
allResults = allResults(resOrd);

[finalTable, latlonTable] = buildResultTables(allResults, coordTable, utmZone);

end

%% ========================================================================
function [sortedNames, order] = sortStationNames(names)
% Natural station-name sorting, e.g. m1, m2, ..., m10.

names = cellstr(names(:));
n = numel(names);

prefix = strings(n,1);
numVal = nan(n,1);

for i = 1:n
    [~, base, ~] = fileparts(names{i});
    tok = regexp(base,'^(.*?)(\d+)$','tokens','once');

    if isempty(tok)
        prefix(i) = lower(string(base));
        numVal(i) = inf;
    else
        prefix(i) = lower(string(tok{1}));
        numVal(i) = str2double(tok{2});
    end
end

T = table(prefix,numVal,string(names(:)),(1:n)', ...
    'VariableNames',{'Prefix','Number','Name','OriginalIndex'});

T = sortrows(T,{'Prefix','Number','Name'});
order = T.OriginalIndex;
sortedNames = names(order);

end

function updateStationTable(APP)

n = numel(APP.results);

if n == 0
    set(APP.lstStations,'String',{'No analysis results yet'},'Value',1);
    return;
end

nAccepted = 0;
nControlled = 0;
nRejected = 0;

items = cell(n,1);

for i = 1:n
    res = APP.results(i);

    if res.criteria.allPass
        nAccepted = nAccepted + 1;
        statusShort = 'ACCEPTED';
        marker = '[A]';
    elseif res.criteria.controlled
        nControlled = nControlled + 1;
        statusShort = 'CONTROLLED';
        marker = '[C]';
    else
        nRejected = nRejected + 1;
        statusShort = 'REJECTED';
        marker = '[R]';
    end

    items{i} = sprintf('%-4s %-10s  f0=%7.4f Hz   T0=%6.3f s   A0=%6.3f   %s', ...
        marker, res.stationName, res.f0, res.T0, res.A0, statusShort);
end

set(APP.txtAcceptedCount,'String',sprintf('%d',nAccepted));
set(APP.txtControlledCount,'String',sprintf('%d',nControlled));
set(APP.txtRejectedCount,'String',sprintf('%d',nRejected));

set(APP.lstStations,'String',items,'Value',1);

% Show first station automatically after analysis
showStation(APP,1);

end

%% ========================================================================
function showStation(APP,row)

res = APP.results(row);

axes(APP.ax); %#ok<LAXES>
cla(APP.ax);
plotHVwithCriteria(res,APP.ax);
title(APP.ax,strrep(res.stationName,'_','\_'));

crit = res.criteria;

critNames = {'V1','V2','V3','V4','V5','V6','V7','V8','V9'};
critDesc  = { ...
    'f0 > 10/Iw', ...
    'nc(f0) > 200', ...
    'amplitude stability', ...
    'clear low', ...
    'clear high', ...
    'A0 > 2', ...
    'peak within f0 +/- 5%', ...
    'sigma_f < epsilon(f0)', ...
    'sigma_A(f0) < theta(f0)'};

critFlags = [crit.V1 crit.V2 crit.V3 crit.V4 crit.V5 crit.V6 crit.V7 crit.V8 crit.V9];

% Update station summary card
set(APP.txtStationName,'String',res.stationName);

if crit.allPass
    statusColor = [0.78 0.92 0.78];
    statusText = 'Status: ACCEPTED';
elseif crit.controlled
    statusColor = [1.00 0.91 0.55];
    statusText = 'Status: CONTROLLED ACCEPTANCE';
else
    statusColor = [0.95 0.72 0.72];
    statusText = 'Status: REJECTED';
end

set(APP.txtOverallStatus,'String',statusText,'BackgroundColor',statusColor);
set(APP.txtReliable,'String',['Reliability: ' yesno(crit.reliable)]);
set(APP.txtClear,'String',['Clear Peak: ' yesno(crit.clear)]);
set(APP.valF0,'String',sprintf('%.4f Hz',res.f0));
set(APP.valT0,'String',sprintf('%.3f s',res.T0));
set(APP.valA0,'String',sprintf('%.3f',res.A0));

% Progress bars
reliabilityScore = sum([crit.V1 crit.V2 crit.V3]);
clearScore = sum([crit.V4 crit.V5 crit.V6 crit.V7 crit.V8 crit.V9]);

set(APP.txtReliabilityScore,'String',sprintf('%d / 3 (%.0f%%)',reliabilityScore,100*reliabilityScore/3));
set(APP.txtClearScore,'String',sprintf('%d / 6 (%.0f%%)',clearScore,100*clearScore/6));

drawProgressBar(APP.axReliabilityBar, reliabilityScore/3, [0.20 0.70 0.30]);
drawProgressBar(APP.axClearBar, clearScore/6, [0.95 0.70 0.05]);

% Update criteria cards
for k = 1:9
    set(APP.critNameText(k),'String',critNames{k});
    set(APP.critDescText(k),'String',critDesc{k});

    if critFlags(k)
        set(APP.critStatusText(k), ...
            'String','TRUE', ...
            'BackgroundColor',[0.78 0.92 0.78], ...
            'ForegroundColor',[0.00 0.35 0.00]);
    else
        set(APP.critStatusText(k), ...
            'String','FALSE', ...
            'BackgroundColor',[0.95 0.72 0.72], ...
            'ForegroundColor',[0.55 0.00 0.00]);
    end
end

end

%% ========================================================================
function drawProgressBar(ax, frac, barColor)
% Draw a clean progress bar in a small axes.

frac = max(0,min(1,frac));

cla(ax);
axis(ax,'off');
xlim(ax,[0 1]);
ylim(ax,[0 1]);

rectangle(ax,'Position',[0 0.08 1 0.84], ...
    'FaceColor',[0.88 0.90 0.92], ...
    'EdgeColor',[0.75 0.78 0.82]);

rectangle(ax,'Position',[0 0.08 frac 0.84], ...
    'FaceColor',barColor, ...
    'EdgeColor','none');

text(ax,0.50,0.50,sprintf('%.0f%%',frac*100), ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle', ...
    'FontWeight','bold', ...
    'FontSize',14, ...
    'BackgroundColor',[1 1 1], ...
    'Margin',1, ...
    'Color',[0.05 0.05 0.05]);

end

%% ========================================================================
function result = runSesameCheck(noise, logFile)
% Modular SESAME assessment from documented, labelled Geopsy fields.
% The parser and evaluator are included as local functions below.
spectrum = hvsa_parse_hv(noise);
windows = hvsa_parse_log(logFile);
result = hvsa_evaluate_sesame(spectrum,windows);
end

%% ========================================================================
function plotHVwithCriteria(res,ax)
% Delegate plotting to the local H/V visualization function.
if nargin < 2
    ax = gca;
end
hvsa_plot_spectrum(ax,res);
end

%% ========================================================================
function [finalTable, latlonTable] = buildResultTables(allResults, coordTable, utmZone)

n = numel(allResults);

Name  = strings(n,1);
X     = nan(n,1);
Y     = nan(n,1);
Z     = nan(n,1);
Lat   = nan(n,1);
Lon   = nan(n,1);
f0    = nan(n,1);
T0    = nan(n,1);
A0    = nan(n,1);

Reliable   = false(n,1);
Clear      = false(n,1);
Controlled = false(n,1);
AllPass    = false(n,1);

ReliabilityScore = nan(n,1);
ClearScore       = nan(n,1);
QualityScore     = nan(n,1);

V1 = false(n,1); V2 = false(n,1); V3 = false(n,1);
V4 = false(n,1); V5 = false(n,1); V6 = false(n,1);
V7 = false(n,1); V8 = false(n,1); V9 = false(n,1);

for i = 1:n
    stName = string(allResults(i).stationName);

    Name(i) = stName;
    f0(i) = allResults(i).f0;
    T0(i) = allResults(i).T0;
    A0(i) = allResults(i).A0;

    Reliable(i) = allResults(i).criteria.reliable;
    Clear(i) = allResults(i).criteria.clear;
    Controlled(i) = allResults(i).criteria.controlled;
    AllPass(i) = allResults(i).criteria.allPass;

    V1(i) = allResults(i).criteria.V1;
    V2(i) = allResults(i).criteria.V2;
    V3(i) = allResults(i).criteria.V3;
    V4(i) = allResults(i).criteria.V4;
    V5(i) = allResults(i).criteria.V5;
    V6(i) = allResults(i).criteria.V6;
    V7(i) = allResults(i).criteria.V7;
    V8(i) = allResults(i).criteria.V8;
    V9(i) = allResults(i).criteria.V9;

    ReliabilityScore(i) = sum([V1(i) V2(i) V3(i)]) / 3;
    ClearScore(i)       = sum([V4(i) V5(i) V6(i) V7(i) V8(i) V9(i)]) / 6;
    QualityScore(i)     = 0.40*ReliabilityScore(i) + 0.60*ClearScore(i);

    idx = find(coordTable.Name == stName,1);
    if ~isempty(idx)
        X(i) = coordTable.X(idx);
        Y(i) = coordTable.Y(idx);
        Z(i) = coordTable.Z(idx);
        [lat,lon] = utm2deg_simple(X(i),Y(i),utmZone);
        Lat(i) = lat;
        Lon(i) = lon;
    else
        warning('Coordinate not found: %s',stName);
    end
end

finalTable = table(Name,X,Y,Z,Lat,Lon,f0,T0,A0, ...
    ReliabilityScore,ClearScore,QualityScore, ...
    Reliable,Clear,Controlled,AllPass, ...
    V1,V2,V3,V4,V5,V6,V7,V8,V9);

latlonTable = table(Name,Lat,Lon,Z,f0,T0,A0, ...
    ReliabilityScore,ClearScore,QualityScore, ...
    Reliable,Clear,Controlled,AllPass, ...
    V1,V2,V3,V4,V5,V6,V7,V8,V9);

end

%% ========================================================================
function coordTable = readCoordinates(coordFile)

opts = detectImportOptions(coordFile,'FileType','text');
opts.Delimiter = {'\t',' '};
opts.CommentStyle = '#';

if numel(opts.VariableNames) < 4
    error('Coordinate file must contain at least 4 columns: X Y Z Name');
end

opts.VariableNames{1} = 'X';
opts.VariableNames{2} = 'Y';
opts.VariableNames{3} = 'Z';
opts.VariableNames{4} = 'Name';

opts = setvartype(opts,{'X','Y','Z'},'double');

coordTable = readtable(coordFile,opts);
coordTable.Name = string(coordTable.Name);

end

%% ========================================================================
function createGISExport(finalTable, utmZone, shpFile, includeChoice)
% Export GIS-compatible layers.
% User can select:
%   1) Accepted + Controlled Acceptance, recommended for mapping/interpolation
%   2) All Stations, including rejected stations

if isempty(finalTable)
    error('No analysis results available for GIS export.');
end

[outDir,baseFile,ext] = fileparts(shpFile);
if isempty(outDir)
    outDir = pwd;
end
if isempty(baseFile)
    baseFile = 'HVSR_Stations';
end
if isempty(ext)
    shpFile = fullfile(outDir,[baseFile '.shp']); %#ok<NASGU>
end

baseName = fullfile(outDir,baseFile);

switch includeChoice
    case 'Accepted + Controlled'
        idx = finalTable.AllPass | finalTable.Controlled;
        exportMode = 'Accepted + Controlled Acceptance';
    case 'All Stations'
        idx = true(height(finalTable),1);
        exportMode = 'All Stations';
    otherwise
        error('Invalid GIS export option.');
end

if ~any(idx)
    error('No stations were found for the selected GIS export option.');
end

T = finalTable(idx,:);

Status = strings(height(T),1);
for i = 1:height(T)
    if T.AllPass(i)
        Status(i) = "Accepted";
    elseif T.Controlled(i)
        Status(i) = "Controlled";
    else
        Status(i) = "Rejected";
    end
end

RelPct = T.ReliabilityScore * 100;
ClrPct = T.ClearScore * 100;

RelClass = strings(height(T),1);
ClrClass = strings(height(T),1);

for i = 1:height(T)
    RelClass(i) = scoreClass(RelPct(i));
    ClrClass(i) = scoreClass(ClrPct(i));
end

% Keep criterion-level provenance in both CSV and shapefile attributes.
% Numeric 1 means PASS, numeric 0 means FAIL. All nine fields are exported.
criterionNames = arrayfun(@(k)sprintf('V%d',k),1:9,'UniformOutput',false);
criterionFlags = zeros(height(T),9);
for k = 1:9
    criterionFlags(:,k) = double(T.(criterionNames{k}));
end

gisTable = table(T.Name, Status, T.f0, T.T0, T.A0, RelPct, ClrPct, RelClass, ClrClass, T.X, T.Y, T.Z, ...
    'VariableNames',{'Name','Status','f0_Hz','T0_s','A0','RelPct','ClrPct','RelClass','ClrClass','X_UTM','Y_UTM','Z'});
criterionTable = array2table(criterionFlags,'VariableNames',criterionNames);
gisTable = [gisTable criterionTable];

writetable(gisTable,[baseName '.csv']);

% Remove old shapefile components with the same base name if present
oldExt = {'.shp','.shx','.dbf','.prj','.cpg'};
for e = 1:numel(oldExt)
    oldFile = [baseName oldExt{e}];
    if exist(oldFile,'file')
        delete(oldFile);
    end
end

% Try Mapping Toolbox shapewrite first; fallback to internal writer if unavailable.
try
    S = struct([]);
    for i = 1:height(T)
        S(i).Geometry = 'Point'; %#ok<AGROW>
        S(i).X = T.X(i);
        S(i).Y = T.Y(i);
        S(i).Name = char(T.Name(i));
        S(i).Status = char(Status(i));
        S(i).f0_Hz = T.f0(i);
        S(i).T0_s = T.T0(i);
        S(i).A0 = T.A0(i);
        S(i).RelPct = RelPct(i);
        S(i).ClrPct = ClrPct(i);
        S(i).RelClass = char(RelClass(i));
        S(i).ClrClass = char(ClrClass(i));
        S(i).X_UTM = T.X(i);
        S(i).Y_UTM = T.Y(i);
        S(i).Z = T.Z(i);
        for k = 1:9
            S(i).(criterionNames{k}) = criterionFlags(i,k);
        end
    end
    shapewrite(S,[baseName '.shp']);
catch
    writePointShapefile(baseName,gisTable);
end

writePrjFile([baseName '.prj'],utmZone);
writeGISReadme([baseName '_README.txt'],utmZone,height(T),height(finalTable),exportMode);

end

%% ========================================================================
function c = scoreClass(pct)

if pct >= 99.9
    c = "High";
elseif pct >= 80
    c = "Moderate";
elseif pct >= 50
    c = "Low";
else
    c = "VeryLow";
end

end

%% ========================================================================
function writePointShapefile(baseName,T)
% Minimal toolbox-free ESRI point shapefile writer.
% Coordinate system: same as input X_UTM/Y_UTM.

n = height(T);

shpFile = [baseName '.shp'];
shxFile = [baseName '.shx'];
dbfFile = [baseName '.dbf'];

xmin = min(T.X_UTM); xmax = max(T.X_UTM);
ymin = min(T.Y_UTM); ymax = max(T.Y_UTM);

shpFileLengthWords = (100 + n*(8+20)) / 2;
shxFileLengthWords = (100 + n*8) / 2;

fid = fopen(shpFile,'w','b');
if fid < 0; error('Could not create SHP file.'); end
writeShpHeader(fid,shpFileLengthWords,1,xmin,ymin,xmax,ymax);
for i = 1:n
    fwrite(fid,i,'int32','b');
    fwrite(fid,10,'int32','b');
    fwrite(fid,1,'int32','l');
    fwrite(fid,T.X_UTM(i),'double','l');
    fwrite(fid,T.Y_UTM(i),'double','l');
end
fclose(fid);

fid = fopen(shxFile,'w','b');
if fid < 0; error('Could not create SHX file.'); end
writeShpHeader(fid,shxFileLengthWords,1,xmin,ymin,xmax,ymax);
offsetWords = 50;
for i = 1:n
    fwrite(fid,offsetWords,'int32','b');
    fwrite(fid,10,'int32','b');
    offsetWords = offsetWords + 14;
end
fclose(fid);

writeDbf(dbfFile,T);

end

%% ========================================================================
function writeShpHeader(fid,fileLengthWords,shapeType,xmin,ymin,xmax,ymax)

fwrite(fid,9994,'int32','b');
fwrite(fid,zeros(1,5),'int32','b');
fwrite(fid,fileLengthWords,'int32','b');

fwrite(fid,1000,'int32','l');
fwrite(fid,shapeType,'int32','l');
fwrite(fid,xmin,'double','l');
fwrite(fid,ymin,'double','l');
fwrite(fid,xmax,'double','l');
fwrite(fid,ymax,'double','l');
fwrite(fid,0,'double','l');
fwrite(fid,0,'double','l');
fwrite(fid,0,'double','l');
fwrite(fid,0,'double','l');

end

%% ========================================================================
function writeDbf(dbfFile,T)
% Minimal dBASE III writer compatible with shapefile attributes.

fields = { ...
    'Name','C',20,0; ...
    'Status','C',12,0; ...
    'f0_Hz','N',12,5; ...
    'T0_s','N',12,5; ...
    'A0','N',12,5; ...
    'RelPct','N',8,2; ...
    'ClrPct','N',8,2; ...
    'RelClass','C',10,0; ...
    'ClrClass','C',10,0; ...
    'X_UTM','N',14,3; ...
    'Y_UTM','N',14,3; ...
    'Z','N',10,3; ...
    'V1','N',1,0; ...
    'V2','N',1,0; ...
    'V3','N',1,0; ...
    'V4','N',1,0; ...
    'V5','N',1,0; ...
    'V6','N',1,0; ...
    'V7','N',1,0; ...
    'V8','N',1,0; ...
    'V9','N',1,0};

nRec = height(T);
nFields = size(fields,1);
headerLength = 32 + nFields*32 + 1;
recordLength = 1 + sum(cell2mat(fields(:,3)));

fid = fopen(dbfFile,'w');
if fid < 0; error('Could not create DBF file.'); end

clk = clock;
fwrite(fid,3,'uint8');
fwrite(fid,clk(1)-1900,'uint8');
fwrite(fid,clk(2),'uint8');
fwrite(fid,clk(3),'uint8');
fwrite(fid,nRec,'uint32','l');
fwrite(fid,headerLength,'uint16','l');
fwrite(fid,recordLength,'uint16','l');
fwrite(fid,zeros(1,20),'uint8');

for i = 1:nFields
    name = char(fields{i,1});
    typ = char(fields{i,2});
    len = fields{i,3};
    dec = fields{i,4};

    nameBytes = uint8(zeros(1,11));
    nb = uint8(name);
    nameBytes(1:min(numel(nb),11)) = nb(1:min(numel(nb),11));

    fwrite(fid,nameBytes,'uint8');
    fwrite(fid,uint8(typ),'uint8');
    fwrite(fid,zeros(1,4),'uint8');
    fwrite(fid,len,'uint8');
    fwrite(fid,dec,'uint8');
    fwrite(fid,zeros(1,14),'uint8');
end

fwrite(fid,13,'uint8');

for r = 1:nRec
    fwrite(fid,uint8(' '),'uint8');

    values = { ...
        char(T.Name(r)), ...
        char(T.Status(r)), ...
        T.f0_Hz(r), ...
        T.T0_s(r), ...
        T.A0(r), ...
        T.RelPct(r), ...
        T.ClrPct(r), ...
        char(T.RelClass(r)), ...
        char(T.ClrClass(r)), ...
        T.X_UTM(r), ...
        T.Y_UTM(r), ...
        T.Z(r), ...
        T.V1(r), T.V2(r), T.V3(r), T.V4(r), T.V5(r), ...
        T.V6(r), T.V7(r), T.V8(r), T.V9(r)};

    for f = 1:nFields
        typ = char(fields{f,2});
        len = fields{f,3};
        dec = fields{f,4};
        val = values{f};

        if typ == 'C'
            s = char(val);
            s = s(1:min(numel(s),len));
            s = sprintf(['%-' num2str(len) 's'],s);
        else
            fmt = ['%' num2str(len) '.' num2str(dec) 'f'];
            s = sprintf(fmt,val);
            if numel(s) > len
                s = repmat('*',1,len);
            end
        end

        fwrite(fid,uint8(s),'uint8');
    end
end

fwrite(fid,26,'uint8');
fclose(fid);

end

%% ========================================================================
function writePrjFile(prjFile,utmZone)

zoneNumber = str2double(utmZone(1:end-1));
if isnan(zoneNumber)
    error('Invalid UTM zone format for PRJ export: %s',utmZone);
end

hemisphereChar = upper(utmZone(end));

if hemisphereChar >= 'N'
    hemiName = 'N';
    epsg = 32600 + zoneNumber;
    falseNorthing = 0;
else
    hemiName = 'S';
    epsg = 32700 + zoneNumber;
    falseNorthing = 10000000;
end

centralMeridian = (zoneNumber - 1)*6 - 180 + 3;

wkt = sprintf(['PROJCS["WGS_1984_UTM_Zone_%d%s",' ...
    'GEOGCS["GCS_WGS_1984",' ...
    'DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],' ...
    'PRIMEM["Greenwich",0],UNIT["Degree",0.0174532925199433]],' ...
    'PROJECTION["Transverse_Mercator"],' ...
    'PARAMETER["False_Easting",500000],' ...
    'PARAMETER["False_Northing",%d],' ...
    'PARAMETER["Central_Meridian",%g],' ...
    'PARAMETER["Scale_Factor",0.9996],' ...
    'PARAMETER["Latitude_Of_Origin",0],' ...
    'UNIT["Meter",1],' ...
    'AUTHORITY["EPSG","%d"]]'], ...
    zoneNumber,hemiName,falseNorthing,centralMeridian,epsg);

fid = fopen(prjFile,'w');
if fid < 0; error('Could not create PRJ file.'); end
fprintf(fid,'%s',wkt);
fclose(fid);

end

%% ========================================================================
function writeGISReadme(readmeFile,utmZone,nIncluded,nTotal,exportMode)

fid = fopen(readmeFile,'w');
if fid < 0
    return;
end

fprintf(fid,'HV-SESAME Analyzer GIS Export\n');
fprintf(fid,'================================\n\n');
fprintf(fid,'Export date: %s\n',datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf(fid,'Coordinate system: WGS84 / UTM Zone %s\n',utmZone);
fprintf(fid,'Export mode: %s\n\n',exportMode);
fprintf(fid,'Included stations: %d\n',nIncluded);
fprintf(fid,'Original station count: %d\n\n',nTotal);

fprintf(fid,'Included status classes:\n');
if strcmp(exportMode,'All Stations')
    fprintf(fid,'  - Accepted\n');
    fprintf(fid,'  - Controlled Acceptance\n');
    fprintf(fid,'  - Rejected\n\n');
    fprintf(fid,'Note:\n');
    fprintf(fid,'This export includes rejected stations. Use the Status field to filter them\n');
    fprintf(fid,'before interpolation or thematic mapping if required.\n\n');
else
    fprintf(fid,'  - Accepted\n');
    fprintf(fid,'  - Controlled Acceptance\n\n');
    fprintf(fid,'Excluded status classes:\n');
    fprintf(fid,'  - Rejected\n\n');
    fprintf(fid,'Note:\n');
    fprintf(fid,'Rejected stations are intentionally excluded from this GIS layer to prevent\n');
    fprintf(fid,'low-quality H/V results from being used directly in interpolation or mapping.\n\n');
end

fprintf(fid,'Attributes:\n');
fprintf(fid,'  Name      : Station name\n');
fprintf(fid,'  Status    : Accepted, Controlled or Rejected\n');
fprintf(fid,'  f0_Hz     : H/V peak frequency in Hz\n');
fprintf(fid,'  T0_s      : H/V peak period in seconds\n');
fprintf(fid,'  A0        : H/V peak amplitude\n');
fprintf(fid,'  RelPct    : Reliability score in percent\n');
fprintf(fid,'  ClrPct    : Clear Peak score in percent\n');
fprintf(fid,'  RelClass  : Reliability class\n');
fprintf(fid,'  ClrClass  : Clear Peak class\n');
fprintf(fid,'  X_UTM     : UTM Easting\n');
fprintf(fid,'  Y_UTM     : UTM Northing\n');
fprintf(fid,'  Z         : Elevation\n');
fprintf(fid,'  V1-V9     : Individual SESAME criterion results (1=PASS, 0=FAIL)\n');
fprintf(fid,'              Values are numeric in both CSV and Shapefile DBF.\n');
fprintf(fid,'              Criterion codes represent the nine checks in SESAME (2004).\n');
fprintf(fid,'  Note      : Display maps show the supplied input X/Y coordinates in kilometres.\n');
fprintf(fid,'              CSV and Shapefile retain the input UTM coordinates.\n');

fclose(fid);

end

%% ========================================================================
function createKMZ(latlonTable,outKmz)
% Creates a multi-layer .kmz file:
% Overall Classification, Reliability Score Map, Clear Peak Score Map.

kmlStr = '';
kmlStr = [kmlStr '<?xml version="1.0" encoding="UTF-8"?>' newline];
kmlStr = [kmlStr '<kml xmlns="http://www.opengis.net/kml/2.2">' newline];
kmlStr = [kmlStr '<Document><name>HV-SESAME Analyzer Results</name>' newline];

styleDefs = { ...
    'overall_accepted',   'icons/overall_accepted.png'; ...
    'overall_controlled', 'icons/overall_controlled.png'; ...
    'overall_rejected',   'icons/overall_rejected.png'; ...
    'score_green',        'icons/score_green.png'; ...
    'score_yellow',       'icons/score_yellow.png'; ...
    'score_orange',       'icons/score_orange.png'; ...
    'score_red',          'icons/score_red.png'};

for s = 1:size(styleDefs,1)
    kmlStr = [kmlStr '<Style id="' styleDefs{s,1} '"><IconStyle><scale>1.10</scale>' ...
        '<Icon><href>' styleDefs{s,2} '</href></Icon>' ...
        '</IconStyle><LabelStyle><scale>0.72</scale></LabelStyle></Style>' newline]; %#ok<AGROW>
end

kmlStr = [kmlStr createKMZLayer(latlonTable,'overall')];
kmlStr = [kmlStr createKMZLayer(latlonTable,'reliability')];
kmlStr = [kmlStr createKMZLayer(latlonTable,'clear')];

kmlStr = [kmlStr '</Document>' newline '</kml>'];

tempDir = tempname;
mkdir(tempDir);
iconsDir = fullfile(tempDir,'icons');
mkdir(iconsDir);

fid = fopen(fullfile(tempDir,'doc.kml'),'w');
fwrite(fid,kmlStr,'char');
fclose(fid);

createKmzIcon(fullfile(iconsDir,'overall_accepted.png'),   [0.00 0.62 0.20], 'check');
createKmzIcon(fullfile(iconsDir,'overall_controlled.png'), [0.95 0.66 0.00], 'warn');
createKmzIcon(fullfile(iconsDir,'overall_rejected.png'),   [0.80 0.05 0.05], 'cross');

createKmzIcon(fullfile(iconsDir,'score_green.png'),  [0.00 0.62 0.20], 'circle');
createKmzIcon(fullfile(iconsDir,'score_yellow.png'), [0.95 0.78 0.00], 'circle');
createKmzIcon(fullfile(iconsDir,'score_orange.png'), [0.95 0.45 0.00], 'circle');
createKmzIcon(fullfile(iconsDir,'score_red.png'),    [0.80 0.05 0.05], 'circle');

zipFile = [tempname '.zip'];
zip(zipFile, {'doc.kml','icons'}, tempDir);

if exist(outKmz,'file'); delete(outKmz); end
movefile(zipFile,outKmz,'f');

try
    rmdir(tempDir,'s');
catch
end

end

%% ========================================================================
function layerStr = createKMZLayer(T,layerType)

switch lower(layerType)
    case 'overall'
        folderName = 'Overall Classification';
        openFlag = '1';
    case 'reliability'
        folderName = 'Reliability Score Map (V1-V3)';
        openFlag = '0';
    case 'clear'
        folderName = 'Clear Peak Score Map (V4-V9)';
        openFlag = '0';
end

layerStr = ['<Folder><name>' folderName '</name><open>' openFlag '</open>' newline];

for i = 1:height(T)
    if isnan(T.Lat(i)) || isnan(T.Lon(i)); continue; end

    switch lower(layerType)
        case 'overall'
            if T.AllPass(i)
                styleUrl = '#overall_accepted'; status = 'ACCEPTED';
            elseif T.Controlled(i)
                styleUrl = '#overall_controlled'; status = 'CONTROLLED ACCEPTANCE';
            else
                styleUrl = '#overall_rejected'; status = 'REJECTED';
            end
            labelName = sprintf('%s  f0=%.3f Hz',char(T.Name(i)),T.f0(i));

        case 'reliability'
            score = T.ReliabilityScore(i);
            styleUrl = scoreToKMLStyle(score);
            status = sprintf('Reliability Score: %.0f%%',score*100);
            labelName = sprintf('%s  R=%.0f%%',char(T.Name(i)),score*100);

        case 'clear'
            score = T.ClearScore(i);
            styleUrl = scoreToKMLStyle(score);
            status = sprintf('Clear Peak Score: %.0f%%',score*100);
            labelName = sprintf('%s  C=%.0f%%',char(T.Name(i)),score*100);
    end

    desc = buildKMLDescription(T,i,status);
    layerStr = [layerStr buildPlacemark(labelName,styleUrl,desc,T.Lon(i),T.Lat(i),T.Z(i))]; %#ok<AGROW>
end

layerStr = [layerStr '</Folder>' newline];

end

%% ========================================================================
function styleUrl = scoreToKMLStyle(score)

if score >= 0.999
    styleUrl = '#score_green';
elseif score >= 0.80
    styleUrl = '#score_yellow';
elseif score >= 0.50
    styleUrl = '#score_orange';
else
    styleUrl = '#score_red';
end

end

%% ========================================================================
function desc = buildKMLDescription(T,i,status)

failed = getFailedCriteriaString(T,i);

desc = sprintf(['<![CDATA[' ...
    '<b>Station:</b> %s<br/>' ...
    '<b>Status:</b> %s<br/><br/>' ...
    '<b>Reliability:</b> %.0f%% (%s)<br/>' ...
    '<b>Clear Peak:</b> %.0f%% (%s)<br/>' ...
    '<b>Quality Index:</b> %.0f%%<br/><br/>' ...
    '<b>f0:</b> %.4f Hz<br/>' ...
    '<b>T0:</b> %.3f s<br/>' ...
    '<b>A0:</b> %.3f<br/><br/>' ...
    '<b>Failed Criteria:</b> %s' ...
    ']]>'], ...
    char(T.Name(i)),status, ...
    T.ReliabilityScore(i)*100,yesno(T.Reliable(i)), ...
    T.ClearScore(i)*100,yesno(T.Clear(i)), ...
    T.QualityScore(i)*100, ...
    T.f0(i),T.T0(i),T.A0(i),failed);

end

%% ========================================================================
function failed = getFailedCriteriaString(T,i)

critNames = {'V1','V2','V3','V4','V5','V6','V7','V8','V9'};
critVals = [T.V1(i) T.V2(i) T.V3(i) T.V4(i) T.V5(i) T.V6(i) T.V7(i) T.V8(i) T.V9(i)];
bad = critNames(~critVals);

if isempty(bad)
    failed = 'None';
else
    failed = strjoin(bad,', ');
end

end

%% ========================================================================
function kml = buildPlacemark(name,styleUrl,desc,lon,lat,z)

kml = '';
kml = [kml '<Placemark>' newline];
kml = [kml '<name>' char(name) '</name>' newline];
kml = [kml '<styleUrl>' styleUrl '</styleUrl>' newline];
kml = [kml '<description>' desc '</description>' newline];
kml = [kml '<Point><coordinates>' num2str(lon,'%.8f') ',' num2str(lat,'%.8f') ',' num2str(z,'%.2f') ...
    '</coordinates></Point>' newline];
kml = [kml '</Placemark>' newline];

end

%% ========================================================================
function createKmzIcon(fileName, rgb, symbolType)
% Create a small transparent PNG marker icon for KMZ export.
% rgb values must be in [0,1].
% symbolType: 'check', 'warn', or 'cross'

N = 96;
[x,y] = meshgrid(1:N,1:N);
cx = N/2;
cy = N/2;
r = N*0.39;

circle = ((x-cx).^2 + (y-cy).^2) <= r^2;

% Small pointed tip, so it behaves visually like a map marker
tip = false(N,N);
for yy = round(cy+r*0.55):N-5
    halfWidth = max(1, round((N-yy)*0.23));
    tip(yy, max(1,round(cx-halfWidth)):min(N,round(cx+halfWidth))) = true;
end

mask = circle | tip;

img = ones(N,N,3);
for k = 1:3
    channel = img(:,:,k);
    channel(mask) = rgb(k);
    img(:,:,k) = channel;
end

alpha = uint8(mask) * 255;

% Add a subtle darker border
border = bwperim_compat(mask);
for k = 1:3
    channel = img(:,:,k);
    channel(border) = max(0, rgb(k)*0.55);
    img(:,:,k) = channel;
end

% White symbol
sym = false(N,N);

switch lower(symbolType)
    case 'check'
        sym = sym | lineMask(N,[30 50],[42 63],4);
        sym = sym | lineMask(N,[42 63],[68 34],4);
    case 'warn'
        sym(25:60,46:51) = true;
        [xx,yy] = meshgrid(1:N,1:N);
        sym = sym | ((xx-48).^2 + (yy-72).^2 <= 5^2);
    case 'cross'
        sym = sym | lineMask(N,[32 33],[64 65],5);
        sym = sym | lineMask(N,[64 33],[32 65],5);
    case 'circle'
        sym = false(N,N);
end

sym = sym & mask;
for k = 1:3
    channel = img(:,:,k);
    channel(sym) = 1;
    img(:,:,k) = channel;
end

imwrite(img,fileName,'png','Alpha',alpha);

end

%% ========================================================================
function m = lineMask(N,p1,p2,width)
% Binary mask for a thick line segment in an N x N image

[x,y] = meshgrid(1:N,1:N);

x1 = p1(1); y1 = p1(2);
x2 = p2(1); y2 = p2(2);

dx = x2-x1;
dy = y2-y1;
L2 = dx^2 + dy^2;

if L2 == 0
    m = false(N,N);
    return;
end

t = ((x-x1)*dx + (y-y1)*dy) / L2;
t = max(0,min(1,t));

projx = x1 + t*dx;
projy = y1 + t*dy;

dist = sqrt((x-projx).^2 + (y-projy).^2);
m = dist <= width;

end

%% ========================================================================
function b = bwperim_compat(mask)
% Toolbox-free perimeter extraction for a binary mask

up    = [false(1,size(mask,2)); mask(1:end-1,:)];
down  = [mask(2:end,:); false(1,size(mask,2))];
left  = [false(size(mask,1),1) mask(:,1:end-1)];
right = [mask(:,2:end) false(size(mask,1),1)];

b = mask & ~(up & down & left & right);

end

%% ========================================================================
function createPDFReportCompat(finalTable, allResults, outPdf)
forceLightTheme();
% PDF report generator with transparent, basemap-free project maps.
% - Map axes display the supplied X/Y coordinates in kilometres (input metres / 1000).
% - Shapes as well as colours convey quality categories.
% - Original GIS coordinate values are not modified.

[outDir,outName,~] = fileparts(outPdf);
tempDir = fullfile(outDir,[outName '_pdf_pages']);

if exist(tempDir,'dir')
    rmdir(tempDir,'s');
end
mkdir(tempDir);

pageFiles = {};
pageNo = 0;

rowsPerPage = 18;
numTablePages = ceil(height(finalTable)/rowsPerPage);
totalSteps = 1 + 3 + numTablePages + 1 + 1;
% summary + 3 maps + table pages + criteria statistics + merge
% Station-level H/V plots are intentionally omitted from PDF for speed/readability.

progressFig = createExportProgressDialog(totalSteps);
cleanupObj = onCleanup(@()safeCloseProgress(progressFig)); %#ok<NASGU>

stepCounter = 0;

    function updateProgress(msg)
        stepCounter = stepCounter + 1;
        updateExportProgress(progressFig,stepCounter,totalSteps,msg);
    end

% No online map service is accessed during report creation.

% Cover/Summary
updateProgress('Creating summary page...');
pageNo = pageNo + 1;
fig = makeSummaryFigure(finalTable);
pageFiles{end+1} = printPage(fig,tempDir,pageNo); %#ok<AGROW>
close(fig);

% Project map pages
updateProgress('Creating overall classification map...');
pageNo = pageNo + 1;
fig = makeProjectMapFigure(finalTable,'overall');
pageFiles{end+1} = printPage(fig,tempDir,pageNo); %#ok<AGROW>
close(fig);

updateProgress('Creating reliability score map...');
pageNo = pageNo + 1;
fig = makeProjectMapFigure(finalTable,'reliability');
pageFiles{end+1} = printPage(fig,tempDir,pageNo); %#ok<AGROW>
close(fig);

updateProgress('Creating clear peak score map...');
pageNo = pageNo + 1;
fig = makeProjectMapFigure(finalTable,'clear');
pageFiles{end+1} = printPage(fig,tempDir,pageNo); %#ok<AGROW>
close(fig);

% Batch table pages
for p = 1:numTablePages
    updateProgress(sprintf('Creating batch results table page %d/%d...',p,numTablePages));
    pageNo = pageNo + 1;
    i1 = (p-1)*rowsPerPage + 1;
    i2 = min(p*rowsPerPage,height(finalTable));
    fig = makeTableFigure(finalTable(i1:i2,:),p,numTablePages);
    pageFiles{end+1} = printPage(fig,tempDir,pageNo); %#ok<AGROW>
    close(fig);
end

% Criteria statistics page
updateProgress('Creating criteria statistics page...');
pageNo = pageNo + 1;
fig = makeCriteriaStatisticsFigure(finalTable);
pageFiles{end+1} = printPage(fig,tempDir,pageNo); %#ok<AGROW>
close(fig);

% Merge attempt
updateProgress('Merging PDF pages...');
ok = mergePDFsWithGhostscript(pageFiles,outPdf);

if ok
    try
        rmdir(tempDir,'s');
    catch
    end

    updateExportProgress(progressFig,totalSteps,totalSteps,'PDF report completed.');
    pause(0.3);

    try
        open(outPdf);
    catch
    end
else
    msg = sprintf(['Ghostscript was not found, so PDF pages could not be merged into a single file.\n\n' ...
        'Pages were saved to:\n%s\n\n' ...
        'If Ghostscript is installed and available on the system path, the program will automatically generate a single PDF.'],tempDir);
    warndlg(msg,'PDF Pages Saved Separately');
end

end

%% ========================================================================
function h = createExportProgressDialog(totalSteps)

h = figure('Name','Exporting PDF Report', ...
    'NumberTitle','off', ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'Units','pixels', ...
    'Position',[520 420 520 145], ...
    'Color',[0.96 0.97 0.98], ...
    'Resize','off', ...
    'WindowStyle','modal', ...
    'InvertHardcopy','off');

uicontrol('Parent',h,'Style','text', ...
    'Units','normalized','Position',[0.05 0.70 0.90 0.18], ...
    'String','Creating PDF Report...', ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'ForegroundColor',[0.05 0.16 0.28], ...
    'HorizontalAlignment','left', ...
    'FontSize',11, ...
    'FontWeight','bold');

h.UserData.msg = uicontrol('Parent',h,'Style','text', ...
    'Units','normalized','Position',[0.05 0.50 0.90 0.16], ...
    'String','Preparing...', ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'ForegroundColor',[0.20 0.20 0.20], ...
    'HorizontalAlignment','left', ...
    'FontSize',9);

h.UserData.ax = axes('Parent',h,'Units','normalized','Position',[0.05 0.25 0.90 0.13]);
axis(h.UserData.ax,'off');
xlim(h.UserData.ax,[0 1]); ylim(h.UserData.ax,[0 1]);

h.UserData.count = uicontrol('Parent',h,'Style','text', ...
    'Units','normalized','Position',[0.05 0.08 0.90 0.12], ...
    'String',sprintf('0 / %d',totalSteps), ...
    'BackgroundColor',[0.96 0.97 0.98], ...
    'ForegroundColor',[0.25 0.25 0.25], ...
    'HorizontalAlignment','right', ...
    'FontSize',8);

drawnow;

end

%% ========================================================================
function updateExportProgress(h,currentStep,totalSteps,msg)

if isempty(h) || ~ishandle(h)
    return;
end

frac = max(0,min(1,currentStep/max(totalSteps,1)));

try
    set(h.UserData.msg,'String',msg);
    set(h.UserData.count,'String',sprintf('%d / %d',currentStep,totalSteps));

    ax = h.UserData.ax;
    cla(ax);
    axis(ax,'off');
    xlim(ax,[0 1]); ylim(ax,[0 1]);

    rectangle(ax,'Position',[0 0.25 1 0.50], ...
        'FaceColor',[0.86 0.88 0.90], ...
        'EdgeColor',[0.70 0.74 0.78]);

    rectangle(ax,'Position',[0 0.25 frac 0.50], ...
        'FaceColor',[0.20 0.55 0.85], ...
        'EdgeColor','none');

    text(ax,0.50,0.50,sprintf('%.0f%%',frac*100), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontSize',8, ...
        'FontWeight','bold', ...
        'Color',[0.05 0.05 0.05]);

    drawnow;
catch
end

end

%% ========================================================================
function safeCloseProgress(h)

try
    if ~isempty(h) && ishandle(h)
        close(h);
    end
catch
end

end


function fig = makeSummaryFigure(finalTable)
% Modern GUI-compatible cover/summary page for PDF export.

fig = figure('Visible','off','Units','pixels','Position',[100 100 1500 850], ...
    'Color',[0.96 0.97 0.98],'InvertHardcopy','off');

ax = axes(fig,'Position',[0 0 1 1]);
axis(ax,'off');
xlim(ax,[0 1]);
ylim(ax,[0 1]);

nTotal = height(finalTable);
nOK = sum(finalTable.AllPass);
nControlled = sum(finalTable.Controlled);
nReject = nTotal - nOK - nControlled;

relScoreTotal = sum(finalTable.Reliable);
clearScoreTotal = sum(finalTable.Clear);
relPct = safeRatio(relScoreTotal,nTotal);
clearPct = safeRatio(clearScoreTotal,nTotal);

% Header
rectangle(ax,'Position',[0.025 0.875 0.95 0.095], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);

text(ax,0.045,0.935,'HV-SESAME ANALYZER', ...
    'FontSize',24,'FontWeight','bold','Color',[0.05 0.16 0.28]);

text(ax,0.047,0.900,'Automated SESAME Reliability and Clear Peak Assessment Report', ...
    'FontSize',12,'Color',[0.25 0.30 0.35]);



% Status cards
drawModernCard(ax,0.035,0.735,0.215,0.105,'Total Stations',sprintf('%d',nTotal),[0.90 0.94 1.00],[0.05 0.20 0.45]);
drawModernCard(ax,0.275,0.735,0.215,0.105,'Accepted',sprintf('%d',nOK),[0.90 0.98 0.92],[0.00 0.40 0.12]);
drawModernCard(ax,0.515,0.735,0.215,0.105,'Controlled',sprintf('%d',nControlled),[1.00 0.96 0.84],[0.65 0.38 0.00]);
drawModernCard(ax,0.755,0.735,0.210,0.105,'Rejected',sprintf('%d',nReject),[1.00 0.90 0.90],[0.60 0.00 0.00]);

% Progress panel
rectangle(ax,'Position',[0.035 0.500 0.455 0.190], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);

summaryCenterX = 0.035 + 0.455/2;

text(ax,summaryCenterX,0.662,'Project-Level Criteria Summary', ...
    'FontSize',13,'FontWeight','bold','Color',[0.05 0.16 0.28], ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');

text(ax,summaryCenterX,0.620,sprintf('Stations passing Reliability (V1-V3): %d / %d',relScoreTotal,nTotal), ...
    'FontSize',10,'FontWeight','bold', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');

drawStaticProgress(ax,0.085,0.588,0.315,0.020,relPct,[0.20 0.70 0.30]);

text(ax,summaryCenterX,0.545,sprintf('Stations passing Clear Peak (V4-V9): %d / %d',clearScoreTotal,nTotal), ...
    'FontSize',10,'FontWeight','bold', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');

drawStaticProgress(ax,0.085,0.513,0.315,0.020,clearPct,[0.95 0.70 0.05]);

% Definition panel
rectangle(ax,'Position',[0.515 0.500 0.450 0.190], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax,0.535,0.662,'Status Definitions', ...
    'FontSize',13,'FontWeight','bold','Color',[0.05 0.16 0.28]);
text(ax,0.535,0.620,'Accepted: Reliability = TRUE and Clear Peak = TRUE', 'FontSize',10);
text(ax,0.535,0.580,'Controlled Acceptance: only one group is TRUE', 'FontSize',10);
text(ax,0.535,0.540,'Rejected: Reliability = FALSE and Clear Peak = FALSE', 'FontSize',10);

% Bar chart panel
rectangle(ax,'Position',[0.035 0.070 0.455 0.390], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
barAx = axes('Parent',fig,'Position',[0.085 0.130 0.355 0.265]);
bar(barAx,[nOK nControlled nReject],0.55);
set(barAx,'XTickLabel',{'Accepted','Controlled','Rejected'});
ylabel(barAx,'Count');
title(barAx,'Station Status Distribution');
grid(barAx,'on');
barAx.Color = 'white';
barAx.XColor = 'black';
barAx.YColor = 'black';

% Failure count chart panel
rectangle(ax,'Position',[0.515 0.070 0.450 0.390], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);

failCounts = [sum(~finalTable.V1) sum(~finalTable.V2) sum(~finalTable.V3) ...
              sum(~finalTable.V4) sum(~finalTable.V5) sum(~finalTable.V6) ...
              sum(~finalTable.V7) sum(~finalTable.V8) sum(~finalTable.V9)];

failAx = axes('Parent',fig,'Position',[0.565 0.130 0.350 0.265]);
bar(failAx,failCounts,0.55);
set(failAx,'XTickLabel',{'V1','V2','V3','V4','V5','V6','V7','V8','V9'});
ylabel(failAx,'Failed Count');
title(failAx,'Failed Criteria Statistics');
grid(failAx,'on');
failAx.Color = 'white';
failAx.XColor = 'black';
failAx.YColor = 'black';

% Footer date/time
text(ax,0.955,0.035,sprintf('Generated: %s',datestr(now,'dd.mm.yyyy HH:MM')), ...
    'FontSize',9, ...
    'Color',[0.40 0.40 0.40], ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle');

end

function fig = makeProjectMapFigure(finalTable,mapType)
% Basemap-free project map using the supplied input coordinates.
% Input X/Y coordinates are converted from metres to kilometres for display only.
% No geographic basemap is used.

fig = figure('Visible','off','Units','pixels','Position',[100 100 1500 850], ...
    'Color',[0.96 0.97 0.98],'InvertHardcopy','off');

ax0 = axes('Parent',fig,'Position',[0 0 1 1]);
axis(ax0,'off'); xlim(ax0,[0 1]); ylim(ax0,[0 1]);
hold(ax0,'on'); % Prevent legend symbols from clearing earlier page elements.

switch lower(mapType)
    case 'overall'
        titleStr = 'Overall SESAME Classification Map';
        subtitleStr = 'Accepted / Controlled Acceptance / Rejected';
    case 'reliability'
        titleStr = 'Reliability Score Map';
        subtitleStr = 'Score based on V1-V3 criteria';
    case 'clear'
        titleStr = 'Clear Peak Score Map';
        subtitleStr = 'Score based on V4-V9 criteria';
    otherwise
        error('Unknown map type: %s',mapType);
end

rectangle(ax0,'Position',[0.025 0.875 0.95 0.085], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax0,0.045,0.935,titleStr,'FontSize',18,'FontWeight','bold', ...
    'Color',[0.05 0.16 0.28],'VerticalAlignment','middle');
text(ax0,0.045,0.900,[subtitleStr '  |  Input X/Y coordinates (no geographic basemap)'], ...
    'FontSize',10,'Color',[0.30 0.35 0.40],'VerticalAlignment','middle');

rectangle(ax0,'Position',[0.045 0.100 0.680 0.760], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
mapAx = axes('Parent',fig,'Position',[0.095 0.185 0.580 0.600]);
hold(mapAx,'on'); box(mapAx,'on'); grid(mapAx,'on');
set(mapAx,'Color',[1 1 1],'XColor',[0.20 0.25 0.30], ...
    'YColor',[0.20 0.25 0.30],'GridColor',[0.86 0.89 0.92], ...
    'GridAlpha',0.45,'FontSize',10);

validXY = isfinite(finalTable.X) & isfinite(finalTable.Y);
if any(validXY)
    % Scale input coordinates (metres) to kilometres for map display only.
    % No origin shift; GIS/KMZ input coordinates remain unchanged.
    xDisplay = finalTable.X / 1000;
    yDisplay = finalTable.Y / 1000;
    setupMapLimits(mapAx,xDisplay(validXY),yDisplay(validXY), ...
        'Easting (input X, km)','Northing (input Y, km)');
    axis(mapAx,'equal'); % Keep distance scaling the same on both map axes.
    mapAx.XAxis.Exponent = 0;
    mapAx.YAxis.Exponent = 0;
    plotProjectPointsOnMap(mapAx,finalTable,mapType,xDisplay,yDisplay);
elseif any(isfinite(finalTable.Lon) & isfinite(finalTable.Lat))
    validLL = isfinite(finalTable.Lon) & isfinite(finalTable.Lat);
    xDisplay = finalTable.Lon;
    yDisplay = finalTable.Lat;
    setupMapLimits(mapAx,xDisplay(validLL),yDisplay(validLL),'Longitude','Latitude');
    plotProjectPointsOnMap(mapAx,finalTable,mapType,xDisplay,yDisplay);
else
    text(mapAx,0.5,0.5,'No coordinate data available.', ...
        'Units','normalized','HorizontalAlignment','center');
end

title(mapAx,'Station distribution (input coordinates, no topography)', ...
    'FontSize',11,'FontWeight','bold');

rectangle(ax0,'Position',[0.755 0.100 0.220 0.760], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax0,0.775,0.820,'Legend','FontSize',14,'FontWeight','bold', ...
    'Color',[0.05 0.16 0.28]);

if strcmpi(mapType,'overall')
    legendColors = {[0.00 0.48 0.23],[0.93 0.62 0.02],[0.75 0.08 0.12]};
    legendLabels = {'Accepted','Controlled Acceptance','Rejected'};
    legendMarkers = {'o','s','^'};
else
    legendColors = {[0.00 0.48 0.23],[0.92 0.75 0.05], ...
                    [0.90 0.44 0.05],[0.75 0.08 0.12]};
    legendLabels = {'100%','80-99%','50-79%','<50%'};
    legendMarkers = {'o','d','s','^'};
end

for k = 1:numel(legendLabels)
    yy = 0.770-(k-1)*0.059;
    plot(ax0,0.788,yy,legendMarkers{k},'MarkerSize',10, ...
        'MarkerFaceColor',legendColors{k},'MarkerEdgeColor',[0.12 0.17 0.20], ...
        'LineStyle','none','LineWidth',0.9);
    text(ax0,0.810,yy,legendLabels{k},'FontSize',10, ...
        'VerticalAlignment','middle');
end

nTotal = height(finalTable);
nOK = sum(finalTable.AllPass);
nControlled = sum(finalTable.Controlled);
nReject = nTotal-nOK-nControlled;
text(ax0,0.775,0.500,'Project Summary','FontSize',14, ...
    'FontWeight','bold','Color',[0.05 0.16 0.28]);
text(ax0,0.775,0.455,sprintf('Total stations: %d',nTotal),'FontSize',10);
text(ax0,0.775,0.420,sprintf('Accepted: %d',nOK),'FontSize',10);
text(ax0,0.775,0.385,sprintf('Controlled: %d',nControlled),'FontSize',10);
text(ax0,0.775,0.350,sprintf('Rejected: %d',nReject),'FontSize',10);
if ~strcmpi(mapType,'overall')
    if strcmpi(mapType,'reliability')
        scoreMean = mean(finalTable.ReliabilityScore,'omitnan');
        scoreLabel = 'Mean Reliability';
    else
        scoreMean = mean(finalTable.ClearScore,'omitnan');
        scoreLabel = 'Mean Clear Peak';
    end
    text(ax0,0.775,0.285,sprintf('%s: %.0f%%',scoreLabel,scoreMean*100), ...
        'FontSize',10,'FontWeight','bold');
end
text(ax0,0.775,0.160,'Shape and colour both encode', ...
    'FontSize',8.5,'Color',[0.28 0.31 0.35]);
text(ax0,0.775,0.133,'the quality category.', ...
    'FontSize',8.5,'Color',[0.28 0.31 0.35]);
end

%% ========================================================================
function plotProjectPointsOnMap(mapAx,finalTable,mapType,xData,yData)
% Plot symbols first, then station names once each; no overlapping status text.
valid = isfinite(xData) & isfinite(yData);
indices = find(valid);
if isempty(indices); return; end
for q = 1:numel(indices)
    i = indices(q);
    [rgb,markerSymbol] = mapPointStyle(finalTable,i,mapType);
    plot(mapAx,xData(i),yData(i),markerSymbol, ...
        'MarkerSize',9,'MarkerFaceColor',rgb, ...
        'MarkerEdgeColor',[0.12 0.17 0.20], ...
        'LineStyle','none','LineWidth',0.9);
end

% Select label positions from multiple candidates and penalise overlap.
xLimits = xlim(mapAx); yLimits = ylim(mapAx);
xSpan = diff(xLimits); ySpan = diff(yLimits);
xNorm = (xData(indices)-xLimits(1))/xSpan;
yNorm = (yData(indices)-yLimits(1))/ySpan;
labelBoxes = zeros(0,4);

for q = 1:numel(indices)
    i = indices(q);
    name = char(finalTable.Name(i));
    w = min(0.110,max(0.044,0.014*numel(name)+0.012));
    h = 0.030;
    u = xNorm(q); v = yNorm(q);
    candidates = [ ...
         u+0.014, v+0.010; ...
         u+0.014, v-0.010-h; ...
         u-0.014-w, v+0.010; ...
         u-0.014-w, v-0.010-h; ...
         u-w/2, v+0.025; ...
         u-w/2, v-0.025-h; ...
         u+0.014, v-h/2; ...
         u-0.014-w, v-h/2];
    bestPenalty = inf;
    bestBox = [];
    for j = 1:size(candidates,1)
        b = [candidates(j,1), candidates(j,2), ...
            candidates(j,1)+w, candidates(j,2)+h];
        outside = max(0,0.005-b(1))+max(0,b(3)-0.995) + ...
                  max(0,0.005-b(2))+max(0,b(4)-0.995);
        penalty = outside*300;
        for k = 1:size(labelBoxes,1)
            c = labelBoxes(k,:);
            overlapX = max(0,min(b(3),c(3))-max(b(1),c(1)));
            overlapY = max(0,min(b(4),c(4))-max(b(2),c(2)));
            penalty = penalty + 10*overlapX*overlapY/(w*h);
        end
        % Avoid covering other station symbols with labels.
        for k = 1:numel(indices)
            if k==q; continue; end
            if xNorm(k)>b(1)-0.008 && xNorm(k)<b(3)+0.008 && ...
               yNorm(k)>b(2)-0.008 && yNorm(k)<b(4)+0.008
                penalty = penalty + 2;
            end
        end
        if penalty < bestPenalty
            bestPenalty = penalty;
            bestBox = b;
        end
    end
    labelBoxes(end+1,:) = bestBox; %#ok<AGROW>
    xx = xLimits(1)+bestBox(1)*xSpan;
    yy = yLimits(1)+(bestBox(2)+h/2)*ySpan;
    text(mapAx,xx,yy,name,'FontSize',8.5,'FontWeight','bold', ...
        'BackgroundColor','white','Margin',1, ...
        'HorizontalAlignment','left','VerticalAlignment','middle', ...
        'Clipping','on','Interpreter','none','Color',[0.11 0.14 0.19]);
end
end

%% ========================================================================
function [rgb,markerSymbol] = mapPointStyle(T,i,mapType)
switch lower(mapType)
    case 'overall'
        if T.AllPass(i)
            rgb = [0.00 0.48 0.23]; markerSymbol = 'o';
        elseif T.Controlled(i)
            rgb = [0.93 0.62 0.02]; markerSymbol = 's';
        else
            rgb = [0.75 0.08 0.12]; markerSymbol = '^';
        end
    case {'reliability','clear'}
        if strcmpi(mapType,'reliability')
            value = T.ReliabilityScore(i);
        else
            value = T.ClearScore(i);
        end
        if value >= 0.999
            rgb = [0.00 0.48 0.23]; markerSymbol = 'o';
        elseif value >= 0.80
            rgb = [0.92 0.75 0.05]; markerSymbol = 'd';
        elseif value >= 0.50
            rgb = [0.90 0.44 0.05]; markerSymbol = 's';
        else
            rgb = [0.75 0.08 0.12]; markerSymbol = '^';
        end
end
end

%% ========================================================================
function setupMapLimits(mapAx,X,Y,xLab,yLab)
padX = max((max(X)-min(X))*0.14,0.05);
padY = max((max(Y)-min(Y))*0.14,0.05);
xlim(mapAx,[min(X)-padX max(X)+padX]);
ylim(mapAx,[min(Y)-padY max(Y)+padY]);
xlabel(mapAx,xLab); ylabel(mapAx,yLab);
grid(mapAx,'on'); box(mapAx,'on');
end

%% ========================================================================
function fig = makeTableFigure(subT,pageIdx,numPages)
% Modern batch results table matching the V5 GUI style.
% V5.3: Lat/Lon columns are omitted and T0 is reported.

fig = figure('Visible','off','Units','pixels','Position',[100 100 1500 850], ...
    'Color',[0.96 0.97 0.98],'InvertHardcopy','off');

ax = axes(fig,'Position',[0 0 1 1]);
axis(ax,'off');
xlim(ax,[0 1]);
ylim(ax,[0 1]);

% Header
rectangle(ax,'Position',[0.025 0.875 0.95 0.085], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);

text(ax,0.045,0.925,sprintf('Batch Results Table  |  Page %d / %d',pageIdx,numPages), ...
    'FontSize',18,'FontWeight','bold','Color',[0.05 0.16 0.28], ...
    'VerticalAlignment','middle');

% Table container
rectangle(ax,'Position',[0.025 0.055 0.95 0.815], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);

headers = {'Name','X','Y','Z','f0','T0','A0','Rel.','Clear','Status'};
colX = [0.045 0.135 0.255 0.375 0.475 0.565 0.650 0.735 0.805 0.885];

y0 = 0.830;
dy = 0.043;

rectangle(ax,'Position',[0.035 y0-0.018 0.925 0.040], ...
    'FaceColor',[0.90 0.94 0.98],'EdgeColor',[0.70 0.75 0.80]);

for c = 1:numel(headers)
    text(ax,colX(c),y0,headers{c},'FontSize',9,'FontWeight','bold','VerticalAlignment','middle');
end

for r = 1:height(subT)
    yy = y0 - r*dy;

    if mod(r,2)==0
        rectangle(ax,'Position',[0.035 yy-0.018 0.925 0.036], ...
            'FaceColor',[0.97 0.98 0.99],'EdgeColor','none');
    end

    if subT.AllPass(r)
        statusStr = 'ACCEPTED';
        bg = [0.78 0.92 0.78];
        fg = [0.00 0.35 0.00];
        marker = 'A';
    elseif subT.Controlled(r)
        statusStr = 'CONTROLLED';
        bg = [1.00 0.91 0.55];
        fg = [0.60 0.35 0.00];
        marker = 'C';
    else
        statusStr = 'REJECTED';
        bg = [0.95 0.72 0.72];
        fg = [0.55 0.00 0.00];
        marker = 'R';
    end

    % colored status pill
    rectangle(ax,'Position',[0.880 yy-0.015 0.075 0.030], ...
        'FaceColor',bg,'EdgeColor',[0.80 0.80 0.80], 'Curvature',[0.25 0.25]);
    text(ax,0.917,yy,marker,'FontSize',8.5,'FontWeight','bold', ...
        'Color',fg,'HorizontalAlignment','center','VerticalAlignment','middle');

    vals = { ...
        char(subT.Name(r)), ...
        sprintf('%.2f',subT.X(r)), ...
        sprintf('%.2f',subT.Y(r)), ...
        sprintf('%.1f',subT.Z(r)), ...
        sprintf('%.4f',subT.f0(r)), ...
        sprintf('%.3f',subT.T0(r)), ...
        sprintf('%.3f',subT.A0(r)), ...
        yesno(subT.Reliable(r)), ...
        yesno(subT.Clear(r)), ...
        statusStr};

    for c = 1:9
        text(ax,colX(c),yy,vals{c},'FontSize',8.8,'VerticalAlignment','middle');
    end
end

% legend
text(ax,0.045,0.030,'A: Accepted     C: Controlled Acceptance     R: Rejected', ...
    'FontSize',9,'Color',[0.35 0.35 0.35]);

end

function fig = makeCriteriaStatisticsFigure(finalTable)
% Criteria statistics and report note page.

fig = figure('Visible','off','Units','pixels','Position',[100 100 1500 850], ...
    'Color',[0.96 0.97 0.98],'InvertHardcopy','off');

ax = axes(fig,'Position',[0 0 1 1]);
axis(ax,'off'); xlim(ax,[0 1]); ylim(ax,[0 1]);

rectangle(ax,'Position',[0.025 0.875 0.95 0.085], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax,0.045,0.930,'SESAME Criteria Statistics', ...
    'FontSize',18,'FontWeight','bold','Color',[0.05 0.16 0.28], ...
    'VerticalAlignment','middle');
text(ax,0.045,0.898,'Station-level H/V plots are available interactively in the software.', ...
    'FontSize',10,'Color',[0.30 0.35 0.40], ...
    'VerticalAlignment','middle');

rectangle(ax,'Position',[0.045 0.120 0.565 0.735], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);

n = height(finalTable);
critNames = {'V1','V2','V3','V4','V5','V6','V7','V8','V9'};
critDesc = {'f0 > 10/Iw','nc(f0) > 200','amplitude stability', ...
            'clear low','clear high','A0 > 2','peak +/-5%', ...
            'sigma_f < epsilon(f0)','sigma_A(f0) < theta(f0)'};

passCounts = [sum(finalTable.V1) sum(finalTable.V2) sum(finalTable.V3) ...
              sum(finalTable.V4) sum(finalTable.V5) sum(finalTable.V6) ...
              sum(finalTable.V7) sum(finalTable.V8) sum(finalTable.V9)];

failCounts = n - passCounts;
passPct = passCounts ./ max(n,1) * 100;

headers = {'Criterion','Description','Passed','Failed','Pass %'};
colX = [0.070 0.160 0.360 0.445 0.530];
y0 = 0.805;
dy = 0.060;

rectangle(ax,'Position',[0.060 y0-0.020 0.525 0.045], ...
    'FaceColor',[0.90 0.94 0.98],'EdgeColor',[0.70 0.75 0.80]);

for c = 1:numel(headers)
    text(ax,colX(c),y0,headers{c},'FontSize',9,'FontWeight','bold','VerticalAlignment','middle');
end

for k = 1:9
    yy = y0 - k*dy;

    if mod(k,2)==0
        rectangle(ax,'Position',[0.060 yy-0.020 0.525 0.040], ...
            'FaceColor',[0.97 0.98 0.99],'EdgeColor','none');
    end

    text(ax,colX(1),yy,critNames{k},'FontSize',9,'FontWeight','bold','VerticalAlignment','middle');
    text(ax,colX(2),yy,critDesc{k},'FontSize',8,'VerticalAlignment','middle');
    text(ax,colX(3),yy,sprintf('%d',passCounts(k)),'FontSize',9,'VerticalAlignment','middle');
    text(ax,colX(4),yy,sprintf('%d',failCounts(k)),'FontSize',9,'VerticalAlignment','middle');
    text(ax,colX(5),yy,sprintf('%.1f',passPct(k)),'FontSize',9,'VerticalAlignment','middle');
end

rectangle(ax,'Position',[0.645 0.355 0.310 0.500], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
barAx = axes('Parent',fig,'Position',[0.695 0.430 0.220 0.340]);
bar(barAx,failCounts,0.55);
set(barAx,'XTickLabel',critNames);
ylabel(barAx,'Failed Count');
title(barAx,'Failed Criteria');
grid(barAx,'on');
barAx.Color = 'white';
barAx.XColor = 'black';
barAx.YColor = 'black';

rectangle(ax,'Position',[0.645 0.120 0.310 0.190], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax,0.665,0.265,'Report Note', ...
    'FontSize',13,'FontWeight','bold','Color',[0.05 0.16 0.28]);
text(ax,0.665,0.225,'Detailed station-level H/V curves and SESAME', ...
    'FontSize',9,'Color',[0.20 0.20 0.20]);
text(ax,0.665,0.195,'evaluations are intentionally omitted from this PDF', ...
    'FontSize',9,'Color',[0.20 0.20 0.20]);
text(ax,0.665,0.165,'to reduce file size and export time.', ...
    'FontSize',9,'Color',[0.20 0.20 0.20]);
text(ax,0.665,0.135,'Use the interactive station list in the software for details.', ...
    'FontSize',9,'Color',[0.20 0.20 0.20]);

end

%% ========================================================================
function fig = makeDetailFigure(finalTable,i,allResults)
% Modern station detail page matching the V5 GUI design.
% V5.2: Latitude/Longitude are intentionally omitted from station detail pages.

fig = figure('Visible','off','Units','pixels','Position',[100 100 1500 850], ...
    'Color',[0.96 0.97 0.98],'InvertHardcopy','off');

stationName = char(finalTable.Name(i));

if finalTable.AllPass(i)
    statusStr = 'ACCEPTED';
    statusColor = [0.78 0.92 0.78];
    statusFg = [0.00 0.35 0.00];
elseif finalTable.Controlled(i)
    statusStr = 'CONTROLLED ACCEPTANCE';
    statusColor = [1.00 0.91 0.55];
    statusFg = [0.65 0.38 0.00];
else
    statusStr = 'REJECTED';
    statusColor = [0.95 0.72 0.72];
    statusFg = [0.60 0.00 0.00];
end

% Background axes for layout
ax0 = axes(fig,'Position',[0 0 1 1]);
axis(ax0,'off');
xlim(ax0,[0 1]);
ylim(ax0,[0 1]);

% Header
rectangle(ax0,'Position',[0.025 0.875 0.95 0.085], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax0,0.045,0.930,sprintf('Station Detail: %s',stationName), ...
    'FontSize',18,'FontWeight','bold','Color',[0.05 0.16 0.28], ...
    'VerticalAlignment','middle');

% Left info card
rectangle(ax0,'Position',[0.025 0.615 0.300 0.260], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax0,0.045,0.845,'Station Summary', ...
    'FontSize',13,'FontWeight','bold','Color',[0.05 0.16 0.28]);

rectangle(ax0,'Position',[0.045 0.790 0.260 0.038], ...
    'FaceColor',statusColor,'EdgeColor',[0.78 0.78 0.78], 'Curvature',[0.20 0.20]);
text(ax0,0.175,0.809,statusStr, ...
    'FontSize',10,'FontWeight','bold','Color',statusFg, ...
    'HorizontalAlignment','center','VerticalAlignment','middle');

details = { ...
    'f0 (Hz)', sprintf('%.4f', finalTable.f0(i)); ...
    'T0 (s)', sprintf('%.3f', finalTable.T0(i)); ...
    'A0', sprintf('%.3f', finalTable.A0(i)); ...
    'Reliability', yesno(finalTable.Reliable(i)); ...
    'Clear Peak', yesno(finalTable.Clear(i))};

y = 0.735;
for k = 1:size(details,1)
    text(ax0,0.055,y,sprintf('%s:',details{k,1}), ...
        'FontSize',9,'FontWeight','bold','Color',[0.20 0.25 0.30], ...
        'VerticalAlignment','middle');
    text(ax0,0.170,y,details{k,2}, ...
        'FontSize',9,'Color',[0.10 0.10 0.10], ...
        'VerticalAlignment','middle');
    y = y - 0.036;
end

% Progress card
rectangle(ax0,'Position',[0.025 0.430 0.300 0.155], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax0,0.045,0.555,'Evaluation Scores', ...
    'FontSize',13,'FontWeight','bold','Color',[0.05 0.16 0.28]);

critVals = [finalTable.V1(i) finalTable.V2(i) finalTable.V3(i) ...
            finalTable.V4(i) finalTable.V5(i) finalTable.V6(i) ...
            finalTable.V7(i) finalTable.V8(i) finalTable.V9(i)];

relScore = sum(critVals(1:3));
clearScore = sum(critVals(4:9));

text(ax0,0.045,0.515,sprintf('Reliability (V1-V3): %d / 3',relScore), ...
    'FontSize',9,'FontWeight','bold');
drawStaticProgress(ax0,0.045,0.491,0.238,0.018,relScore/3,[0.20 0.70 0.30]);

text(ax0,0.045,0.468,sprintf('Clear Peak (V4-V9): %d / 6',clearScore), ...
    'FontSize',9,'FontWeight','bold');
drawStaticProgress(ax0,0.045,0.444,0.238,0.018,clearScore/6,[0.95 0.70 0.05]);

% Criteria card
rectangle(ax0,'Position',[0.025 0.070 0.300 0.370], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);
text(ax0,0.045,0.410,'SESAME Criteria', ...
    'FontSize',13,'FontWeight','bold','Color',[0.05 0.16 0.28]);

critNames = {'V1','V2','V3','V4','V5','V6','V7','V8','V9'};
critDesc = {'f0 > 10/Iw','nc(f0) > 200','amplitude stability', ...
            'clear low','clear high','A0 > 2','peak +/-5%', ...
            'sigma_f < epsilon(f0)','sigma_A(f0) < theta(f0)'};

for k = 1:9
    yy = 0.372 - (k-1)*0.034;

    if critVals(k)
        pillColor = [0.78 0.92 0.78];
        pillFg = [0.00 0.35 0.00];
        status = 'TRUE';
    else
        pillColor = [0.95 0.72 0.72];
        pillFg = [0.55 0.00 0.00];
        status = 'FALSE';
    end

    text(ax0,0.055,yy,critNames{k},'FontSize',8.5,'FontWeight','bold', ...
        'VerticalAlignment','middle');
    text(ax0,0.090,yy,critDesc{k},'FontSize',8.5, ...
        'VerticalAlignment','middle');

    rectangle(ax0,'Position',[0.238 yy-0.011 0.062 0.023], ...
        'FaceColor',pillColor,'EdgeColor',[0.80 0.80 0.80], 'Curvature',[0.25 0.25]);
    text(ax0,0.269,yy,status,'FontSize',7.5,'FontWeight','bold', ...
        'Color',pillFg,'HorizontalAlignment','center','VerticalAlignment','middle');
end

% Plot card
rectangle(ax0,'Position',[0.350 0.070 0.625 0.805], ...
    'FaceColor','white','EdgeColor',[0.82 0.86 0.90]);

ax2 = axes('Parent',fig,'Position',[0.410 0.155 0.510 0.650]);
idxRes = find(strcmp({allResults.stationName},stationName),1);

if ~isempty(idxRes)
    plotHVwithCriteria(allResults(idxRes),ax2);
    title(ax2,sprintf('H/V Curve - %s',stationName));
else
    axis(ax2,'off');
    text(ax2,0.1,0.5,'Plot data not found.');
end

end

function drawModernCard(ax,x,y,w,h,titleStr,valueStr,bgColor,fgColor)

rectangle(ax,'Position',[x y w h], ...
    'FaceColor',bgColor, ...
    'EdgeColor',[0.78 0.82 0.86], ...
    'LineWidth',1.0, ...
    'Curvature',[0.08 0.08]);

% Centered card typography
text(ax,x+w/2,y+h*0.65,titleStr, ...
    'FontSize',10, ...
    'FontWeight','bold', ...
    'Color',fgColor, ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');

text(ax,x+w/2,y+h*0.28,valueStr, ...
    'FontSize',24, ...
    'FontWeight','bold', ...
    'Color',fgColor, ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');

end

%% ========================================================================
function drawStaticProgress(ax,x,y,w,h,frac,barColor)

frac = max(0,min(1,frac));

rectangle(ax,'Position',[x y w h], ...
    'FaceColor',[0.88 0.90 0.92], ...
    'EdgeColor',[0.72 0.75 0.78], ...
    'Curvature',[0.50 0.50]);

if frac > 0
    rectangle(ax,'Position',[x y w*frac h], ...
        'FaceColor',barColor, ...
        'EdgeColor','none', ...
        'Curvature',[0.50 0.50]);
end

% Keep percentage label inside the parent panel/card area.
text(ax,x+w+0.010,y+h/2,sprintf('%.0f%%',frac*100), ...
    'FontSize',8.5, ...
    'FontWeight','bold', ...
    'VerticalAlignment','middle', ...
    'HorizontalAlignment','left', ...
    'Color',[0.10 0.10 0.10]);

end

%% ========================================================================
function r = safeRatio(a,b)

if b == 0
    r = 0;
else
    r = a/b;
end

end

%% ========================================================================
function pageFile = printPage(fig,tempDir,pageNo)

pageFile = fullfile(tempDir,sprintf('page_%03d.pdf',pageNo));

set(fig,'InvertHardcopy','off');
set(fig,'PaperOrientation','landscape');
set(fig,'PaperUnits','normalized');
set(fig,'PaperPosition',[0 0 1 1]);

try
    print(fig,pageFile,'-dpdf','-bestfit');
catch
    print(fig,pageFile,'-dpdf');
end

end

function ok = mergePDFsWithGhostscript(pageFiles,outPdf)

ok = false;

gsCandidates = {'gswin64c','gswin32c','gs'};

gsCmd = '';
for i = 1:numel(gsCandidates)
    [status,~] = system([gsCandidates{i} ' --version']);
    if status == 0
        gsCmd = gsCandidates{i};
        break;
    end
end

if isempty(gsCmd)
    return;
end

if exist(outPdf,'file')
    delete(outPdf);
end

cmd = sprintf('"%s" -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile="%s"', ...
    gsCmd,outPdf);

for i = 1:numel(pageFiles)
    cmd = sprintf('%s "%s"',cmd,pageFiles{i});
end

status = system(cmd);

ok = (status == 0 && exist(outPdf,'file') == 2);

end

%% ========================================================================
function drawBox(ax,x,y,w,h,titleStr,valueStr,colorVal)

rectangle(ax,'Position',[x y w h], ...
    'FaceColor',colorVal, ...
    'EdgeColor',[0.65 0.65 0.65], ...
    'LineWidth',1.0);

text(ax,x+0.018,y+h*0.62,titleStr, ...
    'FontSize',10, ...
    'FontWeight','bold', ...
    'Color',[0.15 0.15 0.15]);

text(ax,x+0.018,y+h*0.18,valueStr, ...
    'FontSize',22, ...
    'FontWeight','bold', ...
    'Color',[0.05 0.16 0.28]);

end

function s = getStatusText(crit)

if crit.allPass
    s = 'ACCEPTED';
elseif crit.controlled
    s = 'CONTROLLED';
else
    s = 'REJECTED';
end

end

%% ========================================================================
function out = yesno(flag)

if flag
    out = 'TRUE';
else
    out = 'FALSE';
end

end

%% ========================================================================
function [lat, lon] = utm2deg_simple(x, y, utmZone)

a = 6378137.0;
f = 1/298.257223563;
b = a*(1-f);
e = sqrt(1 - (b/a)^2);
e1sq = e^2 / (1-e^2);
k0 = 0.9996;

zoneNumber = str2double(utmZone(1:end-1));
if isnan(zoneNumber)
    error('Invalid UTM zone format: %s',utmZone);
end

hemisphereChar = upper(utmZone(end));
isNorthern = hemisphereChar >= 'N';

x = x - 500000.0;

if ~isNorthern
    y = y - 10000000.0;
end

lon0 = (zoneNumber - 1)*6 - 180 + 3;

M = y / k0;
mu = M / (a*(1 - e^2/4 - 3*e^4/64 - 5*e^6/256));

e1 = (1 - sqrt(1 - e^2)) / (1 + sqrt(1 - e^2));

J1 = (3*e1/2 - 27*e1^3/32);
J2 = (21*e1^2/16 - 55*e1^4/32);
J3 = (151*e1^3/96);
J4 = (1097*e1^4/512);

fp = mu + J1*sin(2*mu) + J2*sin(4*mu) + J3*sin(6*mu) + J4*sin(8*mu);

C1 = e1sq * cos(fp).^2;
T1 = tan(fp).^2;
R1 = a*(1-e^2) ./ (1 - e^2*sin(fp).^2).^(3/2);
N1 = a ./ sqrt(1 - e^2*sin(fp).^2);
D  = x ./ (N1*k0);

Q1 = N1 .* tan(fp) ./ R1;
Q2 = (D.^2)/2;
Q3 = (5 + 3*T1 + 10*C1 - 4*C1.^2 - 9*e1sq) .* D.^4 / 24;
Q4 = (61 + 90*T1 + 298*C1 + 45*T1.^2 - 252*e1sq - 3*C1.^2) .* D.^6 / 720;

lat = fp - Q1 .* (Q2 - Q3 + Q4);

Q5 = D;
Q6 = (1 + 2*T1 + C1) .* D.^3 / 6;
Q7 = (5 - 2*C1 + 28*T1 - 3*C1.^2 + 8*e1sq + 24*T1.^2) .* D.^5 / 120;

lon = (deg2rad(lon0) + (Q5 - Q6 + Q7) ./ cos(fp));

lat = rad2deg(lat);
lon = rad2deg(lon);

end

%% ========================================================================
%% Embedded Geopsy parsers, SESAME evaluator and visualization functions
%% All seven modules below are copied intact from the validated modular source.
%% ========================================================================

%% --- hvsa_parse_hv.m (local function) ---------------------------
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

%% --- hvsa_parse_log.m (local function) --------------------------
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

%% --- hvsa_evaluate_sesame.m (local function) --------------------
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

v7Audit = hvsa_v7_peak_review(f,lo,hi,f0);
assert(v7Audit.originalGlobalPass == flags(7), ...
       'HVSA:V7AuditMismatch', ...
       'V7 diagnostic disagrees with baseline V7 calculation.');
result.peakDiagnostics = struct('low',peakLower,'high',peakUpper, ...
    'selection','Global maximum of each standard-deviation curve; first sample for ties', ...
    'multiplePeakInterpretationPerformed',false, ...
    'v7Audit',v7Audit, ...
    'manualReviewRecommended',v7Audit.manualReviewRecommended, ...
    'reviewReason',v7Audit.reviewReason);

end

%% --- hvsa_thresholds.m (local function) -------------------------
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

%% --- hvsa_global_peak.m (local function) ------------------------
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

%% --- hvsa_v7_peak_review.m (local function) ---------------------
function out = hvsa_v7_peak_review(freq,lowHV,highHV,f0)
% READ-ONLY SCIENTIFIC DIAGNOSTIC. 
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

%% --- hvsa_plot_spectrum.m (local function) ----------------------
function hvsa_plot_spectrum(ax,result)
%HVSA_PLOT_SPECTRUM Visual QA view with explicit peak/criterion annotations.
%   Independently written plotting layer for HV-SESAME Analyzer. Marker
%   shapes as well as colors differentiate the three project-level classes.

if ~isgraphics(ax,'axes')
    error('HVSA:InvalidAxes','A valid MATLAB axes handle is required.');
end
% A plain cla(ax) does not delete graphics whose HandleVisibility is 'off'.
% In this plot, criterion guide lines and station markers use hidden handles
% to keep the legend clean. Without allchild, these annotations persist when
% navigating between stations and incorrectly look like extra HVSR peaks.
% Delete *all* axes children while retaining axes placement/format settings.
delete(allchild(ax));
hold(ax,'off');
f = result.tab(:,1);
a = result.tab(:,2);
lo = result.tab(:,3);
hi = result.tab(:,4);
peak = result.f0;
amp = result.A0;
colors = struct('mean',[0.12 0.24 0.34],'bounds',[0.45 0.51 0.60], ...
                'guide',[0.41 0.53 0.71],'pass',[0.08 0.53 0.28], ...
                'warn',[0.80 0.49 0.05],'fail',[0.73 0.19 0.22]);

if result.criteria.allPass
    status = 'ACCEPTED'; color = colors.pass; symbol = '^';
elseif result.criteria.controlled
    status = 'CONTROLLED ACCEPTANCE'; color = colors.warn; symbol = 's';
else
    status = 'REJECTED'; color = colors.fail; symbol = 'd';
end

hold(ax,'on');
plot(ax,f,lo,'--','Color',colors.bounds,'LineWidth',0.9,'DisplayName','Mean - 1 SD');
plot(ax,f,hi,'--','Color',colors.bounds,'LineWidth',0.9,'DisplayName','Mean + 1 SD');
plot(ax,f,a,'-','Color',colors.mean,'LineWidth',1.8,'DisplayName','Mean H/V');

vline(ax,peak,'-',colors.fail,1.2);
vline(ax,0.95*peak,':',colors.guide,0.9);
vline(ax,1.05*peak,':',colors.guide,0.9);
vline(ax,peak/4,':',[0.18 0.48 0.38],0.8);
vline(ax,4*peak,':',[0.18 0.48 0.38],0.8);
plot(ax,[max(min(f),peak/4),min(max(f),4*peak)],[amp/2 amp/2],':', ...
     'Color',colors.fail,'LineWidth',1.1,'HandleVisibility','off');

idx = find(abs(f-peak)==min(abs(f-peak)),1,'first');
plot(ax,f(idx),a(idx),symbol,'Color',color, ...
    'MarkerFaceColor',color,'MarkerSize',9,'HandleVisibility','off');

set(ax,'XScale','log','Color','white','XColor',[0.12 0.18 0.25], ...
    'YColor',[0.12 0.18 0.25]);
xlim(ax,[min(f) max(f)]);
ylim(ax,[0,max(hi)*1.38]);
grid(ax,'on'); box(ax,'on');
xlabel(ax,'Frequency (Hz)'); ylabel(ax,'H/V amplitude');

names = arrayfun(@(k)sprintf('V%d',k),1:9,'UniformOutput',false);
pass = cellfun(@(name)result.criteria.(name),names);
for k = 1:9
    if pass(k)
        thisColor = colors.pass; mark = 'PASS';
    else
        thisColor = colors.fail; mark = 'FAIL';
    end
    text(ax,0.02,0.71-0.068*(k-1),sprintf('V%d: %s',k,mark), ...
        'Units','normalized','FontSize',13.5,'Color',thisColor, ...
        'FontWeight','bold','Interpreter','none');
end
text(ax,0.02,0.97,sprintf('%s  |  f0 = %.4f Hz',status,peak), ...
    'Units','normalized','VerticalAlignment','top', ...
    'Color',color,'FontWeight','bold','FontSize',16,'Interpreter','none');
text(ax,0.02,0.89,sprintf('Reliability: %s  |  Clear Peak: %s', ...
    verdict(result.criteria.reliable),verdict(result.criteria.clear)), ...
    'Units','normalized','Color',[0.14 0.18 0.23], ...
    'FontWeight','bold','FontSize',13.5,'Interpreter','none');

hold(ax,'off');
end

function vline(ax,x,style,color,width)
if x>0
    plot(ax,[x x],ylimSafe(ax),style,'Color',color, ...
        'LineWidth',width,'HandleVisibility','off');
end
end

function vals = ylimSafe(ax)
vals = ylim(ax);
if ~isfinite(vals(1)) || ~isfinite(vals(2)) || vals(1)==vals(2)
    vals = [0 1];
end
end

function str = verdict(flag)
if flag
    str = 'PASS';
else
    str = 'FAIL';
end
end
