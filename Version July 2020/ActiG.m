function ActiG(Mode)

% ActiG runs the first 6 items in the main menu opened by Acti4.m
%
% ActiG consists of 
% 1) a header part setting up cells arrays for graph labels and column headers specifying output parameters
% 2) a switch structure with cases selected by the 'Mode' input parameter corresponding to one of the first 6 items in Acti4.fig 
% 3) finally some supporting functions.

global FidEVA FidHRV FidCalfResults %kun til brug for evt. EVA analyse (EVAactiGenerel3.m), HRV analyse og ved Calf accelerometer
SETTINGS = getappdata(findobj('Tag','Acti4'),'SETTINGS');
[~,~,ParRaw] = xlsread(fullfile(fileparts(which('Acti4')),'ParameterList.xlsx'),'List'); %Read parameter list from Excel file, which must be found in path of Acti4
ColHeadBase = ParRaw(1,cell2mat(cellfun(@isstr,ParRaw(1,:),'UniformOutput',false))); %Column headings must be in lines 1-5:
ColHeadAct = ParRaw(2,cell2mat(cellfun(@isstr,ParRaw(2,:),'UniformOutput',false)));
ColHeadInc = ParRaw(3,cell2mat(cellfun(@isstr,ParRaw(3,:),'UniformOutput',false)));
ColHeadHR = {};
ColHeadHRdist = {};
if SETTINGS.IncludeAH % if Actiheart data should be included for analysis
   ColHeadHR = ParRaw(4,cell2mat(cellfun(@isstr,ParRaw(4,:),'UniformOutput',false)));
   ColHeadHRdist = ParRaw(5,cell2mat(cellfun(@isstr,ParRaw(5,:),'UniformOutput',false)));
end
ColHead = cat(2,ColHeadBase,ColHeadAct,ColHeadInc,ColHeadHR,ColHeadHRdist); 
ParFormats = ParRaw(8,1:size(ColHead,2)); % Formats for writing results in text file (line 8)

Ylab = {{'off';'lie';'sit';'stand';'move';'walk';'run';'stairs';'cycle';'row'},...
        {'off';'lie/sit';'stand';'move';'walk';'run';'stairs';'cycle';'row'}};
ThresArm = [30,60,90,120,150]; %Levels for analysis of arm inclination 
ThresTrunk = [20,30,60,90]; %Levels for analysis of forward trunk inclination
RefCol = {'VrefTrunk_Inc(°)','VrefTrunk_U(°)','VrefTrunk_V(°)','VrefArm_Inc(°)','VrefArm_U(°)','VrefArm_V(°)',...
          'VrefHip_Inc(°)','VrefHip_U(°)','VrefHip_V(°)','VrefThigh_Inc(°)','VrefThigh_U(°)','VrefThigh_V(°)'};
IntAbr = {'A1.','A2.','A3.','A4.','B1.','B2.','B3.','B4.','C0.','C4.','D. '};
ShiftAxes = zeros(5,1); %for information on possible shift of accelerometer orientation for analysis interval

%********************************************************************************************************************************
switch Mode

%********************************************************************************************************************************
case 'Single' %Single file viewing, can be called directly by the main menu or by IntervalSetup
   %For visualizing of preliminary data; individual reference positions not included 
  [Tbeat,RR] = deal([]);  
  if isempty(findobj('Tag','IntervalSetupFig')) %'Single' called by the Main menu:
     delete(findobj('Tag','SelectSingleFiles'));  
     S = SelectSingleFiles('AH');
     if isempty(S), close, return, end %Cancel was selected
     FilThigh = S.FilThigh;
     AHalone = 0; % 11/5-19: to make it possible to select a heart file alone
     if isempty(FilThigh) && isfield(S,'AHfile') % 11/5-19: to make it possible to select a heart file alone
        AHalone = 1;
     end
     if isempty(FilThigh) && ~AHalone
        errordlg('A Thigh file must be selected'), error('A Thigh file must be selected')
     end
     FilHip = S.FilHip;
     FilArm = S.FilArm;
     FilTrunk = S.FilTrunk;
     if isfield(S,'AHfile') && ~isempty(S.AHfile), load(S.AHfile,'Tbeat','RR'), end
   else %'Single' called from 'IntervalSetup': 
     H = guidata(findobj('Tag','IntervalSetupFig'));
     Tabel = get(H.table,'Data');
     FilThigh = char(fullfile(H.AGmappe,Tabel(strcmp(Tabel(:,1),'Thigh'),2))); 
     FilHip = char(fullfile(H.AGmappe,Tabel(strcmp(Tabel(:,1),'Hip'),2)));
     FilArm = char(fullfile(H.AGmappe,Tabel(strcmp(Tabel(:,1),'Arm'),2)));
     FilTrunk = char(fullfile(H.AGmappe,Tabel(strcmp(Tabel(:,1),'Trunk'),2)));
     if isfield(H,'AHfile') && ~isempty(H.AHfile), load(H.AHfile,'Tbeat','RR'), end
     AHalone = 0;
  end
  
  %Find the ID number from first of non-empty file:
  AGfiles = {FilThigh,FilHip,FilArm,FilTrunk};
  if ~AHalone
     Name = '';
     i = 1;
     while isempty(Name)
       [~,Name] = fileparts(AGfiles{i});
       i=i+1;
     end
     ID = Name(1:5); %Running number of subject
  
     [StartActi,StopActi,SF] = CheckFiles(FilThigh,FilHip,FilArm,FilTrunk);

     StartActi = ceil(StartActi*86400)/86400; %round to next second, to prevent problem with 'Next' and 'Previous'
     Datoer = cellstr(datestr(fix(StartActi):fix(StopActi),'dd/mm/yyyy')); %the days of measurement
     Start = StartActi;
     Slut = min([Start + 1/24,StopActi]); %1 hour for first plot
  else %only AH data present (11/5-19)
      [~,ID] = fileparts(S.AHfile);
      SF = 30;
      Start = Tbeat(1);
      Slut = min([Start + 1/24,Tbeat(end)]);
      StartActi = Start;
      StopActi = Tbeat(end);
      Datoer = cellstr(datestr(fix(Start):fix(Tbeat(end)),'dd/mm/yyyy')); %the days of measurement
  end
  
  VrefThigh =  pi*[16 -16 0]/180; %mean reference angles for AGthigh of BAuA data
  if BackFront(FilTrunk) == 1 %AG at the back
     VrefTrunk = pi*[27 27 0]/180; %mean reference angles for AGtrunk of BAuA data
  else %AG at the front, preliminary (Marts 15)  
     VrefTrunk = pi*[15 15 0]/180;
  end
  VrefArm = pi*10/180; %dummy variable
  VrefHip = [];
  %Plot of first hour :
  AnalyseAndPlot(ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,VrefHip,VrefTrunk,ThresTrunk,ThresArm,SF,Start,Slut,Ylab,1,[],[],[],Tbeat,RR,[],[],[],[],[],ColHeadAct,ColHeadInc,ShiftAxes);

  hSelectSingleFiles = findobj('Tag','SelectSingleFiles');
  hActiFig = figure(findobj('Tag','ActiFig'));
  %Adding controls for browsing of recorded data:
  hStartDate = uicontrol('Style','List','String',Datoer,'Units','Characters','Position',[5 1 18 2.5],'FontSize',10);
  hStartTime = uicontrol('Style','Edit','String',datestr(Start,'HH:MM:SS'),'Units','Characters','Position',[13 3.6 11 1.1],'FontSize',10);
  hStep = uicontrol('Style','Edit','String',1,'Units','Characters','Position',[30 1 5 2],'FontSize',10);
  uicontrol('Style','Text','String','hours','Units','Characters','Position',[35 .5 7 2.2],'BackgroundColor',[.8 .8 .8],'FontSize',10);
  hNext = uicontrol('Style','Togglebutton','String','Next','Callback','uiresume','Units','Characters','Position',[50 .7 12 2.2],'FontSize',10);
  hPrevious = uicontrol('Style','Togglebutton','String','Previous','Callback','uiresume','Units','Characters','Position',[75 .7 12 2.2],'FontSize',10);
  hExit = uicontrol('Style','ToggleButton','String','Exit','Callback','uiresume','Units','Characters','Position',[100 .7 12 2.2],'FontSize',10);
  
  set(hPrevious,'Visible','off')%starting to the very left
  OldStart = datenum(Datoer(get(hStartDate,'Value')),'dd/mm/yyyy') + rem(datenum(get(hStartTime,'String')),1);
  OldStep = str2double(get(hStep,'String'))/24;
  while ~get(hExit,'value')
      uiwait(hActiFig)
      if get(hExit,'value'), close, close(hSelectSingleFiles), return, end
      Start = datenum(Datoer(get(hStartDate,'Value')),'dd/mm/yyyy') + rem(datenum(get(hStartTime,'String')),1);
      Step = str2double(get(hStep,'String'))/24;
      if all([Start==OldStart,Step==OldStep])%Start and Step not changed: proceed to right or left
         if get(hNext,'Value')
            Start = Slut;
            Slut = min([Start + Step,StopActi]);
         end
         if get(hPrevious,'Value')
            Slut = Start;
            Start = max([Slut - Step,StartActi]);
         end
         set(hStartDate,'Value',find(strcmp(datestr(Start,'dd/mm/yyyy'),Datoer)))
         set(hStartTime,'String',datestr(Start,'HH:MM:SS'))
      else %Use new values for Start and/or Step 
         Slut = min([Start + Step,StopActi]); 
      end
      AnalyseAndPlot(ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,VrefHip,VrefTrunk,ThresTrunk,ThresArm,SF,Start,Slut,Ylab,1,[],[],[],Tbeat,RR,[],[],[],[],[],ColHeadAct,ColHeadInc,ShiftAxes);
      set(hNext,'Value',0)
      set(hPrevious,'Value',0)
      OldStart = datenum(Datoer(get(hStartDate,'Value')),'dd/mm/yyyy') + rem(datenum(get(hStartTime,'String')),1);
      OldStep = str2double(get(hStep,'String'))/24;
      if Slut==StopActi, set(hNext,'Visible','off'), else set(hNext,'Visible','on'), end
      if Start==StartActi, set(hPrevious,'Visible','off'), else set(hPrevious,'Visible','on'), end
  end
  close(hActiFig)
  close(hSelectSingleFiles)

%********************************************************************************************************************************

case 'Batch'
  
  [FidEVA,FidHRV,FidCalfResults] = deal([]); %global variabel kun til brug for evt. EVA analyse (EVAactiGenerel3.m), HRV analyse og hvis Calf er inkluderet
  S = BatchAnalysis;
  if isempty(S), return, end %Cancel was selected 
  if ~isempty(S.GemmeFil), warning('OFF','MATLAB:xlswrite:AddSheet'), end
     
  close(findobj('Tag','NowAnalysing'))
  hNowAnalysing = NowAnalysing(S);
  hID = findobj(hNowAnalysing,'Tag','ID');
  hActivity = findobj(hNowAnalysing,'Tag','Activity');
  hInterval = findobj(hNowAnalysing,'Tag','Interval');
  hStop = findobj(hNowAnalysing,'Tag','Stop');
  hNext = findobj(hNowAnalysing,'Tag','Next');
  hPrevious = findobj(hNowAnalysing,'Tag','Previous');
  hNextID = findobj(hNowAnalysing,'Tag','NextID');
  hFileNoNow = findobj(hNowAnalysing,'Tag','FileNoNow');
  set(findobj(hNowAnalysing,'Tag','FileNoTotal'),'String',num2str(size(S.ID,1)));
     
  Icol = 3; %column number of start time of interval in the setup file
  
  %Create text files for saving results (RES) and file for supporting information (REF) and write column headers:
  if ~isempty(S.GemmeFil)
      Fid = fopen(S.GemmeFil,'a');
      fprintf(Fid,[strjoin(ColHead,','),'\r\n']);
      fclose(Fid);
      [Sti,Navn] = fileparts(S.GemmeFil);
      RefFil = fullfile(Sti,[Navn,'_REF.txt']);
      Fid = fopen(RefFil,'a');
      fprintf(Fid,[datestr(now),'\r\n']);
      fprintf(Fid,[get(findobj('Tag','Acti4'),'Name'),'\r\n']);
      fprintf(Fid,['Setup file: ',strrep(S.SetupFile,'\','\\'),'\r\n']);
      fprintf(Fid,['AG datafiles directory: ',strrep(S.AGdir,'\','\\'),'\r\n']);
      fprintf(Fid,['AH datafiles directory: ',strrep(S.AHdir,'\','\\'),'\r\n']);
      fprintf(Fid,['Results file: ',strrep(S.GemmeFil,'\','\\'),'\r\n']);
      fprintf(Fid,'\r\n');
      fprintf(Fid,'SETTINGS:\r\n');
      Txt = fieldnames(SETTINGS);
      Val = cell(struct2cell(SETTINGS));
      for i=1:length(Txt)
          if isnumeric(Val{i}), Vali = num2str(Val{i}); else Vali = Val{i}; end
          if ~strncmp(Txt{i},'Period',6), fprintf(Fid,[Txt{i},': ',Vali,'\r\n']); end
          %Periods are not printed because they might not reflect the types selected for the actual setup-file
      end
      fprintf(Fid,'\r\n');
      fprintf(Fid,['LbNr,',strjoin(RefCol,','),'\r\n']);
      fclose(Fid);
  end
  
  Excel = actxGetRunningServer('Excel.Application');
  
  i=1; %ID løkke
  while ~get(hStop,'Value') && i<=length(S.ID)
   set(hActivity,'String','')
   set(hInterval,'String',' ') 
   set(hID,'String',S.ID{i})
   set(hFileNoNow,'String',num2str(i))

   Sheet = get(Excel.ActiveWorkBook.Sheets,'Item', S.ID{i});
   invoke(Sheet,'Activate');
   RawRange = get(Sheet,'Range','A1',['H',num2str(get(Sheet.UsedRange.Rows,'Count'))]);
   Raw = get(RawRange,'Value');
   
   [FilThigh,FilHip,FilArm,FilTrunk] = deal('');
   ThighRow = find(strcmp('Thigh',Raw(:,1)));
   if ~isempty(ThighRow)
       FilThigh = fullfile(S.AGdir,Raw{ThighRow,2});
       
       %Check if directory is found (20/1-20, nu kun check af mappe)
       Folder = fileparts(FilThigh);
       if ~exist(Folder,'dir')
           errordlg({['Directory ',Folder,' not found'],'Check Setup-file (Info sheet) for correct AGdir'})
           error(['Directory ',Folder,' not found'])
       end
       
       FilThigh = Ver5to6ext('AG',FilThigh);  %old setup-files: gt3x extension added  
   end
   HipRow = find(strcmp('Hip',Raw(:,1)));
   if ~isempty(HipRow)
       FilHip = fullfile(S.AGdir,Raw{HipRow,2});
       FilHip = Ver5to6ext('AG',FilHip);
   end
   ArmRow = find(strcmp('Arm',Raw(:,1)));
   if ~isempty(ArmRow)
       FilArm = fullfile(S.AGdir,Raw{ArmRow,2}); 
       FilArm = Ver5to6ext('AG',FilArm);
   end
   TrunkRow = find(strcmp('Trunk',Raw(:,1)));
   if ~isempty(TrunkRow)
       FilTrunk = fullfile(S.AGdir,Raw{TrunkRow,2}); 
       FilTrunk = Ver5to6ext('AG',FilTrunk);
   end  
  
   [StartActi,StopActi,SF] = CheckFiles(FilThigh,FilHip,FilArm,FilTrunk);
   
   [Tbeat,RR,HRrest,HRmax] = deal([]);
   ActiHeartDelay = NaN;
   if SETTINGS.IncludeAH && any(strcmp('ActiHeart',Raw(:,1))) %if ActiHeart row exists
     FileNameActiHeart = Raw{strcmp('ActiHeart',Raw(:,1)),2};
     if isnumeric(FileNameActiHeart), FileNameActiHeart = num2str(FileNameActiHeart); end %FileNameActiHeart is same ID
     if ~isempty(FileNameActiHeart) 
       FilActiHeart = fullfile(S.AHdir,FileNameActiHeart);
       FilActiHeart = Ver5to6ext('AH',FilActiHeart);
       load(FilActiHeart,'Tbeat','RR');
       IrowID = find(strcmp(S.ID{i},S.IDtable(:,1)),1); %find(...,1): to get around a case with repeted identical row (accidental error)
       IcolHRrest = strcmp('HRrest',S.IDtable(1,:));
       IcolAge = strcmp('Age',S.IDtable(1,:));
       IcolHRmax = strcmp('HRmax',S.IDtable(1,:)); %29/5-19
       HRrest = str2double(S.IDtable(IrowID,IcolHRrest));
       Age = str2double(S.IDtable(IrowID,IcolAge));
       HRmax = str2double(S.IDtable(IrowID,IcolHRmax)); %29/5-19:
       if isempty(HRmax) || isnan(HRmax)  % if no HRmax is found, calculate by means of Age: 
          HRmax = 208-.7*Age;
       end
     end
     %Delay (sec.) of ActiHeart time is saved in the 'Hz' column:
     ActiHeartDelay = Raw{strcmp('ActiHeart',Raw(:,1)),strcmp('Hz',Raw(1,:))}; %delay in sec. of actiheart time re actigraph time
     
     if ischar(ActiHeartDelay), ActiHeartDelay = str2double(deblank(ActiHeartDelay)); end
     if isnan(ActiHeartDelay) || isempty(ActiHeartDelay), ActiHeartDelay=0; else Tbeat = Tbeat - ActiHeartDelay/86400; end
   end
   %................................................................................................................................
   if S.ShowRefWindow
      RefRows = find(strcmp('F. Reference',Raw(:,1)));
      if S.ShowRefWindow 
        if ~isempty(RefRows) 
          set(hActivity,'String','Reference');
          set(hInterval,'Enable','Off')
          hRefValues = RefValues; %figure for displaying the different reference values 
            hTables = findobj(hRefValues,'Type','uitable');
            set(hTables,'Data',{})
          for iref = 1:length(RefRows)
            Interval = [Raw{RefRows(iref),3},'-',Raw{RefRows(iref),4}(12:end)]; 
            RefStart = AfkodTid(Raw{RefRows(iref),3});
            RefEnd = AfkodTid(Raw{RefRows(iref),4}); 
            set(hInterval,'String',Interval)
            if ~isempty(Raw{RefRows(iref),5})
               ShiftAxes = CheckBatchString(Raw{RefRows(iref),5});
            end
            Out = RefWindow(S.ID{i},FilThigh,FilHip,FilArm,FilTrunk,StartActi,StopActi,RefStart,RefEnd,SF,RefRows(iref),Icol,ShiftAxes);
            if strcmp(Out,'Cancel'), break, end 
          end
        else
          msgbox(['No reference interval found for ID ',S.ID{i}])
        end
      end
      
      if S.Pause
        if i<length(S.ID), set(hNextID,'Visible','on','Enable','on','Value',0), end
      end
      set(hStop,'Enable','on')
      uiwait(hNowAnalysing)
      
   end
   %.............................................................................................................................
   if S.Analyse
     TableStart = find(strcmp('Type',Raw(:,1)))+1; %row number where interval table starts
     Intervals = Raw(TableStart:end,1:5); %30/1-20: column 5 included for possible shift of accelerometer orientation
     %Editing the Setup file sometimes can put 'NaN' into cells below the last interval line,
     %these lines (which seems empty in Excel) and possible empty text lines must be removed:
     EndInt = size(Intervals,1)+1;
     Endnotfound = true;
     while Endnotfound
        EndInt = EndInt-1; 
        if ischar(Intervals{EndInt,1}) %false for NaNs
           Endnotfound = isempty(deblank(Intervals{EndInt,1}));
        end
     end
     Intervals = Intervals(1:EndInt,:);
     
     [VrefTrunk,VrefArm,VrefHip,VrefThigh] = CalcRef(Intervals,FilTrunk,FilArm,FilThigh,FilHip);
     %if isempty(VrefThigh), errordlg(['Missing reference interval for ', char(S.ID)]), error(' '); end %at least one value for VefThigh must be found
     VrefTrunkMean = nanmedian(VrefTrunk,1);
     VrefHipMean = nanmedian(VrefHip,1);
     VrefArmMean = nanmedian(VrefArm,1);
     VrefThighMean = nanmedian(VrefThigh,1);
     
     
     OnOffManInt = {}; %specification on manual-off-intervals
     OnOffRows = find(strncmp('E.',Raw(:,1),2));
     Code = cell(1,length(OnOffRows));
     if ~isempty(OnOffRows)
        for r=1:length(OnOffRows), Code{r} = Raw{OnOffRows(r),1}(3:6); end
        StartOnOff = AfkodTid(Raw(OnOffRows,3));
        EndOnOff  = AfkodTid(Raw(OnOffRows,4));
        OnOffManInt = cat(2,Code',num2cell([StartOnOff,EndOnOff]));
     end
         
     [ResAkt,ResInc,ResHR,ResHRRdist] = deal([]);
    
     K = false(1,size(Intervals,1));
     for k=1:size(Intervals,1) %find the intervals to analyse
         if any(strcmp(Intervals{k,1}(1:3),IntAbr)), K(k)=true; end
     end
     Int = Intervals(K,:); %Intervals to analyse
     if SETTINGS.SeparatePeriods
        [Int,WorkDay] = Modify2Day(Int); %OBS: Midnight intervals are splitted, WorkDay included (1/4-14) !
     else
         WorkDay = NaN(size(Int,1),1);
     end
     Int34 =cell(size(Int,1),1); %Combined start and end of interval (3. and 4. column of Int merged)
     for k=1:size(Int,1)
         Int34{k,1} = [Int{k,3},'-',Int{k,4}(12:end)];
     end
     set(hInterval,'String',Int34);
     
     j = 1; %Analyseinterval løkke
     while ~get(hStop,'Value') && j<=size(Int,1)
       Ntype = str2double(Int{j,1}(2)); %Ntype: type number of interval (4 == sleep)
       Type = Int{j,1}(1:2); %added 7/12-17: to be used for EVA output
       set(hActivity,'String',Int(j,1));
       set(hInterval,'Value',j);
       drawnow
       h = findobj('Tag','ActiFig'); 
       if ~isempty(h) && S.Pause
         figure(h); text(.4,.5,'Wait . . .','FontSize',14), axis off; drawnow
       end
       Start = AfkodTid(Int{j,3}); 
       Slut = AfkodTid(Int{j,4});
       if ~isempty(Int{j,5}) && ischar(Int{j,5})
           ShiftAxes = CheckBatchString(Int{j,5});
       end
       
       set(hNowAnalysing,'HandleVisibility','off') %to prevent erroneous plotting in the 'NowAnalysing' window 
       [AktTid,IncTid,HR,HRRdist] = AnalyseAndPlot(S.ID{i},FilThigh,FilHip,FilArm,FilTrunk,VrefThighMean,VrefHipMean,VrefTrunkMean,ThresTrunk,ThresArm,...
                               SF,Start,Slut,Ylab,S.Vis,S.PlotMappe,OnOffManInt,Ntype,Tbeat,RR,ActiHeartDelay,HRrest,HRmax,Type,S.Pause,ColHeadAct,ColHeadInc,ShiftAxes);                   
       set(hNowAnalysing,'HandleVisibility','on')

       %Saving:
       if ~isempty(S.GemmeFil)
         ResAkt = cat(1,ResAkt,AktTid);
         ResInc = cat(1,ResInc,IncTid);
         ResHR = cat(1,ResHR,HR);
         ResHRRdist = cat(1,ResHRRdist,HRRdist);
         if all(isnan(HR)), aux = [AktTid,IncTid]; else aux = [AktTid,IncTid,HR,HRRdist]; end
         res = cat(2,Int{j,1:4},WorkDay(j),num2cell(aux)); %WorkDay included 1/4-14
         %Recalculate weekday, if intervals have been edited, weekday maybe not edited accordingly: 
         res{2} = weekday(mean(AfkodTid(res(3:4)))-1); %weekday of midtime, monday = day 1
         Fid = fopen(S.GemmeFil,'a');
         out = cat(2,S.ID{i},res);
         fprintf(Fid,strjoin(ParFormats,','),out{1:end});
         fprintf(Fid,'\r\n');
         fclose(Fid);    
       end
  
       if S.Pause
         if j==1, set(hPrevious,'Visible','off'), else  set(hPrevious,'Visible','on'), end
         if j==size(Int,1), set(hNext,'Visible','off'), else set(hNext,'Visible','on'), end   
         set(hNext,'Enable','on','Value',0)
         set(hPrevious,'Enable','on','Value',0)
         if i<length(S.ID), set(hNextID,'Visible','on','Enable','on','Value',0), end
         set(hStop,'Enable','on')
         uiwait(hNowAnalysing)
         if get(hStop,'Value'), close(hNowAnalysing), return, end
         if get(hNextID,'Value')
             j=1+size(Int,1);
         else
           jInt = get(hInterval,'Value');  
           if j~=jInt, j = jInt; end  
           if get(hNext,'Value'), j=j+1; end
           if get(hPrevious,'Value'), j=j-1; end
         end
         delete(get(findobj('Tag','ActiFig'),'Children'))
         delete(findall(findobj('Tag','ActiFig'),'Tag','HRR%')) %the HRR% axis is hidden
       else
         j=j+1;
       end
       if get(hStop,'Value'), close(hNowAnalysing), return, end

     end
     if ~isempty(S.GemmeFil)
       %Save Reference intervals: 
       Fid = fopen(RefFil,'a');
       for iref = 1:size(VrefThigh,1)
           fprintf(Fid,['%s,',repmat('%5.1f,',1,12),'\r\n'],S.ID{i},180*[VrefTrunk(iref,:),VrefArm(iref,:),VrefHip(iref,:),VrefThigh(iref,:)]/pi);
       end
       fclose(Fid);
     end
   end
   if S.Pause
      if get(hNextID,'Value')
         set(hNextID,'Value',0) 
         i=i+1;
         if i==length(S.ID),set(hNextID,'Visible','off'); end 
      else
         uiwait(hNowAnalysing)
         if get(hStop,'Value'), close(hNowAnalysing), return, end 
      end
   else
      i=i+1;
      if get(hStop,'Value'), close(hNowAnalysing), return, end 
   end
  end
  if exist(S.GemmeFil,'file'), winopen(S.GemmeFil), end
  close(hNowAnalysing)
  fclose('all');
  
%************************************************************************************************************************************
case 'Raw'
    
  delete(findobj('Tag','SelectSingleFiles'));  
  S = SelectSingleFiles;
  if isempty(S), close, return, end %Cancel was selected 
  FilThigh = S.FilThigh;
  FilHip = S.FilHip;
  FilArm = S.FilArm;
  FilTrunk = S.FilTrunk;
  S.Sti = cell(1);
  [StartActi,StopActi] = CheckFiles(FilThigh,FilHip,FilArm,FilTrunk);
  StartActi = ceil(StartActi*86400)/86400; %round to next second, to prevent problem with 'Next' and 'Previous'
  hSelectSingleFiles = findobj('Tag','SelectSingleFiles');
  set(findobj(hSelectSingleFiles,'Tag','StartActi'),'String',datestr(StartActi,'dd/mm/yyyy/HH:MM'))
  set(findobj(hSelectSingleFiles,'Tag','StopActi'),'String',datestr(StopActi,'dd/mm/yyyy/HH:MM'))
  drawnow
  
  if isempty(FilTrunk) && isempty(FilArm)
      Plot24 = 2; Pos = [.02 .25 .5 .65]; 
  else
      Plot24 = 4; Pos = [.02 .25 .85 .65]; 
  end
  
  hActiRaw = findobj('Tag','ActiRaw');
  if isempty(hActiRaw)
     hActiRaw = figure('Units','Normalized','PaperPosition',[.5 2.5 20 20],'Position',Pos,'Tag','ActiRaw','Toolbar','Figure');
     set(zoom,'ActionPostCallback',@UpdateZoom);
  else
     figure(hActiRaw);
     delete(findobj('-regexp','Tag','DateTick'))
  end

  Datoer = cellstr(datestr(fix(StartActi):fix(StopActi),'dd/mm/yyyy'));
  Start = StartActi;
  Step = 1/24;
  Slut = min([Start + Step,StopActi]);
  hStartDate = uicontrol('Style','List','String',Datoer,'Units','Characters','Position',[5 1 18 2.5],'FontSize',10);
  hStartTime = uicontrol('Style','Edit','String',datestr(Start,'HH:MM:SS'),'Units','Characters','Position',[7.5 4 11 1.5],'FontSize',10);
  hStep = uicontrol('Style','Edit','String',1,'Units','Characters','Position',[30 1 5 2],'FontSize',10);
  uicontrol('Style','Text','String','hours','Units','Characters','Position',[35 .5 7 2.2],'BackgroundColor',[.8 .8 .8],'FontSize',10);
  hNext = uicontrol('Style','Togglebutton','String','Next','Callback','uiresume','Units','Normalized','Position',[.6 .02 .085 .04],'FontSize',10);
  hPrevious = uicontrol('Style','Togglebutton','String','Previous','Callback','uiresume','Units','Normalized','Position',[.75 .02 .085 .04],'FontSize',10);
  hExit = uicontrol('Style','ToggleButton','String','Exit','Callback','uiresume','Units','Normalized','Position',[.9 .02 .085 .04],'FontSize',10);
  
  set(hPrevious,'Visible','off')
  if StopActi-Start<1/24, set(hNext,'Visible','off'), end % if length of data < 1 hour
  OldStart = Start;
  OldStep = Step;
  while ~get(hExit,'value')
 
     if ~isempty(FilThigh)
          switch Plot24
              case 2, SubPos = [.1,.12 ,.4,.25;.1,.41,.4,.25;.1,.7 ,.4,.25]; 
              case 4, SubPos = [.05,.12,.21,.25;.05,.41,.21,.25;.05,.7,.21,.25]; 
          end
          RawPlot(FilThigh,Start,Slut,SubPos)
      end
      if ~isempty(FilHip)
          switch Plot24
             case 2, SubPos = [.55,.12 ,.4,.25;.55,.41,.4,.25;.55,.7,.4,.25]; 
             case 4, SubPos = [.29,.12,.21,.25;.29,.41,.21,.25;.29,.7,.21,.25]; 
          end
          RawPlot(FilHip,Start,Slut,SubPos)
      end
      if ~isempty(FilArm)
          SubPos = [.53,.12,.21,.25;.53,.41,.21,.25;.53,.7,.21,.25]; 
          RawPlot(FilArm,Start,Slut,SubPos)   
      end
      if ~isempty(FilTrunk)
          SubPos = [.77,.12,.21,.25;.77,.41,.21,.25;.77,.7,.21,.25]; 
          RawPlot(FilTrunk,Start,Slut,SubPos) 
      end
            
      uiwait(hActiRaw)
      if get(hExit,'value'), close, close(hSelectSingleFiles), return, end
      Start = datenum(Datoer(get(hStartDate,'Value')),'dd/mm/yyyy') + rem(datenum(get(hStartTime,'String')),1);
      Step = str2double(get(hStep,'String'))/24;
      if all([abs(Start-OldStart)<10^-5,abs(Step-OldStep)<10^-5])%Start and Step not changed: proceed to right or left
         if get(hNext,'Value')
            Start = Slut;
            Slut = min([Start + Step,StopActi]);
         end
         if get(hPrevious,'Value')
            Slut = Start;
            Start = max([Slut - Step,StartActi]);
         end
         set(hStartDate,'Value',find(strcmp(datestr(Start,'dd/mm/yyyy'),Datoer)))
         set(hStartTime,'String',datestr(Start,'HH:MM:SS'))
      else %Use new values for Start and/or Step 
         Slut = min([Start + Step,StopActi]); 
      end
      set(hNext,'Value',0)
      set(hPrevious,'Value',0)
      OldStart = Start;
      OldStep = Step;
      if Slut==StopActi, set(hNext,'Visible','off'), else set(hNext,'Visible','on'), end
      if Start==StartActi, set(hPrevious,'Visible','off'), else set(hPrevious,'Visible','on'), end
  end
  close(hActiRaw)
  close(hSelectSingleFiles)
  
%************************************************************************************************************************************
case 'Inclinometer'
    
  delete(findobj('Tag','SelectSingleFiles'));  
  S = SelectSingleFiles;
  if isempty(S), close, return, end %Cancel was selected 
  FilThigh = S.FilThigh;
  FilHip = S.FilHip;
  FilArm = S.FilArm;
  FilTrunk = S.FilTrunk;
  S.Sti = cell(1);
  [StartActi,StopActi,SF] = CheckFiles(FilThigh,FilHip,FilArm,FilTrunk);
  StartActi = ceil(StartActi*86400)/86400; %round to next second, to prevent problem with 'Next' and 'Previous'
  hSelectSingleFiles = findobj('Tag','SelectSingleFiles');
  set(findobj(hSelectSingleFiles,'Tag','StartActi'),'String',datestr(StartActi,'dd/mm/yyyy/HH:MM'))
  set(findobj(hSelectSingleFiles,'Tag','StopActi'),'String',datestr(StopActi,'dd/mm/yyyy/HH:MM'))
  drawnow
  
  if isempty(FilTrunk) && isempty(FilArm), Plot24 = 2; else Plot24 = 4; end
  Pos = [.02 .05 .5 .85];
  hActiRaw = findobj('Tag','ActiRaw');
  if isempty(hActiRaw)
     hActiRaw = figure('Units','Normalized','PaperPosition',[.5 2.5 20 20],'Position',Pos,'Tag','ActiRaw','Toolbar','Figure');
     set(zoom,'ActionPostCallback',@UpdateZoom);
  else
     figure(hActiRaw);
     delete(findobj('-regexp','Tag','DateTick'))
  end

  Datoer = cellstr(datestr(fix(StartActi):fix(StopActi),'dd/mm/yyyy'));
  Start = StartActi;
  Step = 1/24;
  Slut = min([Start + Step,StopActi]);
  hStartDate = uicontrol('Style','List','String',Datoer,'Units','Characters','Position',[5 1 18 2.5],'FontSize',10);
  hStartTime = uicontrol('Style','Edit','String',datestr(Start,'HH:MM:SS'),'Units','Characters','Position',[7.5 4 11 1.5],'FontSize',10);
  hStep = uicontrol('Style','Edit','String',1,'Units','Characters','Position',[30 1 5 2],'FontSize',10);
  uicontrol('Style','Text','String','hours','Units','Characters','Position',[35 .5 7 2.2],'BackgroundColor',[.8 .8 .8],'FontSize',10);
  hNext = uicontrol('Style','Togglebutton','String','Next','Callback','uiresume','Units','Normalized','Position',[.6 .02 .085 .04],'FontSize',10);
  hPrevious = uicontrol('Style','Togglebutton','String','Previous','Callback','uiresume','Units','Normalized','Position',[.75 .02 .085 .04],'FontSize',10);
  hExit = uicontrol('Style','ToggleButton','String','Exit','Callback','uiresume','Units','Normalized','Position',[.9 .02 .085 .04],'FontSize',10);
  
  set(hPrevious,'Visible','off')
  if StopActi-Start<1/24, set(hNext,'Visible','off'), end % if length of data < 1 hour
  OldStart = Start;
  OldStep = Step;
  while ~get(hExit,'value')
 
      if ~isempty(FilThigh)
          switch Plot24
              case 2, subplot(3,1,2) 
              case 4, subplot(5,1,4)
          end
          InclinometerPlot(FilThigh,Start,Slut,SF)
      end
      if ~isempty(FilHip)
          switch Plot24
              case 2, subplot(3,1,1) 
              case 4, subplot(5,1,3)
          end
          InclinometerPlot(FilHip,Start,Slut,SF)
      end
      if ~isempty(FilArm)
          subplot(5,1,2) 
          InclinometerPlot(FilArm,Start,Slut,SF)
      end
      if ~isempty(FilTrunk)
          subplot(5,1,1) 
          InclinometerPlot(FilTrunk,Start,Slut,SF)
      end
      subplot(5,1,5), plot(0,[0,0,0]), axis off
      legend('Inc','U','V','Location','North','Orientation','Horizontal')

      
      uiwait(hActiRaw)
      if get(hExit,'value'), close, close(hSelectSingleFiles), return, end
      Start = datenum(Datoer(get(hStartDate,'Value')),'dd/mm/yyyy') + rem(datenum(get(hStartTime,'String')),1);
      Step = str2double(get(hStep,'String'))/24;
      if all([abs(Start-OldStart)<10^-5,abs(Step-OldStep)<10^-5])%Start and Step not changed: proceed to right or left
         if get(hNext,'Value')
            Start = Slut;
            Slut = min([Start + Step,StopActi]);
         end
         if get(hPrevious,'Value')
            Slut = Start;
            Start = max([Slut - Step,StartActi]);
         end
         set(hStartDate,'Value',find(strcmp(datestr(Start,'dd/mm/yyyy'),Datoer)))
         set(hStartTime,'String',datestr(Start,'HH:MM:SS'))
      else %Use new values for Start and/or Step 
         Slut = min([Start + Step,StopActi]); 
      end
      set(hNext,'Value',0)
      set(hPrevious,'Value',0)
      OldStart = Start;
      OldStep = Step;
      if Slut==StopActi, set(hNext,'Visible','off'), else set(hNext,'Visible','on'), end
      if Start==StartActi, set(hPrevious,'Visible','off'), else set(hPrevious,'Visible','on'), end
  end
  close(hActiRaw)
  close(hSelectSingleFiles)
   
%***********************************************************************************************************************************
case 'Info'
 
  [Filnavne,Mappe] = uigetfile('*.gt3x;*.act4','Select one or more Actigraph data files','MultiSelect','on');
  if isnumeric(Filnavne), return, end %Cancel
  cd(Mappe)
  if ~iscell(Filnavne), Filnavne = {Filnavne}; end %only one selected
  Data = cell(length(Filnavne),7);
  for i=1:length(Filnavne)
      File = [Mappe,Filnavne{i}];
      [~,~,Exten] = fileparts(File);
      %Version 6 gt3x files are disregarded and marked as ERR 
      if strcmpi(Exten,'.act4') || CheckIfVersion5(File,0)
         if strcmp(Exten,'.act4')
            [SN,SF,Start,End,~,~,~,~,Ver] = ACT4info(File); 
         else
            [SN,SF,Start,End] = AGinfo(File); %for old gt3x files
            Ver = '';
         end
         Time = [num2str(fix(End-Start)),':',  datestr(rem(End-Start,1),'HH:MM:SS')]; %duration
         StopTxt = datestr(End);
         Data(i,:) = {Filnavne{i}(1:end-5),[Exten(2:end),'/',num2str(Ver)],datestr(Start),StopTxt,Time,int2str(SF),SN};
      else
         Data(i,1:2) = {Filnavne{i}(1:end-5),'ERR'};
      end
  end 
  Cnames = {'Filename','Type','Start','Stop','D:HH:MM:SS','Hz', 'Serial No.'}; %,'dT (s)'};
  Cformat = {'char','char','char','char','char','numeric','char','numeric'};
  hTableFig = figure('NumberTitle','off','Name','File info');
  Mitems = findall(gcf,'type','uimenu');
  delete(findobj(Mitems,'Tag','figMenuHelp','-or','Tag','figMenuWindow','-or','Tag','figMenuDesktop','-or','Tag','figMenuTools',...
                       '-or','Tag','figMenuInsert','-or','Tag','figMenuView','-or','Tag','figMenuEdit',...  
                       '-or','Tag','figMenuFilePrintPreview','-or','Tag','figMenuFileExportSetup','-or','Tag','figMenuFilePreferences',...
                       '-or','Tag','figMenuFileSaveWorkspaceAs','-or','Tag','figMenuFileImportData','-or','Tag','figMenuGenerateCode',...
                       '-or','Tag','figMenuFileSave','-or','Tag','figMenuUpdateFileNew','-or','Tag','figMenuFileExitMatlab'))
                   
  hTable = uitable('Data',Data,...
                   'ColumnName',Cformat,'ColumnName',Cnames,'ColumnWidth',{230 75 140 140 100 30 105});
  Ext = get(hTable,'Extent');
  set(hTableFig,'Position',[100,200,Ext(3)+20,min([Ext(4)+5,700]+25)])
  Yext = min([Ext(4),700]);
  set(hTable,'Position', [0 0 Ext(3)+20 Yext])
  uicontrol('Style','PushButton','Callback',{@TableSort,hTable,1},'Position',[140 Yext+5 15 15]);
  uicontrol('Style','PushButton','Callback',{@TableSort,hTable,2},'Position',[275 Yext+5 15 15]);
  uicontrol('Style','PushButton','Callback',{@TableSort,hTable,3},'Position',[365 Yext+5 15 15]);
  uicontrol('Style','PushButton','Callback',{@TableSort,hTable,4},'Position',[505 Yext+5 15 15]);
  uicontrol('Style','PushButton','Callback',{@TableSort,hTable,5},'Position',[645 Yext+5 15 15]);
  uicontrol('Style','PushButton','Callback',{@TableSort,hTable,6},'Position',[770 Yext+5 15 15]);
  uicontrol('Style','PushButton','Callback',{@TableSort,hTable,8},'Position',[900 Yext+5 15 15]);
  

%************************************************************************************************************************************
case 'IntervalSetup'
  S = SetupSelect;
  if isempty(S), return, end %Cancel was selected 
 
  try
    Excel = actxGetRunningServer('Excel.Application'); %if Excel setup-fil already is open from previous 'IntervalSetup' session
   % set(Excel, 'Visible', 1); %?
    if strcmp(get(Excel.ActiveWorkBook,'FullName'),S.ExportFile)
      WB = Excel.ActiveWorkbook;
    else
     WB = Excel.Workbooks.Open(S.ExportFile);   
    end
  catch
    Excel = actxserver('Excel.Application');
    set(Excel, 'Visible', 1);
    WB = Excel.Workbooks.Open(S.ExportFile);
  end
  
  LastOne = 0;
  for i=1:length(S.Filnavne)
    if i == length(S.Filnavne), LastOne = 1; end
    R = IntervalSetup({S.AGmappe,S.Filnavne{i},S.ExportFile,S.AHfiles{i},WB,LastOne});
    if isempty(R),return, end
  end 
 
end %switch
%********************************************************************************************************************************
%End of switch structure, the rest is supporting functions:

function RawPlot(Fil,Start,Slut,SubPos)
   [Acc,SF] = ReadAG(Fil,Start,Slut);
   T = Start + (0:length(Acc)-1)/SF/86400;
   T = T - fix(T(1));
  subplot('Position',SubPos(3,:))
   plot(T,Acc(:,3))
   axis tight
   datetick('x','HH:MM','keeplimits')
   set(gca,'Tag','DateTick') %for use in @UpdateZoom
   if SubPos(3,1)<.15, ylabel('Z (G)'), end
   %if SubPos(3,2)>.2, set(gca,'Xtick',[]),end
   [~,FileName] = fileparts(Fil);
   title(FileName,'Interpreter','none')
  subplot('Position',SubPos(2,:))
   plot(T,Acc(:,2))
   axis tight
   datetick('x','HH:MM','keeplimits')
   set(gca,'Tag','DateTick') %for use in @UpdateZoom
   if SubPos(2,1)<.15, ylabel('Y (G)'), end
   %if SubPos(2,2)>.2, set(gca,'Xtick',[]), end
  subplot('Position',SubPos(1,:))
   plot(T,Acc(:,1))
   axis tight
   datetick('x','HH:MM','keeplimits')
   set(gca,'Tag','DateTick') %for use in @UpdateZoom
   if SubPos(1,1)<.15, ylabel('X (G)'), end
   %if SubPos(1,2)>.2, set(gca,'Xtick',[]), end
    
%************************************************************************************************************************************
function InclinometerPlot(Fil,Start,Slut,SF)
   V = 180*Vinkler(Fil,Start,Slut,0)/pi; %17/2-20: 0 tilføjet
   T = Start + (0:length(V)-1)/SF/86400;
   T = T - fix(T(1));
   plot(T,V)
   axis tight
   datetick('x','HH:MM','keeplimits')
   set(gca,'Tag','DateTick')
   ylabel('Angles (°)')
   [~,FileName] = fileparts(Fil);
   title(FileName,'Interpreter','none')
   
%*******************************************************************************************************************************

function Out = RefWindow(ID,FilThigh,FilHip,FilArm,FilTrunk,StartActi,StopActi,RefStart,RefEnd,SF,Irow,Icol,ShiftAxes)
%Reading of acceleration data from specified reference interval (± 10 minutes) for viewing/editing by the function 'Reference' 
 
% ID: Running number of subject (ID = name of worksheet in setup file)
% FilThigh, FilHip, FilArm, FilTrunk: Full file names of AG thigh, hip, arm and trunk
% StartActi: Start time of AG recording (datenum)
% StopActi: Stop time of AG recording (datenum)
% Refstart: Start time of reference interval (datenum)
% Refstop: Stop time of reference interval (datenum)
% SF: sample frequency
% Irow: Row number for reference data in setup file (ID worksheet)
% Icol: Column number for reference data in setup file (ID worksheet)

% Output is the string 'Next' or 'Cancel'

    Start = max(StartActi,RefStart-10/60/24);
    Slut = min([RefEnd+10/60/24,StopActi]);
    Start = ceil(Start*86400)/86400;
    Slut = fix(Slut*86400)/86400;
    N = round((Slut-Start)*86400*SF);
    [Vthigh,Vhip,Varm,Vtrunk] = deal(NaN(N,3));
    if ~isempty(FilThigh), Vthigh = Vinkler(FilThigh,Start,Slut,ShiftAxes(1)); end 
    if ~isempty(FilHip), Vhip = Vinkler(FilHip,Start,Slut,ShiftAxes(2)); end 
    if ~isempty(FilArm), Varm = Vinkler(FilArm,Start,Slut,ShiftAxes(3)); end 
    if ~isempty(FilTrunk), Vtrunk = Vinkler(FilTrunk,Start,Slut,ShiftAxes(4)); end %else error('Trunk file not found'), end
    T = Start + (0:N-1)/SF/86400;
    Iref = find(RefStart<T & T<RefEnd);
    V = struct('Thigh',(180/pi)*Vthigh,'Hip',(180/pi)*Vhip,'Arm',(180/pi)*Varm,'Trunk',(180/pi)*Vtrunk);
    Out = Reference({ID,FilTrunk,RefStart,RefEnd,Iref,T,Irow,Icol,V,FilThigh});
    delete(findall(0,'Tag','Reference'))
     
%************************************************************************************************************************************  

function TableSort(~,~,hTable,Col)
    %Sorting af data according to selected column in the 'File Info' table
    
    Data = get(hTable,'Data');
    if issorted(Data(:,Col)) %if data is already sorted, display them in reverse order
        Ind = size(Data,1):-1:1;
    else
       [~,Ind] = sort(Data(:,Col)); 
    end
    set(hTable,'Data',Data(Ind,:))
%********************************************************************************************************************************    

         

       
       
     