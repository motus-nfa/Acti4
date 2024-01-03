function Acti4ExternFunction(D)

% User function for extra calculations 
%
% In this function the user can specify calculations that complement the standard calculations.
% The function is called at the end of 'AnalyseAndPlot'.
% Se function call in 'AnalyseAndPlot' for fields of input variable (struct) 'D'
%
% Acti4ExternFunction is called if it it found on the Matlab search path. 

%return %if function is of the Matlab path but not to be used 

% The code below was used for PJCs sleep project (U:\PF\AnR_WP\SleepProject\Act4): 
% Reading and plotting sleep scoring files, accelerometer and heart rate data.
% Comparing sleep scoring with NFAsleep function output, calculating and and plotting sens/spec 

persistent Agree Sens Spec CKagree CKsens CKspec SumPSGsleep SumTid
if strcmp(D.ID,'10507') %pt. første ID
    [Agree,Sens,Spec,CKagree,CKsens,CKspec,] = deal([]);
    [SumPSGsleep,SumTid] = deal(0);
end

%sync:
dt = 0; %minutter offset
 IDdt = {'12521',2;'21412',1;'21614',3;'22420',2;'30507',1;'31211',3;'31513',-2;'31715',3;'32420',3};
 if any(strcmp(D.ID,IDdt))
    dt = IDdt{strcmp(D.ID,IDdt),2}*60/86400;
 end
D.Tid = D.Tid+dt;

tstart = D.Tid(1);
tslut = D.Tid(end);
jj = tstart<=D.Tid & D.Tid<=tslut; % indices for Act4 data
Time = D.Tid(jj);

FileSS = dir(fullfile(fileparts(D.FilThigh),[D.ID,'.txt']));
FileSS = FileSS.name;
if exist(FileSS,'file')
   [TimeSS,SS] = ReadSleepScoring(FileSS); % in 'ActiDiverse' folder
   ii = tstart<=TimeSS & TimeSS<tslut; % indices for scoring data
else
    
end

if isfield(D,'TBeatf')
   kk = tstart<=D.TBeatf & D.TBeatf<tslut; % indices for HR data
else   
end



[Bbp,Abp] = butter(6,[.5 10]/(D.SF/2)); %båndpasfilter 0.5-10 Hz

%Wrist file/acceleration:
FileWrist = dir(fullfile(fileparts(D.FilThigh),[D.ID,'_Wrist*.act4']));
if ~isempty(FileWrist)
   FileWrist = FileWrist.name;
   AccWrist = ReadACT4(FileWrist,-dt+tstart,-dt+tslut+1/86400);
   AccWrist(isnan(AccWrist)) = 0; %otherwise filter make all nan
%AccWrist = AccWrist(1:D.SF*60*fix(length(AccWrist)/(D.SF*60)),:); %must be integer number of minutes
   AccWrist = filter(Bbp,Abp,AccWrist);
   Awrist = mean(reshape(sqrt(sum(AccWrist.^2,2)),D.SF,[]));
   [~,cps] = AGcounts(AccWrist,D.SF);
   %ColeKripke 10 sec nonoverlaping:
   WeightColeKripke = .00001*[550,378,413,699,1736,287,309]; %for mean activity per minute
   cps10max = max(reshape(mean(reshape(cps(:,3),10,[])),6,[])); %usikker på mean her
   for i=1:length(cps10max)-6
       Dck(i) = dot(cps10max(i:i+6),WeightColeKripke) > 1;
   end
   Tck = tstart+5/(24*60):1/(24*60):tstart+1;
   Tck = Tck(1:length(Dck));   
end

 h = findobj('Tag','ExtFunPlot1');
     if isempty(h)
        figure('Units','Normalized','Tag','ExtFunPlot1','Toolbar','Figure','Position',[.55 .07 .4 .83] );
        set(zoom,'ActionPostCallback',@UpdateZoomExt);
     else
         figure(h);
         delete(get(h,'Children'))
     end

Np = 7; %antal subplot
db = .05; %bundafstand
dt = .05; %topafstand
dm = .03; %mellemrumsafstand
dh = (1-db-dt-(Np-1)*dm)/Np; %subplothøjde

subplot('Position',[.1, db+(Np-1)*(dh+dm), .8, dh])
  if exist('SS','var')
     plot(TimeSS(ii),SS(ii))
     xlim([Time(1),Time(end)])
     datetick('x','HH:MM','keeplimits')
     set(gca,'ylim',[-.1,5.5],'YTick',0:5,'YTickLabel',{'S0','S1','S2','S3','REM','MT'},'Tag','ExtFun','XTickLabel',[])
     title([D.ID,' / ',datestr(Time(1),1)],'Interpreter','none')
  end
subplot('Position',[.1, db+(Np-2)*(dh+dm), .8, dh])
  plot(Time,D.Akt)
  axis tight
  if isempty(D.FilHip) && isempty(D.FilTrunk)
     Ykat = D.Ylab{2}; %sit/lie uncertainty
  else
     Ykat = D.Ylab{1};
  end
  datetick('x','HH:MM','keeplimits')
  set(gca,'YTick',0:9,'YTickLabel',Ykat,'Ygrid','on','Tag','ExtFun','XTickLabel',[])
subplot('Position',[.1, db+(Np-3)*(dh+dm), .8, dh])
  Vtrunk = (180/pi)*D.Vtrunk(1:D.SF:end,:);
  plot(Time,Vtrunk)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Ylim',[-90,120],'Ytick',-90:30:120,'Ygrid','on','Tag','ExtFun','XTickLabel',[])
  ylabel('Trunk (°)')
subplot('Position',[.1, db+(Np-4)*(dh+dm), .8, dh])
  AccThigh = filter(Bbp,Abp,D.AccThigh);
  Athigh = mean(reshape(sqrt(sum(AccThigh.^2,2)),D.SF,[]));
  plot(Time,Athigh)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Tag','ExtFun','XTickLabel',[])
  ylabel('SVM thigh')
subplot('Position',[.1, db+(Np-5)*(dh+dm), .8, dh])
  AccTrunk = filter(Bbp,Abp,D.AccTrunk);
  Atrunk = mean(reshape(sqrt(sum(AccTrunk.^2,2)),D.SF,[]));
  plot(Time,Atrunk)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Tag','ExtFun','XTickLabel',[]) 
  ylabel('SVM trunk')
if ~isempty(FileWrist)
 subplot('Position',[.1, db+(Np-6)*(dh+dm), .8, dh])
  plot(Time(1:length(Awrist)),Awrist)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Tag','ExtFun','XTickLabel',[]) 
  ylabel('SVM wrist')
end  
subplot('Position',[.1, db+(Np-7)*(dh+dm), .8, dh])
  if isfield(D,'TBeatf') 
     plot(D.TBeatf(kk),D.HRf(kk),'k')
     xlim([Time(1),Time(end)])
     ylim([40, Inf])
     datetick('x','HH:MM','keeplimits')
     set(gca,'Tag','ExtFun') 
     ylabel('HR')
  end
  
hScore = findobj('Tag','ExtFunPlot2');
     if isempty(hScore)
        figure('Units','Normalized','Tag','ExtFunPlot2','Toolbar','Figure','Position',[.55 .07 .4 .83] );
        set(zoom,'ActionPostCallback',@UpdateZoomExt);
     else
         figure(hScore);
     end

Np = 7; %antal subplot
db = .05; %bundafstand
dt = .05; %topafstand
dm = .05; %mellemrumsafstand
dh = (1-db-dt-(Np-1)*dm)/Np; %subplothøjde

subplot('Position',[.1, db+(Np-1)*(dh+dm), .8, dh])
  if exist('SS','var') 
    plot(TimeSS(ii),SS(ii))
    xlim([Time(1),Time(end)])
    datetick('x','HH:MM','keeplimits')
    set(gca,'ylim',[-.1,5.5],'YTick',0:5,'YTickLabel',{'S0','S1','S2','S3','REM','MT'},'Tag','ExtFun','XTickLabel',[])
    title({[D.ID,' / ',datestr(Time(1),1)];'PSG'},'Interpreter','none')
  end
if ~isempty(FileWrist)  
 subplot('Position',[.1, db+(Np-2)*(dh+dm), .8, dh])
  plot(Tck,Dck)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'ylim',[-.1,1.1],'YTick',0:1,'YTickLabel',{'Sleep','Awake'},'Tag','ExtFun','XTickLabel',[])
  
  dck = Dck(TimeSS(1)<=Tck & Tck<=TimeSS(end));
  ss = SS(1:2:end)' == 0;
  ss = ss(1:length(dck));
  ckagree = 100*sum(dck == ss) / length(ss); %provisorisk
  cksens = 100*sum(dck == ss & ss == 0)/sum(ss==0);
  ckspec = 100*sum(dck == ss & ss == 1)/sum(ss==1);
  title(['ColeKripke (',num2str(ckagree,3),'%)'])
  CKagree = [CKagree;ckagree];
  CKsens = [CKsens;cksens];
  CKspec = [CKspec;ckspec];
end

AccArm = filter(Bbp,Abp,D.AccArm);
Aarm = mean(reshape(sqrt(sum(AccArm.^2,2)),D.SF,[]));
%[sleep,I] = NFAsleep(Aarm,exp(-1/(60*19)),.15);
[sleep,I] = NFAsleep(Atrunk,exp(-1/(60*21)),.24);
  
 subplot('Position',[.1, db+(Np-3)*(dh+dm), .8, dh])
  plot(Time(1:length(Athigh)),Athigh)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'Tag','ExtFun','XTickLabel',[]) 
  ylabel('VM trunk')

 subplot('Position',[.1, db+(Np-4)*(dh+dm), .8, dh])
   plot(Time,I)
   axis tight
   datetick('x','HH:MM','keeplimits')
   ylabel('S index')
   set(gca,'Tag','ExtFun','XTickLabel',[]) 

 subplot('Position',[.1, db+(Np-5)*(dh+dm), .8, dh])
  SumTid = SumTid + length(sleep)/3600;
  plot(Time,sleep)
  axis tight
  datetick('x','HH:MM','keeplimits')
  set(gca,'ylim',[-.1,1.1],'YTick',0:1,'YTickLabel',{'Sleep','Awake'},'Tag','ExtFun')
  
%   psg = reshape(repmat(SS'==0,30,1),[],1)';
%   nn = TimeSS(1)<=Time & Time<=TimeSS(end)+30/86400;
%   sleep = sleep(nn);
%   sleep = sleep(1:length(psg));
%   NFAagree = 100*sum(sleep == psg) / length(sleep); 
%   title(['NFA (',num2str(NFAagree,3),'%)'])
  
  
drawnow

SumPSGsleep = SumPSGsleep + sum(SS~=0)/120;

k1m = 10:.5:30;  
k1 = exp(-1./(60*k1m));
k2 = .05:.01:.75;
[agree,sens,spec] = deal(zeros(1,length(k1),length(k2))); 
for m=1:length(k1)
for n=1:length(k2)
    
Sleep = NFAsleep(Athigh,k1(m),k2(n));
Sleep = ~(Sleep==0 & D.Akt==1);

% psg intervals are extended (awake) to intervals matching accelerometer recordings:
   Psg = ones(size(Sleep));
   n1 = find(nn,1);
   Psg(n1:n1+length(psg)-1) = psg;
   agree(1,m,n) = 100*sum(Sleep == Psg) / length(Sleep); %provisorisk
   sens(1,m,n) = 100*sum(Sleep == Psg & Psg == 0)/sum(Psg==0);
   spec(1,m,n) = 100*sum(Sleep == Psg & Psg == 1)/sum(Psg==1);
  
end
end

%bestemme Sleep kun ud fra Ligge: hvis fald-i-søvn sættes til 35 min (efter ligge mere ½ time), 
%fås Sens=95 og Spec=75 (maksimering af Sens+Spec):
%first lying period longer than 30 min:
% DiffLie = diff([0;D.Akt'==1;0]);
% LieInt = [find(DiffLie==1),find(DiffLie==-1)-1];
% Int30 = LieInt(LieInt(:,2)-LieInt(:,1)>60*30,:);
% s1 = Int30(1);
% Sleep = ~(D.Akt==1);
% [agree,sens,spec] = deal(zeros(1,45)); 
% for k=1:45
%  Sleep(1:s1+k*60) = 1;
%  Psg = ones(size(Sleep));
%  n1 = find(nn,1);
%  Psg(n1:n1+length(psg)-1) = psg;
%    agree(k) = 100*sum(Sleep == Psg) / length(Sleep); %provisorisk
%    sens(k) = 100*sum(Sleep == Psg & Psg == 0)/sum(Psg==0);
%    spec(k) = 100*sum(Sleep == Psg & Psg == 1)/sum(Psg==1);
% end

Agree = [Agree;agree];
Sens = [Sens;sens];
Spec = [Spec;spec];

if strcmp(D.ID,'32420') %pt. sidste
   Ag = squeeze(mean(Agree));
   Se = squeeze(mean(Sens));
   Sp = squeeze(mean(Spec));
   figure, 
   hSe = surf(k2,k1,Se); set(hSe,'Facecolor',[1 0 0],'FaceAlpha',1,'EdgeAlpha',0.5); hold
   hSp = surf(k2,k1,Sp); set(hSp,'Facecolor',[0 1 0],'FaceAlpha',1,'EdgeAlpha',0.5);
   hAg = surf(k2,k1,Ag); set(hAg,'Facecolor',[0 0 1],'FaceAlpha',1,'EdgeAlpha',0);
   axis([k2(1),k2(end),k1(1),k1(end),0,100])
   set(gca,'YTick',k1(1:5:end),'YTickLabel',num2str(k1m(1:5:end)'))
   ylabel('minutes')
   
   %find max af Sens+Spec:
   sumSeSp = Se+Sp;
   [~,k2i] = max(max(sumSeSp));
   [~,k1i] = max(sumSeSp(:,k2i));
   line([k2(k2i);k2(k2i)],[k1(k1i);k1(k1i)],[0;100],'LineWidth',2,'Color',[0 0 0],'Marker','o')
   text(k2(k2i),k1(k1i),0,['[',num2str(k2(k2i)),',',num2str(k1m(k1i)),']'],...
        'HorizontalAlignment','Center','VerticalAlignment','Top','FontWeight','Bold')
   legend(['Sesitivity, ',num2str(round(Se(k1i,k2i)))],['Specificity, ',num2str(round(Sp(k1i,k2i)))],'Agreement')

   SumTid
   SumPSGsleep
   CKag = mean(CKagree)
   CKse = mean(CKsens)   
   CKsp = mean(CKspec)   
   
end 

function [Sleep,I] = NFAsleep(A,k1,k2)
  A(A<.02) = 0;
  I = zeros(size(A));
  I0 = exp(1);
  Iprev = I0; %fully awake 
  for i = 1:length(A)
    I(i) = k1*Iprev + k2*A(i);
    Iprev = min(I0,I(i));
  end
  Sleep = I>1;
  Sleep = medfilt1(double(Sleep),19);
  wt = find(diff(Sleep)==1);
  for j=1:length(wt)
      Sleep(max(1,wt(j)-120):wt(j)-1) = 1; 
  end

  
function UpdateZoomExt(~,~)
    %ActionPostCallback function for 'zoom' in plot with datetick x-axis and Tag = 'ExtFun'.
    %Gets 'Xlim' of the current axis and updates other datetick axis in the same figure accordingly, 
    %writes min and max of axis in separat text fields. 
    
    Xakse=get(gca,'Xlim');
    h = findobj('Tag','ExtFun');
    %h = get(gcf,'children');
    for i=1:length(h)
        set(h(i),'Xlim',Xakse)
        datetick(h(i),'x','keeplimits')
    end