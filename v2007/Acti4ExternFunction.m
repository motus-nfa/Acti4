function Acti4ExternFunction(D)

% User function for extra calculations 
%
% In this function the user can specify calculations that complement the standard calculations.
% The function is called at the end of 'AnalyseAndPlot'.
% Se function call in 'AnalyseAndPlot' for fields of input variable (struct) 'D'
%
% Acti4ExternFunction is called if it it found on the Matlab search path. 

return %if function is of the Matlab path but not to be used 

%Example:
% The code below is used for comparing sleep scoring by PSG and the Acti4 function SleepFun. 
% Reading and plotting sleep scoring files, accelerometer and heart rate data.
% Comparing sleep scoring with NFAsleep function output, calculating and and plotting sens/spec 

%Setup file for saving results:
global FidExtFun %to be cleared before a new run to be saved
if isempty(FidExtFun)
   FidExtFun = -1; 
   [FilNavn,Sti] = uiputfile('*.txt','Select file name saving results'); 
   if ~isnumeric(FilNavn) %Cancel not selected
      Fil = fullfile(Sti,FilNavn);
      FidExtFun = fopen(Fil,'w');
      fprintf(FidExtFun,'LbNr, Type, Start, Stop, PSGtme, PSGsleep, NFAsleep, Sensitivity, Specificity\r\n');
   end
end

%Time is modified for some IDs:
Ts = D.Tid(1);
Te = D.Tid(end);
dt = 0; %minutes offset
 IDdt = {'12521',2;'21412',1;'21614',3;'22420',2;'30507',1;'31211',3;'31513',-2;'31715',3;'32420',3};
 if any(strcmp(D.ID,IDdt))
    dt = IDdt{strcmp(D.ID,IDdt),2}*60/86400;
 end
D.Tid = D.Tid+dt;

tstart = D.Tid(1);
tslut = D.Tid(end);
jj = tstart<=D.Tid & D.Tid<=tslut; % indices for Acti4 data
Time = D.Tid(jj);

%Read sleep scoring data:
FileSS = dir(fullfile(fileparts(D.FilThigh),[D.ID,'.txt']));
FileSS = FileSS.name;
if exist(FileSS,'file')
   [TimeSS,SS] = ReadSleepScoring(FileSS); % in 'ActiDiverse' folder
   isc = tstart<=TimeSS & TimeSS<tslut; % indices for scoring data
end
PSGtime = length(SS)/120; %length of psg recording (hours)
PSGsleep = sum(SS~=0)/120; %hours of psg sleep

sleep = SleepFun(D.Akt,D.AccThigh,D.SF,'Thigh');
SumSleep = sum(sleep==0)/3600; %hours of nfa sleep

%Calculate sensitivity and specificity:
%Psg data is extended with 'non-sleep' scores to match length af Acti4 recording
SSext = [zeros(fix((TimeSS(1)-Time(1))*86400/30),1);SS;zeros(fix((Time(end)-TimeSS(end))*86400/30),1)]';
sleep30 = mode(reshape(sleep,30,[])); %to match psg time (30sec)
n = min(length(SSext),length(sleep30));%to ensure equeal length of data
SSext = SSext(1:n);
sleep30 = sleep30(1:n);
Sens = 100*sum(SSext~=0 & sleep30==0)/sum(SSext~=0);
Spec = 100*sum(SSext==0 & sleep30==1)/sum(SSext==0);

[Bbp,Abp] = butter(6,[.5 10]/(D.SF/2)); %band-pass filter 0.5-10 Hz

%Figure setup:
h = findobj('Tag','ExtFunPlot');
    if isempty(h)
       figure('Units','Normalized','Tag','ExtFunPlot','Toolbar','Figure','Position',[.55 .07 .4 .83] );
       set(zoom,'ActionPostCallback',@UpdateZoomExt);
    else
       figure(h);
       delete(get(h,'Children'))
    end
Np = 7; %number of subplot
db = .05; %bottom distance
dt = .05; %top distance
dm = .03; %gap distance
dh = (1-db-dt-(Np-1)*dm)/Np; %hight of subplot

%plot:
subplot('Position',[.1, db+(Np-1)*(dh+dm), .8, dh]) %Sleep scoring data
  if exist('SS','var')
     plot(TimeSS(isc),SS(isc))
     xlim([Time(1),Time(end)])
     datetick('x','HH:MM','keeplimits')
     set(gca,'ylim',[-.1,5.5],'YTick',0:5,'YTickLabel',{'S0','S1','S2','S3','REM','MT'},'Tag','ExtFun','XTickLabel',[])
     title([D.ID,' / ',datestr(Time(1),1)],'Interpreter','none')
  end
  
subplot('Position',[.1, db+(Np-2)*(dh+dm), .8, dh]) %Acti4 activity
  plot(Time,D.Akt)
  axis tight
  if isempty(D.FilHip) && isempty(D.FilTrunk)
     Ykat = D.Ylab{2}; %sit/lie uncertainty
  else
     Ykat = D.Ylab{1};
  end
  datetick('x','HH:MM','keeplimits')
  set(gca,'YTick',0:9,'YTickLabel',Ykat,'Ygrid','on','Tag','ExtFun','XTickLabel',[])
  
subplot('Position',[.1, db+(Np-3)*(dh+dm), .8, dh]) %Trunk angles
  Vtrunk = (180/pi)*D.Vtrunk(1:D.SF:end,:);
  plot(Time,Vtrunk)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Ylim',[-90,120],'Ytick',-90:30:120,'Ygrid','on','Tag','ExtFun','XTickLabel',[])
  ylabel('Trunk (°)')
  
subplot('Position',[.1, db+(Np-4)*(dh+dm), .8, dh]) %Thigh acceleration
  AccThigh = filter(Bbp,Abp,D.AccThigh);
  Athigh = mean(reshape(sqrt(sum(AccThigh.^2,2)),D.SF,[]));
  plot(Time,Athigh)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Tag','ExtFun','XTickLabel',[])
  ylabel('SVM thigh')
  
subplot('Position',[.1, db+(Np-5)*(dh+dm), .8, dh]) %Trunk acceleration
  AccTrunk = filter(Bbp,Abp,D.AccTrunk);
  Atrunk = mean(reshape(sqrt(sum(AccTrunk.^2,2)),D.SF,[]));
  plot(Time,Atrunk)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Tag','ExtFun','XTickLabel',[]) 
  ylabel('SVM trunk')
  
subplot('Position',[.1, db+(Np-6)*(dh+dm), .8, dh]) %Heart rata data
  if isfield(D,'TBeatf') %remember to include heart rate data in 'Analysis setup'
     ihr = tstart<=D.TBeatf & D.TBeatf<tslut; % indices for HR data
     plot(D.TBeatf(ihr),D.HRf(ihr),'k')
     xlim([Time(1),Time(end)])
     ylim([40, Inf])
     set(gca,'Tag','ExtFun','XTickLabel',[]) 
     ylabel('HR')
  end
  
 subplot('Position',[.1, db+(Np-7)*(dh+dm), .8, dh]) %NFA sleep function
  plot(Time,sleep)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'ylim',[-.1,1.1],'YTick',0:1,'YTickLabel',{'Sleep','Awake'},'Tag','ExtFun')
  
%Write results:
if ~isempty(FidExtFun) && FidExtFun~=-1
   fprintf(FidExtFun,'%s, %s, %s, %s, %5.3f, %5.3f, %5.3f, %4.1f, %4.1f\r\n',...
          D.ID,D.Type,datestr(Ts,'dd/mm/yyyy/HH:MM:SS'),datestr(Te,'dd/mm/yyyy/HH:MM:SS'),PSGtime,PSGsleep,SumSleep,Sens,Spec);
end
  
 
function UpdateZoomExt(~,~)
    %ActionPostCallback function for 'zoom' in plot with datetick x-axis and Tag = 'ExtFun'.
    %Gets 'Xlim' of the current axis and updates other datetick axis in the same figure accordingly, 
    Xakse=get(gca,'Xlim');
    h = findobj('Tag','ExtFun');
    for i=1:length(h)
        set(h(i),'Xlim',Xakse)
        datetick(h(i),'x','keeplimits')
    end