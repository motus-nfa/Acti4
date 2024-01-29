 function [VrefThigh,Obs] = EstimateRefThigh(ID,AccThigh,Vthigh,SF,T) 

 % Estimation of reference angle for leg accelerometer.
 % Leg reference angle is estimeated for each interval in the setup file. The calculation is based on 
 % an investigation of 50 measurements from the BAuA project, in which is was found that 
 % average FBthigh angle was 11 (+/-3.0) degrees during walking (14/1-19)
  
 persistent oldID oldRef
 if isempty(oldID) || ~strcmp(oldID,ID) %first interval for ID: provisionel reference for calculation of Akt
    oldID = ID;
    oldRef =  pi*[16,-16,0]/180; %
 end
 Akt = ActivityDetect(AccThigh,SF,T,oldRef,'0');
 korr = pi*11/180; %average Forward/Backward angle during walk (BAuA)
 VthighAccAP = mean(reshape(Vthigh(:,2),SF,length(Akt))); %ant/pos accelerometer angle
 VthighAccLat = mean(reshape(Vthigh(:,3),SF,length(Akt))); %lat accelerometer angle
 v2 = median(VthighAccAP(Akt==5)) - korr;
 v3 = median(VthighAccLat(Akt==5));
 VrefThigh = [acos(cos(v2)*cos(v3)),v2,v3]; %sfærisk triangle
 
 Obs = '';
 if any(abs(VrefThigh - oldRef) > pi*20/180)
    Obs = 'Unexpected shift in thigh reference angle'; 
 end
 if isnan(v2) || sum(Akt==5)<30 ... %less than ½ minute is not accepted
    || any(abs(VrefThigh - oldRef) > pi*20/180) %if new ref differ more than 20deg from old, probably better to use the old 
    VrefThigh = oldRef;
 else
    oldRef = VrefThigh; %for calculation of Akt for the next interval for ID 
 end
 