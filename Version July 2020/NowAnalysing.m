function varargout = NowAnalysing(varargin)
% NOWANALYSING MATLAB code for NowAnalysing.fig
% Set up the menu NowAnalysing used during Batch to display the actual interval for processing.

% If 'Pause' is selected BatchAnalysis menu, the 'Next' button selects the next interval to analyse.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NowAnalysing_OpeningFcn, ...
                   'gui_OutputFcn',  @NowAnalysing_OutputFcn, ...
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

% --- Executes just before NowAnalysing is made visible.
function NowAnalysing_OpeningFcn(hObject, eventdata, handles, varargin)
  handles.output = hObject;
  S = varargin{1};
  set(handles.SetupFile,'String',S.SetupFileName);
  set(handles.Previous,'Visible','Off')
  set(handles.Next,'Visible','Off')
  set(handles.NextID,'Visible','Off')
  uicontrol(handles.Next)
  guidata(hObject, handles);
% uiwait(handles.NowAnalysing);

% --- Outputs from this function are returned to the command line.
function varargout = NowAnalysing_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function Stop_Callback(hObject, eventdata, handles)
  uiresume  
  set(handles.Next,'Enable','Off')
  set(handles.Previous,'Enable','Off')
  set(handles.Stop,'Enable','Off')
    
function NowAnalysing_CloseRequestFcn(hObject, eventdata, handles)
% Hint: delete(hObject) closes the figure
delete(hObject);

function Next_Callback(hObject, eventdata, handles)
uiresume
set(handles.Next,'Enable','Off')
set(handles.Previous,'Enable','Off')
set(handles.Stop,'Enable','Off')
uicontrol(handles.Next)

function NextID_Callback(hObject, eventdata, handles)
uiresume
set(handles.Next,'Enable','Off')
set(handles.Previous,'Enable','Off')
set(handles.Stop,'Enable','Off')
uicontrol(handles.Next)

% --- Executes on button press in Previous.
function Previous_Callback(hObject, eventdata, handles)
uiresume
set(handles.Next,'Enable','Off')
set(handles.Previous,'Enable','Off')
set(handles.Stop,'Enable','Off')
uicontrol(handles.Next)

function Interval_Callback(hObject, eventdata, handles)
uiresume
set(handles.Next,'Enable','Off')
set(handles.Previous,'Enable','Off')
set(handles.Stop,'Enable','Off')
uicontrol(handles.Next)

function Interval_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SetupFile_Callback(hObject, eventdata, handles)

function SetupFile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ID_Callback(hObject, eventdata, handles)

function ID_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Activity_Callback(hObject, eventdata, handles)

function Activity_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function FileNoNow_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function FileNoNow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileNoNow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
%if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%    set(hObject,'BackgroundColor','white');
%end



function FileNoTotal_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function FileNoTotal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileNoTotal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
