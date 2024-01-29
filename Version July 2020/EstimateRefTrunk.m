function [VrefTrunk,Obs] = EstimateRefTrunk(ID,Vtrunk,SF,Akt,OffTrunk,BF) 

% Estimation of reference angle for trunk accelerometer.
% Trunk reference angle is estimeated for each interval in the setup file. The calculation is based on 
% an investigation of 50 measurements from the BAuA project, in which is was found that 
% the average difference between the trunk angle during walk and upright standing was 6 (+/-6) degrees (29/5-19)
 
 persistent oldID oldRef
 if isempty(oldID) || ~strcmp(oldID,ID)  %first interval for ID: provisionel reference
    oldID = ID;
    if BF==1
       oldRef = pi*[27 27 0]/180; %average back accelerometer angle
    else
       oldRef = pi*[10 10 0]/180; %tentative for front accelerometer
    end
 end
 VtrunkAccAP = median(reshape(Vtrunk(:,2),SF,length(Akt))); %ant/pos accelerometer angle 
 VtrunkAccLat = median(reshape(Vtrunk(:,3),SF,length(Akt))); %lat accelerometer angle
 v2 = median(VtrunkAccAP(Akt==5 & ~OffTrunk')) - pi*6/180;
 v3 = median(VtrunkAccLat(Akt==5 & ~OffTrunk'));
 VrefTrunk = [acos(cos(v2)*cos(v3)),v2,v3]; %sfærisk triangle
 
 Obs = '';
 if any(abs(VrefTrunk - oldRef) > pi*20/180)
    Obs = 'Unexpected shift in trunk reference angle'; 
 end
 if isnan(v2) || sum(Akt==5 & ~OffTrunk')<60 ... %less than ½ minute is not accepted
    || any(abs(VrefTrunk - oldRef) > pi*20/180)  %if new ref differ more than 20deg from old, probably better to use the old   
    VrefTrunk = oldRef; %no walking, use previous value 
 else
     oldRef = VrefTrunk;
 end
