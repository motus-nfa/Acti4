function  Af = NotWorn(V,Acc,SF)

% Estimation of periods of 'not-worn'

% All periods longer than 90 minuttes with no activity are considered not-worn;
% periods between 10 to 90 minutes are considered not-worn if a certain amount of movement/acceleration
% is detection just before (within 10 sec.) and the orientaion deviates less than 5° from horizontal lying.

% Input:
% V [N,3]: Orientation of AG (radians)
% Acc [N,3]: Unfiltered accelerations
% SF: Sample frequency

% Output:
% Af [n]: 0/1, not-worn = 1 , one sec. time scale (N=SF*n)
% NaN in Acc and V also means not-worn
% 
V = V(1:SF:end,:);

Acc12 = Acc60(Acc,SF);
StdMean  = mean(squeeze(std(Acc12)),2); %1 second time scale
StdSum = sum(squeeze(std(Acc12)),2);

% For not-worn periods the AG normally enters standby state (Std=0 in all axis) or
% in some cases yield low level noise of ±2-3 LSB: 
OffOn = diff([false,StdMean(1:end-1)'<.01,false]);
Off = find(OffOn==1);
On = find(OffOn==-1);
OffPerioder = On - Off;
StartOff = Off(OffPerioder>600); % 10 minutes
SlutOff = On(OffPerioder>600);

% A not-worn period will normally be preceeded by at least a short period of some movement, so if movement is
% detected within 10 seconds before 'not-worn', it is not accepted as a not-worn period.
% All periods without activity lasting more than 90 minuttes are always not-worn.
Ok = false(size(StartOff));
for i=1:length(StartOff)
          % [num2str(max(StdSum(StartOff(i)-15:StartOff(i)-11))) '  '  datestr(T(SF*StartOff(i)),'HH:MM:SS')]
    Ok(i) = max(StdSum(max(StartOff(i)-15,1):max(StartOff(i)-11,5))) > .5... %max: problem if StartOff(1)<15
          || SlutOff(i) - StartOff(i) > 5400; %over 90min altid off
end
StartOff = StartOff(Ok);
SlutOff = SlutOff(Ok);

% Short periods (<1 minut) of activity between not-worn are filtered out
KortOn = (StartOff(2:end) - SlutOff(1:end-1)) < 60;
if ~isempty(KortOn)
  SlutOff = SlutOff([~KortOn,true]);
  StartOff = StartOff([true,~KortOn]);
end
Af = zeros(length(V),1);
for i=1:length(StartOff)
   Vmean = 180*mean(V(StartOff(i):SlutOff(i),:))/pi;
   if  SlutOff(i)-StartOff(i)>5400 ... % >90 minuttes,always not-worn
       || all(abs(Vmean - [90,90,0]) < 5)... % Only not-worn if orientation differs less than 5° 
       || all(abs(Vmean - [90,-90,0]) < 5)   % from "flat" lying orientation (up or down)
       Af(StartOff(i):SlutOff(i)) = 1;
   end
end

Af(isnan(StdMean)) = 1; %9/12-19 to handle acceleration breaks in firstbeat 'front' data
                        %and early stopped accelerometers, nan acc-data means off   


