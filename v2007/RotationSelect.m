function varargout = RotationSelect(varargin)

% For specifying an axis rotation for act4-accelerometer files.
% Called by RotateAxes.m 

%
% ROTATIONSELECT MATLAB code for RotationSelect.fig
%      ROTATIONSELECT, by itself, creates a new ROTATIONSELECT or raises the existing
%      singleton*.
%
%      H = ROTATIONSELECT returns the handle to a new ROTATIONSELECT or the handle to
%      the existing singleton*.
%
%      ROTATIONSELECT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROTATIONSELECT.M with the given input arguments.
%
%      ROTATIONSELECT('Property','Value',...) creates a new ROTATIONSELECT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RotationSelect_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RotationSelect_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RotationSelect

% Last Modified by GUIDE v2.5 17-Jun-2020 10:23:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RotationSelect_OpeningFcn, ...
                   'gui_OutputFcn',  @RotationSelect_OutputFcn, ...
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


% --- Executes just before RotationSelect is made visible.
function RotationSelect_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RotationSelect (see VARARGIN)

% Choose default command line output for RotationSelect
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RotationSelect wait for user response (see UIRESUME)
 uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = RotationSelect_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
close(handles.figure1)

% --- Executes on button press in OK.
function OK_Callback(hObject, eventdata, handles)
X = get(handles.X,'Value');
Y = get(handles.Y,'Value');
Z = get(handles.Z,'Value');
handles.output = [X,Y,Z];
guidata(hObject, handles);
uiresume(handles.figure1);
% hObject    handle to OK (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
handles.output = {};
guidata(hObject, handles);
uiresume(handles.figure1);
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in X.
function X_Callback(hObject, eventdata, handles)
% hObject    handle to X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns X contents as cell array
%        contents{get(hObject,'Value')} returns selected item from X


% --- Executes during object creation, after setting all properties.
function X_CreateFcn(hObject, eventdata, handles)
% hObject    handle to X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Y.
function Y_Callback(hObject, eventdata, handles)
% hObject    handle to Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Y contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Y


% --- Executes during object creation, after setting all properties.
function Y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in Z.
function Z_Callback(hObject, eventdata, handles)
% hObject    handle to Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Z contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Z


% --- Executes during object creation, after setting all properties.
function Z_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Z (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
