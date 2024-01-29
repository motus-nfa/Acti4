function varargout = BatchAnalysis(varargin)

% Opens BatchAnalysis.fig for selection of batch file processing
%
% Ouput is a struct array with the fields:
% SetupFile: Full file name of Setup file
% SetupFileName: File name of Setup file
% Pause [0/1]: 1 if 'Pause' checked
% Vis [0/1]: 1 if 'Show' checked
% ShowRefWindow [0/1]: 1 if 'Show/edit reference position intervals' checked
% Analyse [0/1]: 1 if 'Analyse' checked
% PlotMappe: Directory for saving of plots
% GemmeFil: Full file name for saving of results
% ID [cell]: The IDs selected for analysis  
% AGdir: Directory for Actigraph datafiles
% AHdir: Directory for Actiheart datafiles
% IDtable [cell]: All IDs in the AG directory
% Fig: Figure handle


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BatchAnalysis_OpeningFcn, ...
                   'gui_OutputFcn',  @BatchAnalysis_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    if ~strcmp(varargin{1},'ActiGraphMenu_WindowScrollWheelFcn') %otherwise scrolling in the window with the IDs makes an error 
   gui_mainfcn(gui_State, varargin{:});
    end
end
% End initialization code - DO NOT EDIT

% --- Executes just before BatchAnalysis is made visible.
function BatchAnalysis_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
set(handles.ok,'Enable','Off')
set(handles.Pause,'Value',1)
set(handles.Vis,'Value',1)
set(handles.ShowRefWindow,'Value',1)
set(handles.Analyse,'Value',1)
set(handles.GemmeFil,'String','')
set(handles.PlotMappe,'String','')
Analyse_Callback(handles.Analyse, eventdata, handles)
uicontrol(handles.SelectSetupFile);
uicontrol(handles.SelectSetupFile);
guidata(gcf, handles);
uiwait(handles.ActiGraphMenu);

function varargout = BatchAnalysis_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
close(handles.ActiGraphMenu)

function ok_Callback(hObject, ~, handles)
Svar.SetupFile = get(handles.SetupFile,'String');
[~,Svar.SetupFileName] = fileparts(Svar.SetupFile);
Svar.Pause = get(handles.Pause,'Value');
Svar.Vis = get(handles.Vis,'Value');
Svar.ShowRefWindow = get(handles.ShowRefWindow,'Value');
Svar.Analyse = get(handles.Analyse,'Value');
Svar.PlotMappe = get(handles.PlotMappe,'String');
Svar.GemmeFil =  get(handles.GemmeFil,'String');
IDliste = get(handles.IDliste,'String');
Svar.ID = IDliste(get(handles.IDliste,'Value'));
Svar.AGdir = handles.AGdir;
Svar.AHdir = handles.AHdir;
Svar.IDtable = handles.IDtable;
Svar.Fig = gcf;
handles.output = Svar;
guidata(hObject, handles);
uiresume(gcf)

function Vis_Callback(hObject, ~, handles)
if get(hObject,'Value')
    set(handles.GemPlotI,'Enable','on')
    set(handles.PlotMappe,'Enable','Inactive')
    set(handles.Pause,'Enable','on')
 else
    set(handles.GemPlotI,'Enable','off')
    set(handles.PlotMappe,'Enable','off')
    set(handles.Pause,'Value',0,'Enable','off')
    set(handles.GemResI,'Enable','on')
    set(handles.GemmeFil,'Enable','Inactive');
end

function GemPlotI_Callback(hObject, ~, handles)
Mappe = uigetdir('','Select folder for saving plots');
if ~ischar(Mappe), Mappe = ''; end  % cancel
set(handles.PlotMappe,'String',Mappe)
set(handles.Vis,'Value',1);

function Pause_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
    set(handles.GemResI,'Enable','off')
    set(handles.GemmeFil,'Enable','off');
else
    set(handles.GemResI,'Enable','on')
    set(handles.GemmeFil,'Enable','Inactive');
end

function GemResI_Callback(hObject, eventdata, handles)
fil = get(handles.SetupFile,'String');
[~,Name] = fileparts(fil);
[Fil,Sti] = uiputfile('*.txt','Gemmefil',[Name,'_RES.txt']);
if ischar(Fil), set(handles.GemmeFil,'String',[Sti Fil]), end

function GemmeFil_Callback(hObject, eventdata, handles)
% fil = get(handles.excelArk,'String');
% punkt = strfind(fil,'.');
% [Fil,Sti] = uiputfile('*.xls','Gemmefil',[fil(1:punkt(end)-1) '_RES.xls']);
% set(handles.GemmeFil,'String',[Sti Fil])

function SelectSetupFile_Callback(hObject, ~, handles)
 [SetupFilnavn,SetupSti] = uigetfile('*.xls;*.xlsx','Select setup file (xls,xlsx)');
 cd(SetupSti);
 SetupFile = [SetupSti,SetupFilnavn];
 set(handles.SetupFile,'String',SetupFile);
 [~,Sheets] = xlsfinfo(SetupFile);
 for i=1:length(Sheets), ErID(i) = ~isempty(str2num(Sheets{i})); end
 set(handles.IDliste,'String',Sheets(ErID),'Value',1:size(Sheets(ErID)))
 set(handles.ok,'Enable','On')
 [~,Txt,Raw] = xlsread(SetupFile,'Info');
 handles.AGdir = Txt{strcmp('GT3Xdirectory',Txt(:,1))|strcmp('AGdirectory',Txt(:,1)),2}; %version 5/6 difference

 handles.AHdir = '';
 if any(strcmp('AHdirectory',Txt(:,1)))
    handles.AHdir = Txt{strcmp('AHdirectory',Txt(:,1)),2};
    IDtable = Raw(find(strcmp('ID',Raw(:,1))):end,1:5);
    IDtable(2:end,:) = cellfun(@num2str,IDtable(2:end,:),'UniformOutput',0); %convert numbers to string in ID table
    handles.IDtable = IDtable;
 end
 %winopen(SetupFile);
 try %28/11-18
    Excel = actxGetRunningServer('Excel.Application'); %if Excel setup-fil already is open from previous 'IntervalSetup' session
    if ~strcmp(get(Excel.ActiveWorkBook,'FullName'),SetupFile)
        Excel.Workbooks.Open(SetupFile);   
    end
catch
    Excel = actxserver('Excel.Application');
    set(Excel, 'Visible', 1);
    Excel.Workbooks.Open(SetupFile);
 end

guidata(hObject, handles);

function Cancel_Callback(hObject, eventdata, handles)
handles.output = struct([]);
guidata(hObject, handles);
uiresume(handles.ActiGraphMenu)

 function ShowRefWindow_Callback(hObject, eventdata, handles)
 if get(hObject,'Value')
    set(handles.Analyse,'Value',0)
    Analyse_Callback(handles.Analyse, eventdata, handles)
 end

function Analyse_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
    set(handles.Vis,'Value',1,'Enable','on')
    set(handles.Pause,'Value',1,'Enable','on')
    set(handles.ShowRefWindow,'Value',0)
    set(handles.GemPlotI,'Enable','on')
    set(handles.PlotMappe,'Enable','Inactive')
    set(handles.GemmeFil,'Enable','off');
    set(handles.GemResI,'Enable','off');
else
    set(handles.Vis,'Enable','off')
    set(handles.GemPlotI,'Enable','off')
    set(handles.PlotMappe,'Enable','off')
    set(handles.Pause,'Enable','off')
    set(handles.GemmeFil,'Enable','off');
    set(handles.GemResI,'Enable','off');
end

  
function IDliste_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function IDliste_Callback(hObject, eventdata, handles)

function PlotMappe_CreateFcn(hObject, ~, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function PlotMappe_Callback(hObject, ~, handles)
function SetupFile_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function SetupFile_Callback(hObject, eventdata, handles)

function GemmeFil_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

