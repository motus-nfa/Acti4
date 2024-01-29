function varargout = SetupSelect(varargin)

% Opens the SetupSelect menu for specification of raw data directory, selection of subjects etc.
% in order to create a setup file and/or append a new measurement (ID) to the setup file.  
%
% Output is a struct specifying the selected files with the fileds:
% AGmappe: Directory including AG data files (.gt3x+ or .act4 files)
% Filnavne: Name of AG files (cell)
% ExportFile: Full name of Excel file to write diary information (Setup file)
% AHfiles: Full name of Actiheart files (cell)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SetupSelect_OpeningFcn, ...
                   'gui_OutputFcn',  @SetupSelect_OutputFcn, ...
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

% --- Executes just before SetupSelect is made visible.
function SetupSelect_OpeningFcn(hObject, ~, H, varargin)
H.output = hObject;
guidata(hObject, H);
uicontrol(H.selectAGdir)
uicontrol(H.selectAGdir)
uiwait(H.SetupSelect);

% --- Outputs from this function are returned to the command line.
function varargout = SetupSelect_OutputFcn(~, ~, H) 
varargout{1} = H.output;
close(H.SetupSelect)

function selectAGdir_Callback(hObject, ~, H)
% Selection of a directory with AG data files, either gt3x+ (only ActilLife ver. 5) files or act4 files (gt3x+ converted
% from ActiLife ver. 6 (or 5)) and displaying in list. 
% Gt3x+ ver. 5 files needs not to be converted to act4 files, but if this is done they must not be found in the same directory!  
  Mappe = uigetdir([],'Select directory with AG data files');
  if ischar(Mappe)
     cd(Mappe)
     Mappe = [Mappe,'\'];
     set(H.AGdir,'String',Mappe)
     BibGT3X = dir(fullfile(Mappe,'*.gt3x'));
     FilerGT3X = sort({BibGT3X.name});
     %Check if the gt3x files are of version 5 and select only those:
     Ver5 = false(1,length(FilerGT3X));
     for i=1:length(FilerGT3X) 
         Ver5(i) = CheckIfVersion5(FilerGT3X{i},0);  
     end
     FilerGT3X = FilerGT3X(Ver5);
     %Find act4 files:
     BibACT4 = dir(fullfile(Mappe,'*.act4'));
     FilerACT4 = sort({BibACT4.name});
    
     if isempty(FilerGT3X), Filer = (FilerACT4); end
     if isempty(FilerACT4), Filer = (FilerGT3X); end
     if ~isempty(FilerACT4) && ~isempty(FilerGT3X)
         Filer = cat(2,FilerGT3X,FilerACT4); %both types files
     end
     if isempty(Filer), msgbox({'No AG data files (gt3x ver.5  or act4) found in the selected directory:';Mappe}), return, end
     set(H.filelist,'String',Filer)

     %Get IDs:
     for i=1:length(Filer)
         IDs(i,:) = Filer{i}(1:5);
         [~,~,Ext(i,:)] = fileparts(Filer{i});
     end
     
     %Check if both ver. 5 gt3-files and act4-files should be found for the
     %some ID(s) in the selected directory; this is not allowed
     IDsExt = unique(cellstr(cat(2,IDs,Ext)));
     charIDsExt = cell2mat(IDsExt);
     RepIDs = cellstr(charIDsExt(:,1:5));
     [~,IA,IC] = unique(RepIDs);
     Illegal = RepIDs(setdiff(IC,IA));
     if ~isempty(Illegal)
        errordlg({'Both ver. 5 gt3-files and act4-files found for IDs';cell2mat(Illegal);['in ',Mappe]})
        error(' ')
     end
     
     ID = unique(cellstr(cat(2,IDs,repmat(' (',size(Ext,1),1),Ext(:,2:5),repmat(')',size(Ext,1),1))));
     set(H.idlist,'String',ID) %list of unique IDs
     set(H.filelist,'Enable','off')
     set(H.filelist,'Value',length(Filer),'ListboxTop',1)% cannot hide the blue selection bar otherwise 
     uicontrol(H.idlist)
     guidata(hObject, H);
  end

function create_Callback(hObject, ~, H)
% Create a new Excel file for writing setup data
  [ExportFileName,Mappe] = uiputfile('*.xls','Create an Excel file for export of data');
  if ischar(Mappe)
     H.ExportFile = [Mappe,ExportFileName];
     xlswrite(H.ExportFile,{'AGdirectory',get(H.AGdir,'String');'AHdirectory',get(H.AHdir,'String')},'Info');
     xlswrite(H.ExportFile,{'ID','AH','Age','HRrest','HRmax','Remarks'},'Info','A4')
     set(H.setupfile,'String',ExportFileName)
     uicontrol(H.ok)
     guidata(hObject, H);
  end
  
function append_Callback(hObject, ~, H)
% Select an existing setup file for writing setup data
  [ExportFileName,Mappe] = uigetfile('*.xls','Select Excel file for appending data');
  if ischar(Mappe)
     H.ExportFile = [Mappe,ExportFileName];
     set(H.setupfile,'String',ExportFileName)
     uicontrol(H.ok)
     guidata(hObject, H);
  end

function cancel_Callback(hObject, ~, H)
  H.output = struct([]);
  guidata(hObject,H);
  uiresume(H.SetupSelect)


function ok_Callback(hObject, ~, H)
% Reads which IDs in the ID list or which individual files (max. 4) in the filelist have been selected,
% checks if a AH file exists for the selected IDs
  if strcmp(get(H.idlist,'Enable'),'on') %ID list used
     IDliste = get(H.idlist,'String'); 
     ID = IDliste(get(H.idlist,'Value'));
     for i=1:length(ID)
        Ext = ID{i}(8:11);
        S = dir([get(H.AGdir,'String'),ID{i}(1:5),'*.',Ext]);
        Filnavne{i} = {S.name};
     end
  end
  if strcmp(get(H.filelist,'Enable'),'on') %individual file list (normally not used, could be removed)
     Filliste = get(H.filelist,'String'); 
     Filnavne = cellfun(@transpose,{Filliste(get(H.filelist,'Value'))},'UniformOutput',false);
     if ~iscell(Filnavne), Filnavne = {Filnavne}; end %only one selected
     if length(Filnavne)>4, msgbox('Maximum number (4) of selected files exceeded'), return, end 
  end
  %check if AH files exist for the selected ID, notify if not
  AHdir = get(H.AHdir,'String');
  if isempty(AHdir)
     AHfiles = cell(size(Filnavne));
  else
    NotFound = {}; %Find the AH files: 
    for i=1:length(ID)
       S = dir([AHdir,ID{i}(1:5),'.mat']);
       if isempty(S)
          AHfiles{i} = '';
          NotFound = cat(1,NotFound,['ActiHeart file ',ID{i}(1:5),'.mat not found']); 
       else
          AHfiles{i} = fullfile(AHdir,S.name);
       end
    end
    if ~isempty(NotFound) %if some AH .mat files were not found
       Ans = questdlg(NotFound,' ','Cancel','Ok','Ok');
       if strcmp('Cancel',Ans), return, end
    end
  end
  
  AGdir = get(H.AGdir,'String');
  if isfield(H,'ExportFile') %to rember to select/create ExportFile
     S = struct('AGmappe',{AGdir},'Filnavne',{Filnavne},'ExportFile',{H.ExportFile},'AHfiles',{AHfiles});
     H.output = S;
     guidata(hObject,H);
     uiresume(H.SetupSelect)
  end
  
  

function uipanel2_SelectionChangeFcn(~, eventdata, H)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'IDselect'
      set(H.idlist,'Enable','on')
      set(H.filelist,'Enable','off')  
    case 'fileselect'
      set(H.idlist,'Enable','off')
      set(H.filelist,'Enable','on')   
end

function SelectAHdir_Callback(hObject, eventdata, H)
  Mappe = uigetdir([],'Select directory including ActiHeart file (.mat) for selected ID');
  if ischar(Mappe)
     set(H.AHdir,'String',[Mappe,'\'])
  end
 
  
% --- Executes during object creation, after setting all properties.
function SetupSelect_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function SelectAHdir_CreateFcn(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function selectAGdir_CreateFcn(hObject, eventdata, handles)

% --- Executes during object deletion, before destroying properties.
function SetupSelect_DeleteFcn(hObject, eventdata, handles)

function AGdir_CreateFcn(hObject, eventdata, H)
function AGdir_Callback(hObject, eventdata, H)
function setupfile_CreateFcn(hObject, eventdata, H)
function setupfile_Callback(hObject, eventdata, H)
function idlist_Callback(hObject, eventdata, H)
function idlist_CreateFcn(hObject, eventdata, H)
function filelist_Callback(hObject, eventdata, H)
function filelist_CreateFcn(hObject, eventdata, H)
