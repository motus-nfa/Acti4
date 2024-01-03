function KneelDetection(ID,Type,Start,Slut,Tid,Akt,SF,FilThigh,Vthigh,OffThigh,ShiftAxes,AktTid,Th)

%Detection of kneeling position
%
%If the option 'Include calf accelerometer' is selected i 'Analysis setup',
%this function is called in AnalyseAndPlot.
%
%Calf data must be found in the same folder as data from other accelerometers.
%Results are saved in a separate textfile specified (Cancel: no saving) when this function is
%called for the first time from Batch run. A separate window shows the
%activity detection and thigh and calf angle.
%18/5-2020

global FidCalfResults

% Setup file for saving results:
if isempty(FidCalfResults) % set to empty when Batch is started
   try
      WB = get(actxGetRunningServer('Excel.Application'),'ActiveWorkbook'); %Finder Setup filen (12/6-19):
      SetupFil = get(WB,'Name');
      [FilNavn,Sti] = uiputfile('*.txt','Select file name for "Calf-results" ',[SetupFil(1:end-4),'_Calf_RES']);
   catch
       FilNavn = 0;
   end
   if isnumeric(FilNavn) %Cancel selected, no saving
      FidCalfResults = NaN; 
   else 
      Fil = fullfile(Sti,FilNavn);
      FidCalfResults = fopen(Fil,'w');
      fprintf(FidCalfResults,'LbNr, Type, Start, Stop, Time, CalfOff, ThighOff, lie, kneel, sit, stand, move, walk, run, stairs, cycle, row, IncCalfWalk, APCalfWalk, LatCalfWalk'); 
      fprintf(FidCalfResults,'\r\n');
   end
end

Mappe = fileparts(FilThigh);
FileCalf = dir(fullfile(Mappe,[ID,'*calf*.act4']));

if isempty(FileCalf) %no kneeling detection
   OffCalf = ones(size(OffThigh));
   Hakt = [AktTid(6:7),NaN,AktTid(8:15)];
   AngCalfWalk = NaN(1,3);
else
   FileCalfName = FileCalf.name;
   FileCalf = fullfile(Mappe,FileCalfName);
   [Angles,AccCalf] = Vinkler(FileCalf,Start,Slut,ShiftAxes);

   OffCalf = NotWorn(Angles,AccCalf,SF);
    
   Angles = 180*Angles/pi;
   Angles(:,2) = -Angles(:,2); %maybe more logical when looking at the plot
    
   Vcalf = squeeze(mean(Acc60(Angles,SF))); %2 sec. averaged angles
   Vthigh = 180*squeeze(mean(Acc60(Vthigh,SF)))/pi; %2 sec. averaged angles
   OffCalf = OffCalf | NotWornCalf(Akt,Vthigh,AccCalf,SF,Vcalf,Th); %extra search for off
  
   Kneel = zeros(size(Akt));
   Kneel(Vcalf(:,1)>Th & Vcalf(:,2)<-45 & Vthigh(:,2)>-20 & abs(Vthigh(:,3))<30 ... 
         & OffCalf==0 & Akt'~=1 & Akt'~=0) = 1;
        
   AngCalfWalk = CheckCalfOrientation(FileCalfName,Akt,Vthigh,Vcalf,Start,Slut,OffCalf);     
   
   Kneel = logical(medfilt1(Kneel,5));
  
   %Make room for kneel in Akt:
   Akt(Akt>=2) = Akt(Akt>=2)+1;
   Akt(Kneel) = 2;
   
   %Find and cancel false 'kneel' embedded in sitting intervals (sitting with calf underneath):
   SitKneel = zeros(size(Akt));
   SitKneel(Akt==3) = 1;
   SitKneel(Akt==2) = -1;
   SitKneel = [0,SitKneel];
   kneel2sit = find(diff(SitKneel)==2); %kneel til sit overgange
   sit2kneel = find(diff(SitKneel)==-2); %sit til kneel overgange
   for iss=1:length(sit2kneel)
       if range(Vthigh(max(sit2kneel(iss)-3,1):min(sit2kneel(iss)+2,length(Akt)),1)) <30 %benvinkelrange i +/- 3sek ved overgang fra sit til kneel <30
          NextKneel2sit =kneel2sit(find(kneel2sit > sit2kneel(iss),1,'first')); %førstfølgende sit til kneel
          if ~isempty(NextKneel2sit) && all(Akt(sit2kneel(iss):NextKneel2sit-1)==2) ... %hvis det ét sammenhængende kneel interval
             && range(Vthigh(max(NextKneel2sit-3,1):min(NextKneel2sit+2,length(Akt)),1)) <30; %og benvinkelrange <30 ved overgang til sit (som før)
             Akt(sit2kneel(iss):NextKneel2sit-1) = 3; %så er det sit
          end
       end
   end
   
   Nakt = hist(Akt,0:10)';
   Hakt = Nakt/3600;
   
   %Plotting:
   h = findobj('Tag','KneelFig');
   if isempty(h)
      h = figure('Units','Normalized','Position',[.5 .2 .4 .6],'Tag','KneelFig');
      set(zoom,'ActionPostCallback',@UpdateFig);
   end
   figure(h)
   delete(findobj('Tag','KneelSub'))
   subplot('Position',[.13 .67 .775 .25]) %Activity
       Apct = num2str(100*Nakt/sum(Nakt),'%4.1f');
       plot(Tid,Akt,'-k')
       axis tight
       datetick('x','HH:MM','keeplimits')
       Xakse = xlim;
       set(gca,'Ylim',[-.1 10.1])
       Ylab = {'off';'lie';'kneel';'sit';'stand';'move';'walk';'run';'stairs';'cycle';'row'};
       set(gca,'YTick',0:10,'YTickLabel',Ylab,'Ygrid','on')
       set(gca,'Tag','KneelSub')
       title([ID,' / ',datestr(Start,1)],'Interpreter','none')
       % Procentvædier skrives i højre side:
       text(1.02,1.08,'%','Units','Normalized','Tag','Percent','Tag','Percent')
       text(repmat(1.01,1,11),(0:10)/10.2+1/102,Apct,'Units','Normalized','FontSize',8,'Tag','Percent')
       if any(OffThigh)
          hold on
          plot(Tid(OffThigh==1),Akt(OffThigh==1),'y')
          hold off
       end
       
   subplot('Position',[.13 .375 .775 .2]) %Thigh angles
       plot(Tid,Vthigh)
       set(gca,'Xlim',Xakse,'Ylim',[-90,120],'Ytick',-90:30:120,'Ygrid','on') 
       datetick('x','HH:MM','keeplimits')
       set(gca,'Tag','KneelSub')
       ylabel('Thigh (°)')
       L = legend('Inc','Ant/Pos','Lat','Orientation','Horizontal','Location','North');
       legend(L,'boxoff')
       SubPos = get(gca,'Position');
       set(L,'Position',[.5,SubPos(2)+1.05*SubPos(4),.001,.02])
        
   subplot('Position',[.13 .09 .775 .2]) %Calf angles
       plot(Tid,Vcalf)
       set(gca,'Xlim',Xakse,'Ylim',[-90,120],'Ytick',-90:30:120,'Ygrid','on') 
       datetick('x','HH:MM','keeplimits')
       set(gca,'Tag','KneelSub')
       ylabel('Calf (°)')  
       L = legend('Inc','Ant/Pos','Lat','Orientation','Horizontal');
       legend(L,'boxoff')
       SubPos = get(gca,'Position');
       set(L,'Position',[.5,SubPos(2)+1.05*SubPos(4),.001,.02])
       if any(OffCalf) %if Calf is off somewhere in the interval
          hold on
          plot(Tid(OffCalf==1),Vcalf(OffCalf==1,:),'.y')
          hold off
       end 
end

if ~isnan(FidCalfResults)
   fprintf(FidCalfResults,'%s, %s, %s, %s, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %8.5f, %5.1f, %5.1f, %5.1f \r\n', ...
           ID,Type,datestr(Start,'dd/mm/yyyy/HH:MM:SS'),datestr(Slut,'dd/mm/yyyy/HH:MM:SS'),24*(Slut-Start),sum(OffCalf)/3600,Hakt,AngCalfWalk);
end  


function AngCalfWalk = CheckCalfOrientation(FileCalfName,Akt,Vthigh,Vcalf,Start,Slut,OffCalf) 
  %Check orientation of calf accelerometer; 
  %If lying ("flat", more than 1 minute) is present, forward/backward orientation can be checked,
  %if walk is present, up/down is checked
   Int = [datestr(Start,'dd/mm/yyyy/HH:MM:SS'),' - ',datestr(Slut,'dd/mm/yyyy/HH:MM:SS')];
   ii = Akt'==1 & (abs(Vthigh(:,2)>60 & abs(Vcalf(:,2))>60)) ...
        & OffCalf==0 & (abs(Vthigh(:,3))<30 & abs(Vcalf(:,3)<30)); %Lying at the back or belly (at least 1 min.):
   if sum(Vthigh(ii,2).*Vcalf(ii,2) >0)/sum(ii)<.5  && sum(ii)>60 %signs of forward/backward angle should be equal
      warndlg({[FileCalfName,':'];'Probably wrong IN/OUT orientation by calf (or thigh) accelerometer for interval';Int})
   end
   AngCalfWalk = mean(Vcalf(Akt'==5 & OffCalf==0,:));
   if AngCalfWalk(1) > 45
       warndlg({[FileCalfName,':'];'Probably wrong UP/DOWN orientation by calf accelerometer for interval';Int}) 
   end


function Af = NotWornCalf(Akt,Vthigh,AccCalf,SF,Vcalf,Th)
   % Extra search for off periods for calf accelerometer
   % Calf accelerometer is off if there is no movement for at least 10 minute where thigh moves.
   
   StdMeanCalf  = mean(squeeze(std(Acc60(AccCalf,SF))),2); %1 second time scale
   % For not-worn periods the AG normally enters standby state (Std=0 in all axis) or
   % in some cases yield low level noise of ±2-3 LSB: 
   OffOn = diff([false,StdMeanCalf(1:end-1)'<.01,false]);
   Off = find(OffOn==1);
   On = find(OffOn==-1);
   OffPerioder = On - Off;
   StartOff = Off(OffPerioder>180); % 3 minutes
   SlutOff = On(OffPerioder>180); 
   
   %Short periods (<1 minut) of activity between not-worn are removed
   KortOn = (StartOff(2:end) - SlutOff(1:end-1)) < 60;
   if ~isempty(KortOn)
      SlutOff = SlutOff([~KortOn,true]);
      StartOff = StartOff([true,~KortOn]);
   end
   
   Af = zeros(size(StdMeanCalf));
   for i=1:length(StartOff)
       if  SlutOff(i)-StartOff(i)>600 ... %for more than 10 minuttes
           && max(range(Vthigh(StartOff(i):SlutOff(i),:))) > 10  %if thigh moves more than 10 degrees
           Af(StartOff(i):SlutOff(i)) = 1;
       end
       Vmean = mean(Vcalf(StartOff(i):SlutOff(i),:));
       if  SlutOff(i)-StartOff(i)>300 ... % 5 minuttes
           && (all(abs(Vmean - [90,90,0]) < 3)... % Only not-worn if orientation differs less than 3° 
               || all(abs(Vmean - [90,-90,0]) < 3))   % from "flat" lying orientation (up or down)
           Af(StartOff(i):SlutOff(i)) = 1;
       end
   end
   Af(Vcalf(:,1)<Th | Vcalf(:,2)>-45 | Vthigh(:,2)<-20 | abs(Vthigh(:,3))>30) = 0; 
   Af(Akt==1) = 0; %no off detection for lying perids
   
   
function UpdateFig(~,~)
  Xakse=get(gca,'Xlim');
  h = findobj('Tag','KneelSub');
  for i=1:length(h)
      set(h(i),'Xlim',Xakse)
      datetick(h(i),'x','keeplimits')
  end
  delete(findobj('Tag','Percent'))
