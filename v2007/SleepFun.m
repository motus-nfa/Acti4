function Sleep = SleepFun(Akt,Acc,SF,Position)

% Estimation of sleep during lying. 
% Sleep is estimated in each second for lying periods longer than 15 minutes from thigh,
% arm (preferable) or trunk accelerometer.
%
% Input:
% Akt: Activity vector (1 sec time scale))
% Acc [N,3]: Acceleration matrix
% SF: Sample frequency (30 Hz)
% Position (string): Thigh, Arm or Trunk
%
% Output:
% Sleep: Vector (size as Akt), 1 for wake, 0 for sleep

Sleep = ones(size(Akt)); %all awake

%Find lying periods lomger than 15 minutes:
DiffLie = diff([0;Akt'==1;0]);
LieInt = [find(DiffLie==1),find(DiffLie==-1)-1];
Int15 = LieInt(LieInt(:,2)-LieInt(:,1)>60*15,:);
if isempty(Int15) %return if no lying periods longer than 15 minutes are found (all awake)
   return
end
    
[Bbp,Abp] = butter(6,[.5 10]/(SF/2)); %båndpasfilter 0.5-10 Hz
 Acc = filter(Bbp,Abp,Acc);
 
 A = mean(reshape(sqrt(sum(Acc.^2,2)),SF,[]));
 A(A<.02) = 0; %remove background noise

 % Algorithm constants for the different acceleromters:
 K = [exp(-1/(60*18.5)), .19; ...  %Thigh (time constant 18.5 min, gain .19)
      exp(-1/(60*20)), .15;...    %Arm (time constant 20 min, gain .15)
      exp(-1/(60*21)), .24];     %Trunk (time constant 21 min, gain .24)

 k = K(strcmp(Position,{'Thigh','Arm','Trunk'}),:); %select the constants
 
 for i=1:size(Int15,1)
     sleep = Calc(A(Int15(i,1):Int15(i,2)),k);
     Sleep(Int15(i,1):Int15(i,2)) = sleep;
 end
 Sleep = medfilt1(Sleep,19);
 Sleep(isnan(A)) = NaN;

 function sleep = Calc(A,k)
  I = zeros(size(A));
  I0 = exp(1);
  Iprev = I0; %fully awake
  for i = 1:length(A)
    I(i) = k(1)*Iprev + k(2)*A(i);
    Iprev = min(I0,I(i));
  end
  sleep = I>1;
  wt = find(diff(sleep)==1); %wake up time is considered to be 2 minutes a head:
  for j=1:length(wt)
      sleep(max(1,wt(j)-120):wt(j)-1) = 1; 
  end
  
