function varargout = NotWornFig(varargin)
% NOTWORNFIG MATLAB code for NotWornFig.fig
% Set up the menu NotWornFig for manual selection of not-worn periods.

% Returns a 4 character string e.g. 1011 for thigh worn, hip not-worn, arm worn and trunk worn 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NotWornFig_OpeningFcn, ...
                   'gui_OutputFcn',  @NotWornFig_OutputFcn, ...
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

% --- Executes just before NotWornFig is made visible.
function NotWornFig_OpeningFcn(hObject, eventdata, handles, varargin)
 handles.output = hObject;
 set(handles.ThighNotWorn,'Value',1)
 set(handles.HipNotWorn,'Value',1)
 set(handles.ArmNotWorn,'Value',1)
 set(handles.TrunkNotWorn,'Value',1)
 uiwait(handles.NotWornFig);

% --- Outputs from this function are returned to the command line.
function varargout = NotWornFig_OutputFcn(hObject, eventdata, handles) 
  varargout{1} = handles.output;
  close(handles.NotWornFig)

% --- Executes on button press in Ok.
function Ok_Callback(hObject, eventdata, handles)
  handles.output = [num2str(~get(handles.ThighNotWorn,'Value')),...
  num2str(~get(handles.HipNotWorn,'Value')),...
  num2str(~get(handles.ArmNotWorn,'Value')),...
  num2str(~get(handles.TrunkNotWorn,'Value'))];
  guidata(hObject,handles);
  uiresume(handles.NotWornFig)
