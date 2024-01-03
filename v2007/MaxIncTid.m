function [MaxTid,Imax] = MaxIncTid(V,Iok,Threshold,SF)

% MaxIncTid finds the maximal length of a period with a inclination above 'Threshold'.
%
% Input:
% V [N]: Array of inclination values (rad) for arm or trunk. 
% Iok [N]: Array of logical values; values of V for which Iok is false, are set to 0 (below Threshold angle)  
% Threshold: Threshold angle (rad)
% SF: Sample frequency
%
% Output:
% MaxTid: Length (seconds) of maximum period with V>Threshold
%
% A 5 second median filter is included to remove short 'pauses'

V = V(1:SF:end);
Iok = Iok(1:SF:end);
Iv = medfilt1(double(V),5)>Threshold; %medfilt: a 1 or 2 sec. 'pause' is removed
Iv(~Iok) = 0;
OpNed = diff([0;Iv;0]);
Op = find(OpNed==1);
Ned = find(OpNed==-1);
Tider =(Ned-Op);
[MaxTid,I] = max(Tider); %in seconds
Imax = Op(I);
if isempty(Tider), MaxTid = 0; end