
function [Data,Start,info] = ReadCWA(filename, interpRate)

% Reads and resamples cwa file.
%
% This is a combination of resampleCWA and resampleACC from OpenMovement.
% This function calls AX3_readFile, which use the mex funtions parseDate.mexw64 and parseValueBlock.mexw64 

info = AX3_readFile(filename, 'verbose',0, 'info',1,'useC',1);
startTime = info.validPackets(1,2);
stopTime  = info.validPackets(end,2);

%large files are divided into part to avoid memory troubles (and excessive processing time):
N = ceil(length(info.validPackets)/500000); %number of interval parts   
dT = (stopTime-startTime)/N; %duration of interval part
for i=1:N
    start = max([startTime+(i-1)*dT - 5/86400, startTime]); %5 seconds extra data in the start to create overlap to previous part
    stop = min([startTime+i*dT,stopTime]);
    data = AX3_readFile(filename, 'validPackets', info.validPackets, 'startTime', start, 'stopTime', stop,'useC',1);

    %  Remove any duplicate timestamps
    data.ACC = data.ACC(diff(data.ACC(:,1))>0,:); %this line was repeated in 'resampleCWA' ?
   % data.ACC = data.ACC(diff(data.ACC(:,1))>0,:); 

   start = fix(data.ACC(1,1)*86400)/86400; %fix to interger second time
   stop = fix(data.ACC(end,1)*86400)/86400;

   t = linspace(start, stop, (stop - start) * 24 * 60 * 60 * interpRate);

   %dataintp = interp1(data.ACC(:,1),(data.ACC(:,2:4)),t,'cubic',0); % extra memory required
   for j=1:3
       dataintp(:,j) = single(interp1(data.ACC(:,1),data.ACC(:,j+1),t,'pchip',0)); %data.ACC must be double if 'cubic' is selected
   end

   if i==1 %first interval part
      T = t;
      Data = dataintp; 
   else % next interval part is merged to the end of the previous part:
      In = find(abs(T(end)-t(1:1000))<.001/86400); %find end time of previous part in the next part
      T = [T,t(In+1:end)];
      Data = [Data;dataintp(In+1:end,:)]; 
   end
   clear t dataintp

end
Start = T(1);      



