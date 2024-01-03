function [VMCPS,CPS] = AGcounts(Acc,SF)
%Calculation of Actigraph counts

% Input: 
%    Acc [n,3]: raw acceleration
%    SF: sample frequency

% Output:
%    VMCPS: Vector Magnitude Counts Per Second
%    CPS [n,3]: Counts Per Second

if isempty(Acc)
   [VMCPS,CPS] = deal([]);
   return
end

F = [flipud(Acc(1:300,:));Acc]; %add 10 sec dummy to avoid initial erroneous filter response

 [Blp1,Alp1] = cheby1(4,.088,4.8/(SF/2),'low');
 F = filter(Blp1,Alp1,F);
 
 [Blp2,Alp2] = cheby1(2,.496,1.244/(SF/2),'low'); 
 F = filter(Blp2,Alp2,F);
 
 [Bhp,Ahp] = butter(2,.2421/(SF/2),'high');
 F = filter(Bhp,Ahp,F);
 
 F = F(301:end,:); %remove dummy data
 
 F = abs(F);
 F = 19.6*F-.393;
 F(F<.977) = 0;
 
 CPS = round(squeeze(sum(reshape(F,SF,[],3))));
 VMCPS = sqrt(sum(CPS.^2,2));