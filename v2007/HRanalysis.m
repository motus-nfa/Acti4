function [TBeatf,RRf,HRf,HRmin,HRmax] = HRanalysis(Tbeat,RR,Start,Stop)

% Filtering of raw data from HR recordings (Aug. 2019)
%
% This function filters raw HR data
% and outputs filtered RR and HR data and max/min HR values. 
% The filtering is inspired by a procedure by Kubios (www.Kubios.com,
% Kubios_HRV_Users_Guide.pdf, 2016-2019, Premium procedure, pp. 11-12).
% Some minor adjustments and amendments have been necessary.
% Actiheart recordings by U:\PF\Guldlok\Pilot\Data\Raw\AX3\Guldlok_pilot_setup.xls 
% have been used for development and testing of the procedure.

% Input:
% Tbeat [N]: Array of datenum values for heartbeats (red from mat-files) 
% RR [N]: Interbeat distance in millisec. (red from mat-files)

% Start: Start time (datenum) of interval to be analysed
% Stop: Stop time (datenum) of interval to be analysed
% (N: total number of beats)

% Output:
% TBeatf [n]: Array of datenum values (approx.) for beats in the interval Start-Stop
% RRf [n]: Filtered IBIs (ms)
% HRf []n]: Filtered instantaneous heart rate for beats in the interval Start-Stop
% HRmin: Minimum HRf in interval, minimum of running average over 10 sec. 
% HRmax: Maximum HRf in interval, maximum of running average over 10 sec.

Ibeat = Start<=Tbeat & Tbeat<=Stop;
TBeat = Tbeat(Ibeat);
RR = RR(Ibeat); %now the actual interval

[RRf,TBeatf] = Filt0(RR,TBeat); %filtering
HRf = 60000./RRf;

%Max/min calculation:
HRmax = 60000./min(smooth(RRf(~isnan(RRf)),10)); %averaging RRf minimise impact of HR spikes
HRmin = min(smooth(HRf(~isnan(HRf)),10));
if isempty(HRmax), HRmax = NaN; end
if isempty(HRmin), HRmin = NaN; end



function [RRf,TBeatf] = Filt0(RR,TBeat)
% Htest1 = findobj('Tag','Test1');
% if isempty(Htest1),Htest1=figure('Tag','Test1'); else figure(Htest1), end
% ax1(1)=subplot(2,1,1); plot((TBeat-TBeat(1))*86400,RR,'r')

%RR values to be removed are set to NaN 

RR(RR<300 | RR>=2000) = NaN; %extreme values removed

%Processing missing beats:
dRR = diff(RR);
N = length(dRR);
Th = zeros(size(dRR)); %Time varying threshold (Kubios)
med10 = zeros(size(dRR)); %Median of 10 RR valus
mb = zeros(size(RR)); %for marking missing beats

for i=1:10:N 
    Th(i) = 5.2*.5*iqr(dRR(max(1,i-45):min(i+45,N))); %iqr: time consuming to calculate every sample,
end                                   % so every 10th is calculated and then linear interpolation 
Th = interp1(1:10:N,Th(1:10:N),1:N)';

for i=1:N %to include calculation of Th in this loop increase calculation time drastically
    med10(i) = median(RR(max(i-5,1):min(i+5,N+1)));
    if abs(RR(i)/2-med10(i))<.5*Th(i) && RR(i)>1300 ,  mb(i)=1; end
    %OBS: 0.5*Th are used instead of 2*Th (Kubios). 2*Th cause some 'long beats' to be misclassified as missing beats.
    %Without the condition RR(i)>1300, somme misclassification of small RR values can occur. 
end

MB = find(mb); %inserting missing beats
if ~isempty(MB)
   for i=length(MB):-1:1 %from the end
       RR = [RR(1:MB(i)-1);RR(MB(i))/2;RR(MB(i))/2;RR(MB(i)+1:end)];
       TBeat = [TBeat(1:MB(i));(TBeat(MB(i)) + TBeat(MB(i)+1))/2;TBeat(MB(i)+1:end)];
   end
   dRR = diff(RR);
   N = length(dRR);
   %number of beats have now changed, so update Th so ready for extra beats handling:
   Th = zeros(size(dRR)); %Time varying threshold (Kubios)
   for i=1:10:N 
       Th(i) = 5.2*.5*iqr(dRR(max(1,i-45):min(i+45,N))); %iqr: time consuming to calculate every sample,
   end                                   % so every 10th is calculated and then linear interpolation 
   Th = interp1(1:10:N,Th(1:10:N),1:N)';
end

%Processing extra beats:
[med10,std10] = deal(zeros(size(dRR)));
eb = zeros(size(RR)); %for marking extra beats
for i=1:N
   % Th(i) = 5.2*.5*iqr(dRR(max(1,i-45):min(i+45,N))); calculated above, if beats have changed
    med10(i) = median(RR(max(i-5,1):min(i+5,N+1)));
    std10(i) = std(RR(max(i-5,1):min(i+5,N+1)));
    if abs(RR(i)+RR(i+1)-med10(i))<2*Th(i) && RR(i)<750  %last critera: to avoid detecting false extra beats during sleep
       eb(i)=1; 
    end
end
%The above loop marks isolated extra beats and series of extra beats also occur.
%Handling series of extra beats are not described by Kubios, but seems to match intervals with corrupted RR values.
%So the isolated extra beats are filled in and the series of extra beats are removed from the RR data.
%Find which are isolated extra beats:
aux = diff([0;eb(2:end-1);0]);
ss = [find(aux==1),find(aux==-1)]; %start and stop indices for extra beats 
EBiso = ss((ss(:,2)-ss(:,1) == 1),1)+1; %Isolated (thrue) extra beats

EB = find(eb);
EB = setdiff(EB,EBiso); %EB is now the series of "extra" beats, 
RR(EB) = NaN; %which represents bad RR values.

RR(std10 == 0) = NaN; %constant values of 2000ms found for bad Actiheart data 

for i=length(EBiso):-1:1 %remove isolated extra beats from the end:
    if EBiso(i)+2<=length(RR)
       RR = [RR(1:EBiso(i)-1);(TBeat(EBiso(i)+2)-TBeat(EBiso(i)))*86400000;RR(EBiso(i)+2:end)];
       TBeat = [TBeat(1:EBiso(i));TBeat(EBiso(i)+2:end)];
    end
end
%The edges of these bad intervals typically contain RR intervals with large variation which are deleted below. 

% Htest2 = findobj('Tag','Test2');
% if isempty(Htest2),figure('Tag','Test2'), else figure(Htest2), end
% ax2(1)=subplot(3,1,1); plot(RR),ylabel('RR')
% ax2(2)=subplot(3,1,2); plot(Th),ylabel('Th')
% ax2(3)=subplot(3,1,3); plot(std10),ylabel('std10')
% linkaxes(ax2,'x')
% figure(Htest1)
% ax1(2)=subplot(2,1,2); plot((TBeat-TBeat(1))*86400,RR,'r'), hold on
% linkaxes(ax1,'x')

%Processing short/long beats and ectopic beats:
if ~isempty(EB) || ~isempty(EBiso)
   dRR = diff(RR);
   N = length(dRR);
   Th = zeros(size(dRR)); %update Th (series have changed)
   for i=1:10:N 
       Th(i) = 5.2*.5*iqr(dRR(max(1,i-45):min(i+45,N))); %iqr: time consuming to calculate every sample,
   end                                   % so every 10th is calculated and then linear interpolation 
   Th = interp1(1:10:N,Th(1:10:N),1:N)';
end

j = diff([0; abs(dRR)>Th;0]);
ss = [find(j==1),find(j==-1)]; %start and stop indices for short/long/ectopic beats
if ~isempty(ss)
  ss(1,1) = max(2,ss(1,1)); %to prevent index outside RR range
  ss(end,2) = min(size(RR,1)-1,ss(end,2)); %to prevent index outside RR range
  for k=1:size(ss,1)
    n = ss(k,2)-ss(k,1); 
    if n==2 && dRR(ss(k,1))*dRR(ss(k,2)-1) <0 % short (NP) or lonp (PN) beats
        aux = linspace(RR(ss(k,1)),RR(ss(k,2)),n+1);
        RR(ss(k,1)+1:ss(k,2)-1) = aux(2:end-1); %interpolation
    end
    %ectopic beats PNP or NPN:
    if n==3 && (all(sign(dRR(ss(k,1):ss(k,2)-1))==[1;-1;1]) || all(sign(dRR(ss(k,1):ss(k,2)-1))==[-1;1;-1]))
        aux = linspace(RR(ss(k,1)),RR(ss(k,2)),n+1);
        RR(ss(k,1)+1:ss(k,2)-1) = aux(2:end-1);
    end 
    if n>=4 %more than 3 dRR intervals above threshold -> remove
       RR(ss(k,1)+1:ss(k,2)-1)= NaN;
    end
  end
end

% Important cleaning edges of RR intervals with removed values (NaN).
% Neighbours to removed RR intervals are removed if they contain large variations:  
aux = isnan(RR);
j = diff([0;aux(2:end-1);0]);
ss = [find(j==1),find(j==-1)]; %start and stop for removed intervals
for k=1:size(ss,1)
    m=0; %left neighbours to removed intervals are removed if range/median through 10 RRs exceed .25
    while range(RR(max(1,ss(k,1)-9-m):ss(k,1)-m))/median(RR(max(1,ss(k,1)-9-m):ss(k,1)-m)) >.25
          RR(ss(k,1)-m) = NaN;
          m=m+1;
    end
    m=0; %right neighbours to removed intervals are removed if range/median through 10 RRs exceed .25
    while range(RR(ss(k,2)+1+m:min(ss(k,2)+10+m,N+1)))/median(RR(ss(k,2)+1+m:min(ss(k,2)+10+m,N+1))) >.25
          RR(ss(k,2)+1+m) = NaN;
          m=m+1;
    end 
end

%Isolated sequence with less than 5 beats are removed and also sequences with less than 90 beats unless variations are very small: 
aux = isnan(RR);
j = diff([0;aux(2:end-1);0]);
ss = [find(j==1),find(j==-1)]; %start and stop for removed intervals
for k=2:size(ss,1) 
    if ss(k,1)-ss(k-1,2)<=5  ||  (ss(k,1)-ss(k-1,2)<90 && std(RR(ss(k-1,2)+1:ss(k,1)))/median(RR(ss(k-1,2)+1:ss(k,1))) > .05)
       RR(ss(k-1,2)+1:ss(k,1)) = NaN;
    end
end

RRf = RR;
TBeatf = TBeat;

% figure(Htest1), subplot(2,1,2)
% plot((TBeat-TBeat(1))*86400,RR), hold off

    
    

