function varargout = AnalysisSetup(varargin)

% Selecting/editing of parameters for the analysis methods, called from the main Acti4 menu.
%
% Several parameters that determine the analyses can be edited and saved for later use.
% The set of analysis parameters is saved in a sheet of the file ParameterList.xlsx; the sheet name identifies the parameter settings,
% a Default sheet/settings is always present.
% The actual SETTINGS are stored by setappdata at ACT4.
% 6/12-17: Selection of EVA analysis added
% 6/6-19: HRV analysis added
% 20/11-19: Use calibrations removed (new calibration procedure)
% 27/1-20: Checking of accelerometer orientation etc. during Batch run
% 28/4-20: Calf accelerometer for kneel detection

% ANALYSISSETUP MATLAB code for AnalysisSetup.fig
%      ANALYSISSETUP, by itself, creates a new ANALYSISSETUP or raises the existing
%      singleton*.
%
%      H = ANALYSISSETUP returns the handle to a new ANALYSISSETUP or the handle to
%      the existing singleton*.
%
%      ANALYSISSETUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANALYSISSETUP.M with the given input arguments.
%
%      ANALYSISSETUP('Property','Value',...) creates a new ANALYSISSETUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AnalysisSetup_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AnalysisSetup_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AnalysisSetup

% Last Modified by GUIDE v2.5 14-May-2020 07:37:01

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AnalysisSetup_OpeningFcn, ...
                   'gui_OutputFcn',  @AnalysisSetup_OutputFcn, ...
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

% --- Executes just before AnalysisSetup is made visible.
function AnalysisSetup_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AnalysisSetup (see VARARGIN)
[~,Sheets] = xlsfinfo(fullfile(fileparts(which('Acti4')),'ParameterList.xlsx')); %Available stored settings
Stored = setdiff(Sheets,{'Info','List','Default'});
Stored = cat(2,'Default',Stored); %list always 'Default' first
set(handles.StoredSettings,'String',Stored)
SETTINGS = getappdata(findobj('Tag','Acti4'),'SETTINGS');
set(handles.StoredSettings,'Value',find(strcmp(SETTINGS.Name,Stored)))
setappdata(hObject,'ParameterListFile',fullfile(fileparts(which('Acti4')),'ParameterList.xlsx'))
StoredSettings_Callback(handles.StoredSettings,[],handles) %Put in the actual values
setappdata(hObject,'Changed',0);
setappdata(hObject,'Saved',0);

% Choose default command line output for AnalysisSetup
%handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes AnalysisSetup wait for user response (see UIRESUME)
 uiwait(handles.AnalysisSetup);

% --- Outputs from this function are returned to the command line.
function varargout = AnalysisSetup_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
%varargout{1} = handles.output;

% --- Executes on button press in SaveAnalysisSetup.
function SaveAnalysisSetup_Callback(~,~,handles)
%Save analysis setup in 'ParameterList.xlsx' (check for existing names)
Stored = get(handles.StoredSettings,'String');
Stored = Stored(1:end-1); %A blank line (item) was added when an Edit was changed
Again = 1;
while Again
  NewName = SelectNavn;
  if isempty(NewName), return, end %Cancel
  if any(strcmp(Stored,NewName))
     Ans = questdlg([NewName,' already exists - overwrite?'],'','Yes','No','No');
     if strcmp('No',Ans), Again = 1; else Again = 0; end
  else
     Again = 0;
  end
end
Edits = findobj(handles.AnalysisSetup,'Style','edit');
[~,I] = sort(get(Edits,'Tag'));
Edits = Edits(I);
Data = cell(length(Edits),2);
for i=1:length(Edits)
   D1 = get(Edits(i),'Tag');
   D2 = get(Edits(i),'String');
   if ~strncmp(D1,'Period',6), D2 = str2double(D2); end
   if  strncmp(D1,'Period',6) && isempty(D2), D2 = char(39); end %apostrof
   Data(i,1:2) = {get(Edits(i),'Tag'),D2}; 
end
Data(i+1,1:2) = {'SeparatePeriods',get(handles.SeparatePeriods,'Value')}; %SeparatePeriods added
Data(i+2,1:2) = {'IncludeAH',get(handles.IncludeAH,'Value')}; %IncludeAH added
Data(i+3,1:2) = {'ActivityExportTxt',get(handles.ActivityExportTxt,'Value')}; %Export activity data as text file
Data(i+4,1:2) = {'ActivityExportMat',get(handles.ActivityExportMat,'Value')}; %Export activity data as m-file
Data(i+5,1:2) = {'EVAanalysis',get(handles.EVAanalysis,'Value')}; %EVA analysis added (6/12-17)
Data(i+6,1:2) = {'HRVanalysis',get(handles.HRVanalysis,'Value')}; %HRV analysis added (6/6-19)
Data(i+7,1:2) = {'CheckBatch',get(handles.CheckBatch,'Value')}; %CheckBatch added (27/1-20)
Data(i+8,1:2) = {'Calf',get(handles.Calf,'Value')}; %Calf accelerometer for kneel detection added (28/4-20)

if all(~strcmp(Stored,NewName)), Stored = cat(1,Stored,NewName); end %add, if it is a new name
set(handles.StoredSettings,'String',Stored,'Value',find(strcmp(Stored,NewName)))
Fil = getappdata(handles.AnalysisSetup,'ParameterListFile');
warning('Off','MATLAB:xlswrite:AddSheet')
xlswrite(Fil,Data,NewName)
warning('On','MATLAB:xlswrite:AddSheet')
setappdata(handles.AnalysisSetup,'Saved',1);

function Navn = SelectNavn
%Select the name and check for the illegal names 'Info' and 'List'
Again = 1;
while Again
  Navn = cell2mat(inputdlg('Select name for saving the analysis setup'));
  if isempty(Navn), return, end %Cancel
  if any(strcmpi(Navn,{'Info','List'})) %not to be used
     uiwait(msgbox('Illegal name','modal'))
     Again = 1;
  else
     Again = 0;
  end
end

% --- Executes on selection change in StoredSettings.
function StoredSettings_Callback(hObject, ~, handles)
%Reads the stored settings and display values
Fil = getappdata(handles.AnalysisSetup,'ParameterListFile');
Navne = get(hObject,'String');
[~,~,Raw] = xlsread(Fil,Navne{get(hObject,'Value')});
for i=1:size(Raw,1)
    Obj = findobj(handles.AnalysisSetup,'Tag',Raw{i});
    if strcmp('edit',get(Obj,'Style'))
       if isnumeric(Raw{i,2}), Val = num2str(Raw{i,2});
       else Val = Raw{i,2}; end
       set(Obj,'String',Val)
    end
    if strcmp('radiobutton',get(Obj,'Style'))
       set(Obj,'Value',Raw{i,2})
    end
end

function Bout_row_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_stair_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_cycle_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_run_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_walk_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_move_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_stand_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_sit_Callback(~, ~, handles)
ChangesMade2(handles)

function Bout_lie_Callback(~, ~, handles)
ChangesMade2(handles)

function Threshold_standmove_Callback(~, ~, handles)
ChangesMade1(handles)

function Threshold_walkrun_Callback(~, ~, handles)
ChangesMade1(handles)

function Threshold_sitstand_Callback(~, ~, handles)
ChangesMade1(handles)

function Threshold_staircycle_Callback(~, ~, handles)
ChangesMade1(handles)

function Threshold_slowfastwalk_Callback(~, ~, handles) %3/6-19
ChangesMade1(handles)

function Threshold_kneel_Callback(hObject, eventdata, handles) %14/5-20
ChangesMade1(handles)

function Period_A1_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_A2_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_A3_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_A4_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_B1_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_B2_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_B3_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_B4_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_C0_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_C4_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function Period_D_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function SeparatePeriods_Callback(hObject, eventdata, handles)
%1 for separating periods in days
ChangesMade1(handles)

function IncludeAH_Callback(hObject, eventdata, handles)
%1 for including Actiheart data
ChangesMade1(handles)

function EVAanalysis_Callback(hObject, eventdata, handles) %6/12-17
%1 for including EVA
ChangesMade1(handles)

function HRVanalysis_Callback(hObject, eventdata, handles)
%1 for including HRV analysis
set(handles.IncludeAH,'Value',1)
ChangesMade1(handles)

function CheckBatch_Callback(hObject, eventdata, handles)
%1 for checking for accelerometer orientation etc. during batch run
ChangesMade1(handles)

function Calf_Callback(hObject, eventdata, handles)
%1 for including analysis of calf accelerometer
ChangesMade1(handles)

% Hint: get(hObject,'Value') returns toggle state of Calf
function ActivityExportMat_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function ActivityExportTxt_Callback(hObject, eventdata, handles)
ChangesMade1(handles)

function ChangesMade1(handles)
setappdata(handles.AnalysisSetup,'Changed',1);
setappdata(handles.AnalysisSetup,'Saved',0);
Stored = get(handles.StoredSettings,'String'); %A blank item added (if not already present)
if ~strcmp(' ',Stored(end))  %to show it is a new item that should be saved
   set(handles.StoredSettings,'String',cat(1,Stored,' '),'Value',size(Stored,1)+1)
end

function ChangesMade2(handles)
Input = num2str(max(round(str2double(get(gcbo,'String'))),2));%minimum 2 and no decimals accepted
set(gcbo,'String',Input) 
setappdata(handles.AnalysisSetup,'Changed',1);
setappdata(handles.AnalysisSetup,'Saved',0);
Stored = get(handles.StoredSettings,'String'); %A blank item added (if not already present)
if ~strcmp(' ',Stored(end))  %to show it is a new item that should be saved
   set(handles.StoredSettings,'String',cat(1,Stored,' '),'Value',size(Stored,1)+1)
end

% --- Executes on button press in Close.
function Close_Callback(hObject, eventdata, handles)
Changed = getappdata(handles.AnalysisSetup,'Changed');
Saved = getappdata(handles.AnalysisSetup,'Saved');
if Saved==0 && Changed==1
   Ans = questdlg('Close without saving new setting?','','Yes','No','No');
   if strcmp(Ans,'No'), return, end
   if strcmp(Ans,'Yes'), close(handles.AnalysisSetup), return, end
end 
Navne = get(handles.StoredSettings,'String');
SETTINGS.Name = Navne{get(handles.StoredSettings,'Value')};
Edits = findobj(handles.AnalysisSetup,'Style','edit');
for i=1:length(Edits)
   Var = get(Edits(i),'Tag'); 
   Val = get(Edits(i),'String');
   if ~strncmp(Var,'Period',6), Val = str2double(Val); end
   SETTINGS.(Var) = Val;
end
SETTINGS.SeparatePeriods = get(handles.SeparatePeriods,'Value');
SETTINGS.IncludeAH = get(handles.IncludeAH,'Value');
SETTINGS.ActivityExportTxt = get(handles.ActivityExportTxt,'Value');
SETTINGS.ActivityExportMat = get(handles.ActivityExportMat,'Value');
SETTINGS.EVAanalysis = get(handles.EVAanalysis,'Value'); %EVA analysis added (6/12-17)
SETTINGS.HRVanalysis = get(handles.HRVanalysis,'Value'); %HRV analysis added (6/6-19)
SETTINGS.CheckBatch = get(handles.CheckBatch,'Value'); %Checking accelerometer orientation etc. during Batch run, added (29/1-20)
SETTINGS.Calf = get(handles.Calf,'Value'); %Kneel detection

setappdata(findobj('Tag','Acti4'),'SETTINGS',SETTINGS)
save(fullfile(fileparts(which('Acti4')),'StartFile'),'SETTINGS') %to be able to start with the last used setting
close(handles.AnalysisSetup)

%........................................................................................
% --- Executes during object creation, after setting all properties.
function StoredSettings_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Bout_row_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Bout_stair_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Bout_run_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Bout_sit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Bout_lie_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Bout_walk_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Bout_move_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Bout_stand_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Bout_cycle_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Threshold_standmove_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Threshold_walkrun_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Threshold_sitstand_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Threshold_staircycle_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Threshold_slowfastwalk_CreateFcn(hObject, eventdata, handles) %3/6-19
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Threshold_kneel_CreateFcn(hObject, eventdata, handles) %14/5-20
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Period_D_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_C4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_C0_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_B4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_B3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_B2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_B1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_A4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_A3_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_A2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function Period_A1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





