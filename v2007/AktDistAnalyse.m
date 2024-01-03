function [Tmax,P50,T50,P10,P90,T30min,N30min,Noff,Pauses] = AktDistAnalyse(Akt,a)

% Calculates several descriptive parameters of the distribution for the activity "a". 
% Aug.2014

% Input:
% Akt [n]: Activity array (1 sec. time scale, 1=lie, 2=sit, 3=stand still, 4=move, etc.).

% Output:
% Tmax: Maximum length (h) interval for selected activity.  
% P10,P50,P90: Percentiles for distribution (h).
% T50: Total length (h) of periods longer than P50 (median).
% T30min: Total length (h) of periods longer than 30 minuttes
% N30min: Number of periods longer than 30 minuttes
% Nrise: Number of times leaving activity (for SitLie, number of rises)
% (Pauses: pauses for testing)


A = zeros(size(Akt));
switch a
  case 'Sit', A(Akt==2) = 1;
  case 'SitLie', A(Akt==2 | Akt==1) = 1;
  case 'Stand',  A(Akt==3) = 1;
  case 'StandMove', A(Akt==3 | Akt==4) = 1;
end

OnOff = diff([0,A,0]);
On = find(OnOff==1);
Off = find(OnOff==-1);
Times = Off-On;
Pauses = On(2:end)-Off(1:end-1);

if isempty(Times)
   [Tmax,P50,T50,P10,P90,T30min,N30min,Noff] = deal(0);
   return
end

Tmax = max(Times)/3600; %empty ?

Y = prctile(Times,[10 50 90])/3600;
P10 = Y(1);
P50 = Y(2); %median
P90 = Y(3);
T50 = sum(Times(Times/3600>=P50))/3600; %hours spent in periods longer than median

i30 = Times>=1800; %30 minuttes
T30min = sum(Times(i30))/3600; %hours spent in periods longer than 30 minuttes
N30min = sum(i30); % number of periods longer than 20 minuttes
    
Noff = length(find(diff(A)==-1)); %for SitLie: number of rises 
%length(Off) is not used, this would give one extra rise if interval is finished in sittting/lying position 