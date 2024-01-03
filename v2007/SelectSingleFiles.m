function varargout = SelectSingleFiles(varargin)
% SELECTSINGLEFILES MATLAB code for SelectSingleFiles.fig
%
% Opens the menu SelectSingleFiles for selecting individual files or automatic selection
% of a group of files belonging to the same measurement as one selected file.
%
% Output is a struct with the full file names of the files for thigh, hip, arm, trunk and AH
% (or a subset of these).

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SelectSingleFiles_OpeningFcn, ...
                   'gui_OutputFcn',  @SelectSingleFiles_OutputFcn, ...
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

% --- Executes just before SelectSingleFiles is made visible.
function SelectSingleFiles_OpeningFcn(hObject, ~, handles, varargin)
if ~isempty(strcmp('AH',varargin))
   set(handles.AHdirSelect,'Visible','on')
   set(handles.AHdir,'Visible','on')
end
handles.output = hObject;
handles.AHfile = '';
uicontrol(handles.autofind)
uicontrol(handles.autofind)
guidata(hObject, handles);
uiwait(handles.SelectSingleFiles);

% --- Outputs from this function are returned to the command line.
function varargout = SelectSingleFiles_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;

% --- Executes on button press in SelectThigh.
function SelectThigh_Callback(~, ~, handles)
[ThighFile,ThighMap] = uigetfile('*.gt3x;*.act4','Select Thigh file');
if ischar(ThighFile)
   cd(ThighMap);
   File = fullfile(ThighMap,ThighFile);
   set(handles.ThighFile,'String',File);
   uicontrol(handles.SelectHip)
end

% --- Executes on button press in SelectHip.
function SelectHip_Callback(~, ~, handles)
[HipFile,HipMap] = uigetfile('*.gt3x;*.act4','Select Hip file)');
if ischar(HipFile)
   cd(HipMap);
   File = fullfile(HipMap,HipFile);
   set(handles.HipFile,'String',File);
   uicontrol(handles.SelectArm)
end

% --- Executes on button press in SelectArm.
function SelectArm_Callback(~, ~, handles)
[ArmFile,ArmMap] = uigetfile('*.gt3x;*.act4','Select Arm file');
if ischar(ArmFile) 
   cd(ArmMap);
   File = fullfile(ArmMap,ArmFile);
   set(handles.ArmFile,'String',File);
   uicontrol(handles.SelectTrunk)
end
 
 % --- Executes on button press in SelectTrunk.
function SelectTrunk_Callback(~, ~, handles)
[TrunkFile,TrunkMap] = uigetfile('*.gt3x;*.act4','Select Trunk file');
if ischar(TrunkFile)
   cd(TrunkMap);
   File = fullfile(TrunkMap,TrunkFile);
   set(handles.TrunkFile,'String',File);
   uicontrol(handles.Ok)
end

% --- Executes on button press in Ok.
function Ok_Callback(hObject, ~, handles)
% Gets the full file names and put them into a struct as output parameter
% to be returned by SelectSingleFiles
S = struct(...
'FilThigh',get(handles.ThighFile,'String'),...
'FilHip',get(handles.HipFile,'String'),...
'FilArm',get(handles.ArmFile,'String'),...
'FilTrunk',get(handles.TrunkFile,'String'),...
'AHfile',handles.AHfile);
handles.output = S;
set(hObject,'Enable','Inactive')
set(handles.Cancel,'Enable','Inactive')
guidata(hObject, handles);
uiresume(gcf)

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, ~, handles)
handles.output = struct([]);
guidata(hObject, handles);
uiresume(gcf)

function autofind_Callback(hObject, ~, handles)
  %Finds the other AG files that belongs to one selected.   
  [Filnavn,Mappe] = uigetfile('*.gt3x;*.act4','Select an Actigraph data file');
  [~,~,Ext] = fileparts(Filnavn);
  handles.ID = Filnavn(1:5);
  S = dir([Mappe,handles.ID,'*',Ext]);
  [~,~,~,Name] = File2BodyPos({S.name}); %looks for file names that associates to thigh, hip, arm and trunk
  cd(Mappe);
  if ~isempty(Name.Thigh), set(handles.ThighFile,'String',[Mappe,Name.Thigh]); end
  if ~isempty(Name.Hip), set(handles.HipFile,'String',[Mappe,Name.Hip]); end
  if ~isempty(Name.Arm), set(handles.ArmFile,'String',[Mappe,Name.Arm]); end
  if ~isempty(Name.Trunk), set(handles.TrunkFile,'String',[Mappe,Name.Trunk]); end
handles.Mappe = Mappe;
guidata(hObject, handles);

function AHdirSelect_Callback(hObject, ~, handles)
  %To select a directory in which AH files should be found
persistent AHdir
if isfield(handles,'Mappe') %11/5-19: for at kunne vælge en AH file alene
  if (isempty(AHdir)||isnumeric(AHdir)), AHmappe = handles.Mappe; else AHmappe = AHdir; end
     AHdir = uigetdir(AHmappe,'Select ActiHeart directory');
    if ischar(AHdir) %is numeric if cancel was selected
      AHfile = fullfile(AHdir,[handles.ID,'.mat']);
      Bib = dir(AHfile);
      if isempty(Bib)
         msgbox({['No ActiHeart datafile (.mat) found for ID ',handles.ID,' in directory: '];AHdir})
      else
         set(handles.AHdir,'String',AHdir)
         handles.AHfile = AHfile;
         guidata(hObject, handles);
      end
    end
else %11/5-19: for at kunne vælge en AH file alene
    [AHfile,AHdir] = uigetfile('*.mat','Select haeart rate file');
    set(handles.AHdir,'String',fullfile(AHdir,AHfile))
    handles.AHfile = fullfile(AHdir,AHfile);
    guidata(hObject, handles);
end

function AHdir_Callback(hObject, eventdata, handles)

function AHdir_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function ThighFile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function HipFile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function ArmFile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function TrunkFile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
