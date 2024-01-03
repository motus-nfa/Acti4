function varargout = Calibrate_ChangeAxesOrientation(varargin)
% Displays menu for optional calibration and change of accelerometer axis orientation (in/out, up/down or both)
%
% Displays the figure Calibrate_ChangeAxesOrientation.fig, for user selection of 
% calibration and change of axis orientation if it differs from Acti4 standard: 
% Manufacturer serial number inward abd X-axis downward.

% CALIBRATE_CHANGEAXESORIENTATION MATLAB code for Calibrate_ChangeAxesOrientation.fig
%      CALIBRATE_CHANGEAXESORIENTATION, by itself, creates a new CALIBRATE_CHANGEAXESORIENTATION or raises the existing
%      singleton*.
%
%      H = CALIBRATE_CHANGEAXESORIENTATION returns the handle to a new CALIBRATE_CHANGEAXESORIENTATION or the handle to
%      the existing singleton*.
%
%      CALIBRATE_CHANGEAXESORIENTATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CALIBRATE_CHANGEAXESORIENTATION.M with the given input arguments.
%
%      CALIBRATE_CHANGEAXESORIENTATION('Property','Value',...) creates a new CALIBRATE_CHANGEAXESORIENTATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Calibrate_ChangeAxesOrientation_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Calibrate_ChangeAxesOrientation_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Calibrate_ChangeAxesOrientation

% Last Modified by GUIDE v2.5 18-Nov-2019 11:04:42

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Calibrate_ChangeAxesOrientation_OpeningFcn, ...
                   'gui_OutputFcn',  @Calibrate_ChangeAxesOrientation_OutputFcn, ...
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


% --- Executes just before Calibrate_ChangeAxesOrientation is made visible.
function Calibrate_ChangeAxesOrientation_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for Calibrate_ChangeAxesOrientation
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Calibrate_ChangeAxesOrientation wait for user response (see UIRESUME)
 uiwait(handles.ChangeAxesOrientation);


% --- Outputs from this function are returned to the command line.
function varargout = Calibrate_ChangeAxesOrientation_OutputFcn(hObject, eventdata, handles) 
varargout = handles.output;
close(handles.ChangeAxesOrientation)

% --- Executes on button press in inout.
function inout_Callback(hObject, eventdata, handles)

% --- Executes on button press in updown.
function updown_Callback(hObject, eventdata, handles)


% --- Executes on button press in Ok.
function Ok_Callback(hObject, eventdata, handles)
cal = get(handles.Calibrate,'Value');
inout = get(handles.inout,'Value'); 
updown = get(handles.updown,'Value');
if ~inout && ~updown, iu = 1; end
if ~inout && updown, iu = 2; end %23/12-19 error corrected
if inout && ~updown, iu = 3; end %23/12-19 error corrected
if inout && updown, iu = 4; end
handles.output = {cal,iu};
guidata(hObject, handles);
uiresume(handles.ChangeAxesOrientation)


% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
handles.output = {NaN 5};
guidata(hObject, handles);
uiresume(handles.ChangeAxesOrientation)


% --- Executes on button press in Calibrate.
function Calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to Calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Calibrate
