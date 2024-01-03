function Acti4(varargin)

% Main function of program to analyse activities, arm and trunk inclination. 
% Recordings by Acigraph, Axivity, ActivPal ans Sens accelerometers at the thigh, hip,
% arm and trunk and heartrate recordings by Actiheart and BodyGuard2 are
% supported.
%
% Acti4 opens Acti4.fig showing the main menu for selection of  
%
%         File information
%         Single file viewing
%         Interval setup
%         Batch analysis
%         Inclinometer data viewing
%         Raw data viewing
%         Convert ActiGraph CSV-files
%         Convert Axivity CWA-files
%         Convert Sens bin-files
%         Convert ActivPAL-files
%         Convert ActiHeart IBI-files
%         Convert Firstbeat files
%         Calibrate act4-files
%         Synchronize act4-files
%         Outlier check
%         Aggregate result
%         Rotate axes
%         Analysis setup

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Acti4_OpeningFcn, ...
                   'gui_OutputFcn',  @Acti4_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Acti4 is made visible.
function Acti4_OpeningFcn(hObject, ~, handles)
set(gcf,'Name','ACTI4 (2007)') %Version: year, month
% Read default parameters for the analyses methods:
PathActi4 = fileparts(which('Acti4'));
[~,Sheets] = xlsfinfo(fullfile(fileparts(which('Acti4')),'ParameterList.xlsx'));
if ~isempty(dir(fullfile(PathActi4,'StartFile.mat')))
   load(fullfile(PathActi4,'StartFile.mat'),'SETTINGS')
   if ~any(strcmp(SETTINGS.Name,Sheets)) %if the last used setting have been removed from the Excel file, load Default
      [~,~,R] = xlsread(fullfile(fileparts(which('Acti4')),'ParameterList.xlsx'),'Default');
      SETTINGS = cell2struct(cat(1,'Default',R(:,2)),cat(1,'Name',R(:,1))); 
   end
else
   [~,~,R] = xlsread(fullfile(fileparts(which('Acti4')),'ParameterList.xlsx'),'Default');
   SETTINGS = cell2struct(cat(1,'Default',R(:,2)),cat(1,'Name',R(:,1)));
end
setappdata(hObject,'SETTINGS',SETTINGS)
uicontrol(handles.batch) % to give focus to the Batch button, for some unknown reason 
uicontrol(handles.batch) % the command must be repeated to work
uiwait(handles.Acti4);

% --- Outputs from this function are returned to the command line.
function varargout = Acti4_OutputFcn(hObject, eventdata, handles) 

% --- Executes on button press in batch.
function batch_Callback(hObject, eventdata, handles)
close(findobj('Tag','NowAnalysing'))
close(findobj('Tag','ActiFig'))
ActiG('Batch')

% --- Executes on button press in single.
function single_Callback(hObject, eventdata, handles)
close(findobj('Tag','NowAnalysing'))
close(findobj('Tag','ActiFig'))
ActiG('Single')

% --- Executes on button press in inclinometer.
function inclinometer_Callback(hObject, eventdata, handles)
close(findobj('Tag','NowAnalysing'))
close(findobj('Tag','ActiFig'))
ActiG('Inclinometer')

% --- Executes on button press in raw.
function raw_Callback(hObject, eventdata, handles)
close(findobj('Tag','NowAnalysing'))
close(findobj('Tag','ActiFig'))
ActiG('Raw')

% --- Executes on button press in info.
function info_Callback(hObject, eventdata, handles)
close(findobj('Tag','NowAnalysing'))
close(findobj('Tag','ActiFig'))
ActiG('Info')

% --- Executes on button press in IntervalSetup.
function IntervalSetup_Callback(hObject, eventdata, handles)
ActiG('IntervalSetup')

% --- Executes on button press in ConvertAH.
function ConvertAH_Callback(hObject, eventdata, handles)
AHtxt2mat

% --- Executes on button press in ConvertAG.
function ConvertAG_Callback(hObject, eventdata, handles)
Csv2Acti4

% --- Executes on button press in AnalysisSetup.
function AnalysisSetup_Callback(hObject, eventdata, handles)
AnalysisSetup

% --- Executes on button press in exit.
function exit_Callback(hObject, eventdata, handles)
fclose('all');
uiresume(handles.Acti4)
close(handles.Acti4)

% --- Executes on button press in ActivPAL2Acti4.
function ActivPAL2Acti4_Callback(hObject, eventdata, handles)
ActivPAL2Acti4

% --- Executes on button press in ConvertAX3.
function ConvertAX3_Callback(hObject, eventdata, handles)
Cwa2Acti4

% --- Executes on button press in ConvertSens.
function ConvertSens_Callback(hObject, eventdata, handles)
Sens2Acti4

% --- Executes on button press in AutoCalibration_Act4file.
function AutoCalibration_Act4file_Callback(hObject, eventdata, handles)
AutoCalibration;

% --- Executes on button press in ConvertFirstbeat.
function ConvertFirstbeat_Callback(hObject, eventdata, handles)
BodyguardSdf2mat


% --- Executes on button press in DataCheck.
function DataCheck_Callback(hObject, eventdata, handles)
DataCheck

% --- Executes on button press in Aggregate.
function Aggregate_Callback(hObject, eventdata, handles)
Interval2DayResult


% --- Executes on button press in Synchronize_Act4Files.
function Synchronize_Act4Files_Callback(hObject, eventdata, handles)
AutoSynchronization


% --- Executes on button press in RotateAxes.
function RotateAxes_Callback(hObject, eventdata, handles)
RotateAxes
