function varargout = RefValues(varargin)

% Opens the RefValues.fig for displaying of reference values during editing
% 
% To get an overview, reference values are shown in this table during processing 
% the reference intervals in the Batch anlysis 

% REFVALUES MATLAB code for RefValues.fig

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @RefValues_OpeningFcn, ...
                   'gui_OutputFcn',  @RefValues_OutputFcn, ...
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

% --- Executes just before RefValues is made visible.
function RefValues_OpeningFcn(hObject, ~, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = RefValues_OutputFcn(~, ~, handles) 
varargout{1} = handles.output;
