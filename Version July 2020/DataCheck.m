function DataCheck

% Visualizing of outliers in output file from Batch run.
%
%Funktion til visualisering af outliers i output fra batch beregninger, kaldes fra 'Outlier check' i Acti4's hovedmenu.
%Der vælges en output fil (RES) med data fra en batch kørsel og den tilhørende Setup-fil.
%Et vindue præsenteres med 3 listboxe/grupper af outputparametre samt knapper for valg af intervaltyper (A1,A2...)
%Gruppe 1 parametrene er parametre med enheden timer (h), gruppe 2 er %antalsparametre uden enhed og gruppe 3 er
%parametre med enhed grader, procent eller BPM.
%Parametrene i gruppe 1 omregnes til procent af intervallernes måletid, i gruppe 2 skaleres antallet til en standard 
%varighed på 8 timer og i gruppe 3 sker ingen skalering. For hver valgt parameter/intervaltype foretages en 
%outlierberegning baseret på 'Tukeys fence' med afstandsparameter på hhv. 1.5 (blå) og 3 (rød). 
%Der kan vises detaljer for hver parameter/intervaltype ved at klikke på de enkelte 'bars' og derefter markere enkelte
%intervaller.  

delete(findobj('Tag','DataPlot'))
delete(findobj('Tag','Tabel'))
delete(findobj('Tag','OutlierPlot'))

[Navn,Sti] = uigetfile('*.txt','Select interval output file from final batch run');
if isnumeric(Navn), return, end
Fil = fullfile(Sti,Navn);
cd(Sti);
[Snavn,Ssti] = uigetfile({'*.xls;*.xlsx'},'Select the corrsponding Setup-file');
if isnumeric(Snavn), return, end
Sfil = fullfile(Ssti,Snavn);
[~,Txt] = xlsread(Sfil,'Info');
 AGmappe = Txt{1,2}; 
 AHmappe = Txt{2,2};

Fid = fopen(Fil);
ResColNames = textscan(fgetl(Fid),'%s','delimiter',','); %variabelnavne i resutatfil
ResColNames = ResColNames{1}';

%Læs kolonnenavne og formater fra ParameterList.xlsx:
[~,~,R] = xlsread(fullfile(fileparts(which('Acti4')),'ParameterList.xlsx'),'List');
c = cellfun(@ischar,R(1:5,:)); %Første 5 rækker indeholder (på skift) kolonnenavnene 
ListColNames = [R(1,c(1,:)),R(2,c(2,:)),R(3,c(3,:)),R(4,c(4,:)),R(5,c(5,:))];

%Indlæsningsformat bestemmes for de ResColNames, der findes i ListColNames: 
Formats = cell(length(ResColNames),1);
for i=1:length(ResColNames)
    j = find(strcmp(ResColNames(i),ListColNames));
    if isempty(j)
       Formats{i} = '%*f'; %findes ikke i ListColNames og skal overspringes ved indlæsning
       ResColNames{i} = 'Fjernes';
    else
       Formats{i} = R{8,j};
    end
end

ResColNames = ResColNames(~strcmp('Fjernes',ResColNames)); %ResColNames opdateres til match med Raw

Formats = strrep(Formats,'%d','%f'); %for at kunne læse  NaNs (%d giver 0 for NaN) 
Raw = textscan(Fid, cell2mat(Formats'),'delimiter',','); %data fra evt. udgåede parametre overspringes 
fclose(Fid);

%Nu findes prametre hvor alle værdier er NaN, de skal så udelades (fx. ved intet armaccelerometer)
for i=1:length(Raw)
    if isnumeric(Raw{i})
       if all(isnan(Raw{i}))
          ResColNames{i} = 'Fjernes';
       end
    end
end
Raw = Raw(~strcmp('Fjernes',ResColNames)); %Raw, tomme (NaN) kolonner fjernes
ResColNames = ResColNames(~strcmp('Fjernes',ResColNames)); %ResColNames opdateres til match med Raw

%Opstilling af liste over parametre der kan vælges blandt:
ExcludeNames = {'LbNr','Type','Weekday','Start','Stop','Workday','Time','AHTime','NBeat','NBeatErr'}; %Indgår ikke.
ParNames = setdiff(ResColNames,ExcludeNames,'stable'); %De parametre der nu kan vælges blandt.

ParName{2} = {'Steps';'Sit_N30min';'NriseSit';'SitLie_N30min';'NriseSitLie'}; %antalsparametre (uden enhed)
aux = Par3Grp;
ParName{3} = ParNames(ismember(ParNames,aux(:,1)))'; %'gennemsnitsparametre', enhed grader, procent eller BPM
ParName{1} = setdiff(ParNames,cat(1,ParName{2},ParName{3}),'stable')'; %parametre med enhed timer

%Valg af parametre/intervaltyper
Out = OutlierParSelection(ParName); %{parametergruppe, valgte parametre, valgte intervaltyper}
close(gcf)
if isempty(Out), return, end
Grp = find(~cellfun(@isempty,Out(1:3))); %den parametergruppe der er valgt fra
Par = ParName{Grp}(Out{Grp}); %de valgte parametre
IntTypes = {'A1','A2','A3','A4','C0','C4','B1','B2','B3','B4','D'};
Int = IntTypes(find(Out{4})); %de valgte intervaltyper
     
Type = Raw{:,strcmp('Type',ResColNames)};
LbNr = Raw{:,strcmp('LbNr',ResColNames)};
Time = Raw{:,strcmp('Time',ResColNames)};
ThighOff = Raw{strcmp('ThighOff',ResColNames)};
Start = Raw{:,strcmp('Start',ResColNames)};
Stop = Raw{:,strcmp('Stop',ResColNames)};

OutPct = zeros(length(Int),length(Par),2);
akt = cell(length(Int),length(Par)); % parameterværdier
aktnorm = cell(length(Int),length(Par)); %skalerede parameterværdier (for gruppe 1 og 2, for gruppe 3 er akt=aktnorm)
for i=1:length(Int)
    int = find(strncmp(Int{i},Type,2)); %index for den aktuelle intervaltype 
    tid{i} = Time(int) - ThighOff(int); %reelle måletid
    lbnr{i} = LbNr(int);
    start{i} = Start(int);
    stop{i} = Stop(int);
    %Skalering for gruppe 1 og 2:
    for j=1:length(Par);  
        akt{i,j} = double(Raw{:,strcmp(Par(j),ResColNames)}(int));
        if Grp==1
           aktnorm{i,j} = 100*akt{i,j}./tid{i}; %procent skalering
        end  
        if Grp==2
           aktnorm{i,j} = 8*double(akt{i,j})./tid{i}; %skalering til antal pr. 8 timer
        end
        if Grp==3
           aktnorm{i,j} = akt{i,j}; %ingen skalering
        end
        Q12 = quantile(aktnorm{i,j},[.25,.75]);
        ii15 = aktnorm{i,j} < Q12(1)-1.5*diff(Q12) |  Q12(2)+1.5*diff(Q12) < aktnorm{i,j}; %Outlier, Tukey´s fence, faktor 1.5
        ii30 = aktnorm{i,j} < Q12(1)-3*diff(Q12) |  Q12(2)+3*diff(Q12) < aktnorm{i,j}; %Ekstrem outlier, Tukey´s fence, faktor 3.0
        %procentvise andel der er outlier/ekstrem outlier for de valgte parameter/intervaltyper:
        OutPct(i,j,1) = 100*sum(ii15)/length(aktnorm{i,j});
        OutPct(i,j,2) = 100*sum(ii30)/length(aktnorm{i,j});  
     end
end

H = figure('Units','Normalized','Position',[.645,.5,.335,.4],'Tag','OutlierPlot');
for i=1:length(Int)
    Sub(i) = subplot(length(Int),1,i); %et subplot for hver intervaltype
    bar(zeros(1,length(Par))) %først tomt plot for at sætte 'XtickLabels'
    if i==length(Int)
       set(gca,'XtickLabel',Par)
    else
       set(gca,'XtickLabel','') 
    end
    ylabel([Int{i},'(%)'])
    hold on
    for j=1:length(Par) %hvert 'Bar' plottes enkeltvis for at kunne tilordne 'ButtonDownFcn' selektivt til hver 'Bar' 
        bar(j,squeeze(OutPct(i,j,1)),'k','ButtonDownFcn',@VisBarData,'UserData',[i,j]);
        bar(j,squeeze(OutPct(i,j,2)),.5,'r','ButtonDownFcn',@VisBarData,'UserData',[i,j]);
    end
 end   
guidata(H,{Grp,Par,Int,akt,aktnorm,lbnr,start,stop,Sfil,AGmappe,AHmappe});
 

function VisBarData(h,~) 
% Viser et plot med data fra en enkelt 'Bar' samt en tabel med detaljer for
% outliers, kaldes ved ButtonDown på en 'Bar'
ij = get(h,'UserData');
i = ij(1); %nummer på intervaltype
j = ij(2); %nummer på parameter 
D = guidata(gcbf);
[Grp,Par,Int,akt,aktnorm,lbnr,start,stop,Sfil,AGmappe,AHmappe] = D{:};
%nu kun data for det valgte interval og parameter
akt = akt{i,j};
aktnorm = aktnorm{i,j};
lbnr = lbnr{i};
start = start{i};
stop = stop{i};
%Bestemmer outliers (kunne også have været gemt ovenfor):
Q12 = prctile(aktnorm,[25,75]);
iQ12 = find(Q12(1) <= aktnorm &  aktnorm <= Q12(2)); %inter-kvartil data
i15 = aktnorm < Q12(1)-1.5*diff(Q12) |  Q12(2)+1.5*diff(Q12) < aktnorm; %outlier, Tukey´s fence med faktor 1.5
i30 = aktnorm < Q12(1)-3*diff(Q12) |  Q12(2)+3*diff(Q12) < aktnorm; %ekstrem outlier, Tukey´s fence med faktor 3.0

%Plot af alle data for valgt interval/parameter:
h = findobj('Tag','DataPlot');
if isempty(h)
   figure('Units','Normalized','Position',[.645,.1,.12,.3],'Tag','DataPlot');
else
    figure(h), cla
end
plot(ones(size(aktnorm)),aktnorm,'o'); %alle værdier plottes først med 'o' (blå)
if Grp==1, ylabel('Percent'), end
if Grp==2, set(gca,'Position',[0.4 0.1 0.4 0.7]), ylabel('N per 8 hour'), end
if Grp==3
   Par3 = Par3Grp;
   YText = Par3{strcmp(Par{j},Par3(:,1)),2};
   ylabel(YText)
end
hold on
plot(ones(size(aktnorm(iQ12))),aktnorm(iQ12),'og') %interkvartil værdier gøres grønne
plot(ones(size(aktnorm(i15))),aktnorm(i15),'ok') % milde outliers gøres sorte
plot(ones(size(aktnorm(i30))),aktnorm(i30),'or') % ekstreme outliers gøres røde
set(gca,'XTickLabel',{' '})
title({'Data for activity';['"',Par{j},'"'];['in ',num2str(length(aktnorm)),' ',Int{i},' intervals'];''},'Interpreter','none')

%Opstilling af tabel med værdi for outlier (skaleret og værdi), LbNr og starttidspunkt for interval:
IDoutl = cat(2,num2cell([aktnorm(i15),akt(i15)]),lbnr(i15),start(i15),stop(i15));
[~,iisort] = sort(aktnorm(i15),1,'descend');
IDoutl = IDoutl(iisort,:);

IDoutl(:,1) = cellfun(@(x) num2str(x,'%5.1f'),IDoutl(:,1),'UniformOutput',false); %afrundinger
IDoutl(:,2) = cellfun(@(x) num2str(x,'%4.2f'),IDoutl(:,2),'UniformOutput',false);

Htabel = findobj('Tag','Tabel');
if isempty(Htabel)
   Htabel = figure('NumberTitle','off','Toolbar','auto','Units','Normalized','Position',[.77,.1,.19,.3],'Tag','Tabel');
else
   figure(Htabel)
end
uicontrol('Units','Normalized','Position',[.07,.925,.85,.06],'Style','text','FontSize',10,...
          'String',['Outliers for activity "',Par{j},'" in ',Int{i},' intervals'],'BackgroundColor',[.8 .8 .8])
if Grp==1 %første kolonne er procentværdier
   uitable('Units','Normalized','Position',[.07,.1,.9,.8],'Data',IDoutl(:,1:4),'RowName',[],...
           'ColumnName',{'Pct','Hours','ID','Start time'},'ColumnWidth',{35,50,50,130},...
           'ColumnFormat',{'char','char','char','char'},'FontSize',9,'CellSelectionCallback',@VisPlot,...
           'TooltipString','Click any cell to show raw data');
end
if Grp==2 % første kolonne er værdier skaleret til 8 timer
   IDoutl(:,1) = cellfun(@(x) x(1:end-2),IDoutl(:,1),'UniformOutput',false);
   IDoutl(:,2) = cellfun(@(x) x(1:end-3),IDoutl(:,2),'UniformOutput',false);
   uitable('Units','Normalized','Position',[.07,.1,.85,.8],'Data',IDoutl(:,1:4),'RowName',[],...
           'ColumnName',{'N/8h','N','ID','Start time'},'ColumnWidth',{40,50,50,130},...
           'ColumnFormat',{'char','char','char','char'},'FontSize',9,'CellSelectionCallback',@VisPlot,...
           'TooltipString','Click any cell to show raw data');
end
if Grp==3 %værdier, ingen skalering
   uitable('Units','Normalized','Position',[.07,.1,.85,.8],'Data',IDoutl(:,[1 3 4]),'RowName',[],...
           'ColumnName',{YText,'ID','Start time'},'ColumnWidth',{40,50,130},...
           'ColumnFormat',{'char','char','char'},'FontSize',9,'CellSelectionCallback',@VisPlot,...
           'TooltipString','Click any cell to show raw data');
end
    
guidata(Htabel,{IDoutl,Sfil,AGmappe,AHmappe});


function VisPlot(~,Ind)
%Dette er 'CellSelectionCallback' funktionen fra tabellen ovenfor som
%aktiver et plot af rådata for et interval i tabellen 
OutlInfo = guidata(gcbf);
[IDoutl,Sfil,AGmappe,AHmappe] = OutlInfo{:};  
ID = IDoutl{Ind.Indices(1),3};
[~,~,Sraw] = xlsread(Sfil,ID); 

FilThigh = fullfile(AGmappe,Sraw{strcmp('Thigh',Sraw(:,1)),2});
FilThigh = Ver5to6ext('AG',FilThigh);  %old setup-files: gt3x extension added, for at gamle BAuA og 3F data skal kunne læses 
FilHip = fullfile(AGmappe,Sraw{strcmp('Hip',Sraw(:,1)),2});
FilHip = Ver5to6ext('AG',FilHip);
if ~any(strcmp('Hip',Sraw(:,1))),FilHip = ''; end  
FilArm = fullfile(AGmappe,Sraw{strcmp('Arm',Sraw(:,1)),2});
FilArm = Ver5to6ext('AG',FilArm);
if ~any(strcmp('Arm',Sraw(:,1))),FilArm = ''; end
FilTrunk = fullfile(AGmappe,Sraw{strcmp('Trunk',Sraw(:,1)),2});
FilTrunk = Ver5to6ext('AG',FilTrunk);
if ~any(strcmp('Trunk',Sraw(:,1))),FilTrunk = ''; end  
[~,~,SF] = CheckFiles(FilThigh,FilHip,FilArm,FilTrunk);
FileNameActiHeart = Sraw{strcmp('ActiHeart',Sraw(:,1)),2};
if isnumeric(FileNameActiHeart)
   FilAH = fullfile(AHmappe,[num2str(FileNameActiHeart),'.mat']); %i tilfælde af gamle BAuA eller 3F data
else
   FilAH = fullfile(AHmappe,FileNameActiHeart);
end 
     
Start = AfkodTid(IDoutl{Ind.Indices(1),4});
Slut = AfkodTid(IDoutl{Ind.Indices(1),5}); 
  
TableStart = find(strcmp('Type',Sraw(:,1)))+1; %row number where interval table starts
Intervals = Sraw(TableStart:end,1:4);  
[VrefTrunk,~,~,VrefThigh] = CalcRef(Intervals,FilTrunk,FilArm,FilThigh,FilHip);
%Medianværdier af referrencer:
VrefTrunk = nanmedian(VrefTrunk,1);
VrefThigh = nanmedian(VrefThigh,1);

[Tbeat,RR] = deal([]);
if ~isempty(FilAH), load(FilAH,'Tbeat','RR'), end

Ylab = {{'off';'lie';'sit';'stand';'move';'walk';'run';'stairs';'cycle';'row'},...
       {'off';'lie/sit';'lie/sit';'stand';'move';'walk';'run';'stairs';'cycle';'row'}};
ThresArm = [30,60,90,120,150]; %Levels for analysis of arm inclination 
ThresTrunk = [20,30,60,90]; %Levels for analysis of forward trunk inclination
  
AnalyseAndPlot(ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,[],VrefTrunk,ThresTrunk,ThresArm,SF,Start,Slut,Ylab,1,[],[],[],Tbeat,RR);

%Finder de egentlige måleintervaller {'A','B','C','D'}:
Intervals = Intervals(ismember(cellfun(@(x) x(1),Intervals(:,1),'UniformOutput',false) , {'A','B','C','D'}),:); %Ref/sync intervaller fjernes
IntNr = find(strcmp(Intervals(:,3), IDoutl(Ind.Indices(1),4)) | strcmp(Intervals(:,4), IDoutl(Ind.Indices(1),5)),1); %finder det aktuelle intervalnr
%Knapper til til visning af næste/forrige interval:
uicontrol('Style','Togglebutton','String','Next','Callback',@NextPreviousCallBack,'Units','Characters','Position',[50 .7 12 2.2],'FontSize',10);
uicontrol('Style','Togglebutton','String','Previous','Callback',@NextPreviousCallBack,'Units','Characters','Position',[75 .7 12 2.2],'FontSize',10);
  
guidata(gcf,{ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,VrefTrunk,ThresTrunk,ThresArm,SF,Ylab,Tbeat,RR,Intervals,IntNr})  
  
function NextPreviousCallBack(~,~)
D = guidata(gcbo);
[ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,VrefTrunk,ThresTrunk,ThresArm,SF,Ylab,Tbeat,RR,Intervals,IntNr] = D{:};
if strcmp('Next',get(gcbo,'String'))
   IntNr = IntNr+1;
else
   IntNr = IntNr-1; 
end
if IntNr==0 || IntNr==size(Intervals,1)+1
   return
end
Start = AfkodTid(Intervals{IntNr,3});
Slut = AfkodTid(Intervals{IntNr,4});
guidata(gcf,{ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,VrefTrunk,ThresTrunk,ThresArm,SF,Ylab,Tbeat,RR,Intervals,IntNr})  
AnalyseAndPlot(ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,[],VrefTrunk,ThresTrunk,ThresArm,SF,Start,Slut,Ylab,1,[],[],[],Tbeat,RR);

function Par3 = Par3Grp
%oplistning af gruppe 3 parametre: vinkel-, BPM- og procentparametre
Par3 = {'IncArmPrctile10','degree';...
'IncArmPrctile50','degree';...
'IncArmPrctile90','degree';...
'VrefThighAP','degree';...
'VrefThighLat','degree';...
'VrefTrunkAP','degree';...
'VrefTrunkLat','degree';...
'IncTrunkWalk','degree';...
'BeatErrPct','percent';...
'HRmin','BPM';...
'HRmax','BPM';...
'HRmean','BPM';...
'HRsleep','BPM';...
'HRRmean','BPM';...
'HRoff','BPM';...
'HRlie','BPM';...
'HRsit','BPM';...
'HRstand','BPM';...
'HRmove','BPM';...
'HRwalk','BPM';...
'HRrun','BPM';...
'HRstairs','BPM';...
'HRcycle','BPM';...
'HRrow','BPM';...
'HRRoff','percent';...
'HRRlie','percent';...
'HRRsit','percent';...
'HRRstand','percent';...
'HRRmove','percent';...
'HRRwalk','percent';...
'HRRrun','percent';...
'HRRstairs','percent';...
'HRRcycle','percent';...
'HRRrow','percent'};
