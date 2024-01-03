function varargout = IntervalSetup(varargin)

% Setting up intervals for analysis
%
% Displays IntervalSetupFig.fig for specication of intervals for analysis.
% Date and time for specified intervals are saved in an Excel file.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @IntervalSetup_OpeningFcn, ...
                   'gui_OutputFcn',  @IntervalSetup_OutputFcn, ...
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


function IntervalSetup_OpeningFcn(hObject, ~, H, varargin)
    H.output = hObject;

    S = varargin{1};
    H.AGmappe = S{1}; %directory of data files 
    FilNavne = S{2}; %file names of data files 
    H.ExportFile = S{3}; %setup file where to write diary data
    H.AHfile = S{4};  
    H.WB = S{5}; %windows workbook interface to ExportFile 
    LastOne = S{6}; %if the actual subject (ID) is the last one selected for processing 
    if LastOne, set(H.nextID,'Visible','off'), end
    
    ID = FilNavne{1}(1:5);
    set(H.id,'String',ID)
    %Guess the file/positions relationship:
    [Pos,PosActual,FilNavne] = File2BodyPos(FilNavne);
    
    %prepair table:
    for i=1:length(FilNavne)
        [SN,SF(i),Start(i),End,Stop,Down] = AGinfo([H.AGmappe,FilNavne{i}]);
        Time = [num2str(fix(End-Start(i))),':',  datestr(rem(End-Start(i),1),'HH:MM:SS')]; %duration
        if isnan(Stop), StopTxt = ' '; else StopTxt = datestr(Stop); end
        if isnan(Down), DownTxt = ' '; else DownTxt = datestr(Down); end
        Data(i,:) = {PosActual{i},FilNavne{i},datestr(Start(i)),StopTxt,DownTxt,Time,int2str(SF(i)),SN};
    end
    Cnames = {'Position','File','Start','Stop','Down','D:HH:MM:SS','Hz', 'Serial No.'};
    Cformat = {Pos,'char','char','char','char','char','numeric','char'};
    Cedit = [true,false,false,false,false,false,false,false];
    set(H.table,'Data',Data,'ColumnName',Cnames,'ColumnFormat',Cformat,'ColumnEditable',Cedit,...
                'ColumnWidth',{80 250 150 150 0 90 0 90});

    if any(abs(Start(1)-Start) > 5/86400), warndlg('Differences in Start time found'), end %13/9-16: 5 sec difference
    if any(SF(1)-SF~=0), warndlg('Differences in Sampling frequency (Hz) found'), end

    if ~isempty(H.AHfile)%if Actiheart data exists
      set(H.ahtable,'Visible','on')
      [~,AHfilename] = fileparts(H.AHfile);
      load(H.AHfile,'Tbeat')
      AHtime = [num2str(fix(Tbeat(end)-Tbeat(1))),':',  datestr(rem(Tbeat(end)-Tbeat(1),1),'HH:MM:SS')]; %#ok<COLND> %ActiHeart duration
      AHdata = {[AHfilename,'.mat'],datestr(Tbeat(1)),datestr(Tbeat(end)),' ',AHtime}; %#ok<COLND>
      set(H.ahtable,'Data',AHdata,'ColumnWidth',{250,150,150,0,90})
    end
      
    set(H.save,'Enable','off')
    set(H.next,'Enable','off')
    set(H.intervaltype,'Enable','off')

    %types of intervals:
    SETTINGS = getappdata(findobj('Tag','Acti4'),'SETTINGS');
    H.Typer = {...
        ['A1. ',SETTINGS.Period_A1],...    
        ['A2. ',SETTINGS.Period_A2],...
        ['A3. ',SETTINGS.Period_A3],...
        ['A4. ',SETTINGS.Period_A4],...
        ['B1. ',SETTINGS.Period_B1],...
        ['B2. ',SETTINGS.Period_B2],...
        ['B3. ',SETTINGS.Period_B3],...
        ['B4. ',SETTINGS.Period_B4],...
        ['C0. ',SETTINGS.Period_C0],...
        ['C4. ',SETTINGS.Period_C4],...
        ['D. ',SETTINGS.Period_D],...
        'E. Actigraph(s) worn/not worn',...
        'F. Reference',...
        'G. Synchronization'};
        
    set(H.intervaltype,'String',H.Typer,'Value',1)
    set(H.date,'String',datestr(Start(1),'dd/mm/yyyy'))
    set(H.Esekund,'String','00')
    set(H.Ssekund,'String','00')
    set(H.Etime,'String','00')
    set(H.Eminut,'String','00')
    set(H.Stime,'String','00')
    set(H.Sminut,'String','00')
    uicontrol(H.Confirm)
    uicontrol(H.Confirm)
    H.Nexted = 1;
    H.Saved = 0;
    guidata(hObject, H);
    uiwait(H.IntervalSetupFig);


% --- Outputs from this function are returned to the command line.
function varargout = IntervalSetup_OutputFcn(hObject, eventdata, H) 
  varargout{1} = H.output;
  close(H.IntervalSetupFig)

  
function Confirm_Callback(hObject, ~, H)
% Initially, set up of the worksheet, startline etc.

   set(H.id,'Enable','Inactive')
   set(H.table,'ColumnEditable', false(1,8));
   set(H.next,'Enable','on')
   set(H.intervaltype,'Enable','on')
     
   NewSheet = get(H.id,'String');
   [~,SheetNames] = xlsfinfo(H.ExportFile);
   if any(strcmp(NewSheet,SheetNames))
     [~,~,Raw] = xlsread(H.ExportFile,NewSheet);
     Svar = questdlg({['The setup-file already contains a sheet ',NewSheet,' !'];...
                      ['Do you want to append data to ',NewSheet,' ?']},'','Yes','No','No');
     if strcmp(Svar,'Yes')
        H.Sheet = get(H.WB.Worksheets,'Item',NewSheet);
        H.Sheet.Activate
        RowS = size(Raw,1)+1; %start row number for appending lines  
        H.RangeD = {['A',num2str(RowS)],['D',num2str(RowS)]}; %start position for writing interval data
        uicontrol(H.intervaltype)
     else
       set(H.id,'Enable','on')
       return   
     end
   else
   
     %First update the ID table in the Info-sheet with NewSheet name:
     [~,~,Raw] = xlsread(H.ExportFile,'Info');
     InfoRow = num2str(size(Raw,1)+1);
     WS = H.WB.Worksheets;
     RangeInfo = get(get(WS,'Item','Info'),'Range',['A',InfoRow],['B',InfoRow]);
     if isempty(H.AHfile)
         set(RangeInfo,'Value',{[char(39),NewSheet],[]}) %to make Excel accept a zero as first character
     else
         set(RangeInfo,'Value',{[char(39),NewSheet],[char(39),NewSheet]}) %ActiHeart file exists 
     end
   
     %Then add the new sheet and setup for writing:
     WS.Add([],WS.Item(WS.Count)); %add a new sheet at the end
     H.Sheet = get(WS,'Item', WS.Count);
     set(H.Sheet,'Name',NewSheet)
      
     hRange = get(H.Sheet,'Range','A1','H6');
     Tabel = cell(6,8);
     set(hRange,'ColumnWidth',20) %,'HorizontalAlignment',-4108)
     tabel = cat(1,get(H.table,'ColumnName')',get(H.table,'Data'));
     if ~isempty(H.AHfile), tabel = cat(1,tabel, cat(2,'ActiHeart',get(H.ahtable,'Data'),' ',' ')); end
     Tabel(1:size(tabel,1),:) = tabel;
     set(hRange,'Value',Tabel)
    
     hRange = get(H.Sheet,'Range','A9','D9');
     set(hRange,'Value',{'Type','Weekday','Start','Stop'})
   
     H.RangeD = {'A10','D10'}; %start position for writing interval data
   
     invoke(H.WB,'Save');
     
     set(hObject,'Enable','off')
     uicontrol(H.intervaltype)
   end
   guidata(gcf,H)  
  
  
function intervaltype_Callback(hObject, eventdata, H)
%After selection of the interval, type cursor jumps to hour-window, possible opens window for selection not-worn AGs
   set(H.save,'Enable','on')
   if strcmp(H.RangeD{1},'A10') %Start time first time
      uicontrol(H.Stime)
   else
      uicontrol(H.Etime) %else End time
   end
   if strcmp(H.Typer(get(hObject,'Value')),'E. Actigraph(s) worn/not worn')
     %select which Actigraphs worn/not worn:
     H.Worn = NotWornFig; %ex: Worn = 1100 (ThighHipArmTrunk), means Arm and Trunk accelerometer not worn 
   end
   guidata(gcf, H);

%Checking of format and consistency of time values:
function Stime_Callback(hObject,~,~)
  Check(hObject,'HH')
function Sminut_Callback(hObject,~,~)
  Check(hObject,'MMSS')
function Ssekund_Callback(hObject,~,~)
  Check(hObject,'MMSS')
function Etime_Callback(hObject,~,~)
  Check(hObject,'HH')
function Eminut_Callback(hObject,~,~)
  Check(hObject,'MMSS')
function Esekund_Callback(hObject,~,~)
  Check(hObject,'MMSS')
  
function Check(hObject,type)
  if strcmp(type,'HH'), Range = [0 23]; end
  if strcmp(type,'MMSS'), Range = [0 59]; end
  XX = fix(str2double(get(hObject,'String')));
  if XX<min(Range) || max(Range)<XX
     XX = '??';
     set(hObject,'String',XX)
  else
      if XX<10, XX = ['0',num2str(XX)]; else XX = num2str(XX); end
      set(hObject,'String',XX)
  end
  
function DateDecrement_Callback(~, ~, H) %decrement date window
  Date = datenum(get(H.date,'String'),'dd/mm/yyyy');
  set(H.date,'String',datestr(Date-1,'dd/mm/yyyy'))

function DateIncrement_Callback(~, ~, H) %increment date window
  Date = datenum(get(H.date,'String'),'dd/mm/yyyy');
  set(H.date,'String',datestr(Date+1,'dd/mm/yyyy'))


function save_Callback(~, ~, H)
%Reads the filled in time data, writes to worksheet
   if ~H.Nexted && H.Saved %"Next" button not activated directly after "Save"
      Svar = questdlg('Overwrite already saved interval data?','Overwrite?','No','Yes','No');
      if strcmp(Svar,'No'), return, end  
   end   
   Etime =get(H.Etime,'String');
   Eminut =get(H.Eminut,'String');
   Esekund =get(H.Esekund,'String');
   Etid = str2double(Etime) + str2double(Eminut)/60 + str2double(Esekund)/3600;
   Stime =get(H.Stime,'String');
   Sminut =get(H.Sminut,'String');
   Ssekund =get(H.Ssekund,'String');
   Stid = str2double(Stime) + str2double(Sminut)/60 + str2double(Ssekund)/3600;
   StartDate = datenum(get(H.date,'String'),'dd/mm/yyyy');
   StartTime =  StartDate + Stid/24;
   EndDate = StartDate;
   if Etid<Stid, EndDate = EndDate+1; end
   EndTime = EndDate + Etid/24;
   
   Data = get(H.table,'Data');
   if isempty(deblank(Data{1,4})), SlutTid = datenum(Data{1,5}); else SlutTid = datenum(Data{1,4}); end
   if StartTime < datenum(Data{1,3}) ||  SlutTid < EndTime
     msgbox('Illegal date/time  setting!')
     return
   end
   Day = num2str(weekday(mean([StartTime,EndTime])-1)); %weekday of midtime, monday = day 1
   
   hRange = get(H.Sheet,'Range',H.RangeD{1},H.RangeD{2});
   Typen = H.Typer(get(H.intervaltype,'Value')); 
   %By the worn/not worn category: A code for which Actigraph(s) worn/not worn , is added:
   if strcmp(Typen,'E. Actigraph(s) worn/not worn'), Typen = {['E.',H.Worn,' Actigraph(s) worn/not worn']}; end
   set(hRange,'Value',{Typen{1},Day,...
                       datestr(StartTime,'dd/mm/yyyy/HH:MM:SS'),...
                       datestr(EndTime,'dd/mm/yyyy/HH:MM:SS')})
   invoke(H.WB,'Save');
   H.Saved = 1;
   H.Nexted = 0;
   uicontrol(H.next) 
   guidata(gcf,H);
   
   
function next_Callback(~, ~, H)
% Previous End times are enteredvas new Start times, increment row number in worksheet
   if ~H.Saved
       Svar = questdlg('Proceed to next interval without saving?','Saving?','No','Yes','No');
       if strcmp(Svar,'No'), return, end
   end 
   Etime =get(H.Etime,'String');
   Eminut =get(H.Eminut,'String');
   Esekund =get(H.Esekund,'String');
   Etid = str2double(Etime) + str2double(Eminut)/60 + str2double(Esekund)/3600;
   Stime =get(H.Stime,'String');
   Sminut =get(H.Sminut,'String');
   Ssekund =get(H.Ssekund,'String');
   Stid = str2double(Stime) + str2double(Sminut)/60 + str2double(Ssekund)/3600;
   
   %If the previous interval type was not a reference, previous end-times are entered as the new start-times: 
   if strcmp(H.Typer(get(H.intervaltype,'Value')),'F. Reference');
      set(H.Stime,'String','00')
      set(H.Sminut,'String','00')
      set(H.Ssekund,'String','00')
   else
      set(H.Stime,'String',Etime)
      set(H.Sminut,'String',Eminut)
      set(H.Ssekund,'String',Esekund) 
   end
   set(H.Etime,'String','00')
   set(H.Eminut,'String','00')
   set(H.Esekund,'String','00')
   set(H.intervaltype,'Value',1)
   if Etid<Stid, DateIncrement_Callback([],[],H), end %propose the next date
   %Step to next row in sheet:
   H.RangeD = {['A',num2str(str2double(H.RangeD{1}(2:end))+1)],...
               ['D',num2str(str2double(H.RangeD{1}(2:end))+1)]};
   H.Saved = 0;
   H.Nexted = 1;                
   uicontrol(H.intervaltype)
   guidata(gcf,H)
   
function exit_Callback(hObject, ~, H)
  H.output = struct([]);
  guidata(hObject,H);
  uiresume(H.IntervalSetupFig)
 
function nextID_Callback(~, ~, H)
  uiresume(H.IntervalSetupFig)

function show_Callback(hObject, eventdata, H)
%this calls the Single file viewing menu for checking data
  ActiG('Single')

  

function date_Callback(hObject, eventdata, H)

  
function id_Callback(hObject, eventdata, handles)
  
function date_CreateFcn(hObject, eventdata, H)
function intervaltype_CreateFcn(hObject, eventdata, H)
function Stime_CreateFcn(hObject, eventdata, H)
function Sminut_CreateFcn(hObject, eventdata, H)
function Ssekund_CreateFcn(hObject, eventdata, H)
function Etime_CreateFcn(hObject, eventdata, H)
function Eminut_CreateFcn(hObject, eventdata, H)
function Esekund_CreateFcn(hObject, eventdata, H)
function id_CreateFcn(hObject, eventdata, handles)
