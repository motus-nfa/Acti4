function varargout = OutlierParSelection(varargin)

% Opens the OutlierParSelection menu for checking of outliers in output from a Batch run
%
% Parameters (from 1 of 3 groups) and types of interval are selected from the menu. 
% Output is a 1x4 cell array in which the first 3 element contains the
% selected parameters and the last one the interval types.

% OUTLIERPARSELECTION MATLAB code for OutlierParSelection.fig
%      OUTLIERPARSELECTION, by itself, creates a new OUTLIERPARSELECTION or raises the existing
%      singleton*.
%
%      H = OUTLIERPARSELECTION returns the handle to a new OUTLIERPARSELECTION or the handle to
%      the existing singleton*.
%
%      OUTLIERPARSELECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OUTLIERPARSELECTION.M with the given input arguments.
%
%      OUTLIERPARSELECTION('Property','Value',...) creates a new OUTLIERPARSELECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OutlierParSelection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OutlierParSelection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OutlierParSelection

% Last Modified by GUIDE v2.5 10-Apr-2019 09:31:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OutlierParSelection_OpeningFcn, ...
                   'gui_OutputFcn',  @OutlierParSelection_OutputFcn, ...
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



% --- Executes just before OutlierParSelection is made visible.
function OutlierParSelection_OpeningFcn(hObject, eventdata, h, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OutlierParSelection (see VARARGIN)

% Choose default command line output for OutlierParSelection
h.output = hObject;

set(h.r1,'Value',1)
set(h.r2,'Value',1)
set(h.r3,'Value',1)
set(h.r4,'Value',1)
set(h.ParGrp1,'String',varargin{1}{1})
set(h.ParGrp2,'String',varargin{1}{2},'Enable','off')
set(h.ParGrp3,'String',varargin{1}{3},'Enable','off')

uicontrol(h.ParGrp1) %focusproblem: kan ikke få ændret blå-markeringer til grå når der vælges en anden gruppe
uicontrol(h.ParGrp1)

% Update handles structure
guidata(hObject, h);

% UIWAIT makes OutlierParSelection wait for user response (see UIRESUME)
 uiwait(h.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = OutlierParSelection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function ParGrp1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParGrp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function ParGrp2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParGrp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function ParGrp3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ParGrp3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function Grp1_Callback(hObject, eventdata, h)
set(gcbo,'value',1)
set(h.ParGrp1,'Enable','on')
set(h.ParGrp2,'Enable','off')
set(h.ParGrp3,'Enable','off')

function Grp2_Callback(hObject, eventdata, h)
set(gcbo,'value',1)
set(h.ParGrp1,'Enable','off')
set(h.ParGrp2,'Enable','on')
set(h.ParGrp3,'Enable','off')

function Grp3_Callback(hObject, eventdata, h)
set(gcbo,'value',1)
set(h.ParGrp1,'Enable','off')
set(h.ParGrp2,'Enable','off')
set(h.ParGrp3,'Enable','on')

% --- Executes on button press in Cancelbutton.
function Cancelbutton_Callback(hObject, eventdata, h)
% hObject    handle to Cancelbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h.output = {};
guidata(hObject, h);
uiresume(h.figure1);

function Okbutton_Callback(hObject, eventdata, h)
%Output er cell array {1:4} hvor de første 3 positioner indeholder parametervalget og
%sidste position indeholder intervalvalget. 
if strcmp('on',get(h.ParGrp1,'Enable'))
   Out{1} = get(h.ParGrp1,'Value');
end
if strcmp('on',get(h.ParGrp2,'Enable'))
   Out{2} = get(h.ParGrp2,'Value');
end
if strcmp('on',get(h.ParGrp3,'Enable'))
   Out{3} = get(h.ParGrp3,'Value');
end
for i=1:11
  Int(i) = get(findobj('Tag',['r',num2str(i)]),'Value');
end
Out{4} = Int;
h.output = Out;
guidata(hObject, h);
uiresume(h.figure1);
