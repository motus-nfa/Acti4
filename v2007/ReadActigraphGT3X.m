function [Acc,SF,StartActi,SN] = ReadActigraphGT3X(File,Start,End)

% Read data from ActiGraph GT3X file, only ActiLife ver. 5
%
% In version 20xx: old synchronization method is removed: SFmult=1
%
% Output parameters:
%   Acc: Acceleration ([:,3] matrix), unit G
%
% Input parameters:
%   File: input file
%   Start: start time of data to read (optional, all data read if missing)
%   End: stop time of data to read (optional, data read to end of file if missing)
%   SFmult: correction factor to sample frequency for optimal synchronization 
%           with other Actigraph recordings (optional) 
%   Start and End must be datenum variables.
%
%   Number of input parameters:
%   1 input parameter or Start is empty: all data read
%   2 input parameters: data read from Start
%   3 input parameters: data read from Start to End
%   4 input parameters: Start and End time is calculated by means of SF*SFmult

SFmult=1; %old synchronization cancelled

[SN,SF,StartActi,EndActi,~,~,ByteStart,Nsamples] = GT3Xinfo(File);

Kal = single(6/2047); %Calibration factor

Fid = fopen(File,'r','b');
fseek(Fid,ByteStart,'bof');

if nargin==1 || isempty(Start)
   Acc = Kal*single(fread(Fid,[3,Nsamples],'bit12=>bit16')');
else
   if Start<StartActi || EndActi<Start, error('Start-time error'), end 
   StartSample = round((Start-StartActi)*86400*SF);
   if nargin == 2
      if Start<StartActi, error('Start-time error'), end 
      N = Nsamples;
   end    
   if nargin > 2
      if End<StartActi || EndActi<End-5/86400, error('End-time error'), end
      %5 seconds uncertainty because of small differences in sample rate
      if End<Start, error('Start/End-time error'), end  
      if nargin == 4
         dT =  (Start-StartActi) - SFmult*(Start-StartActi);
         Start = Start + dT;
         End = End + dT;
         StartSample = round((Start-StartActi)*86400*SF);
      end
      N = round((End-Start)*86400*SF); %number of sample-sets (ch1,ch2,ch3) to read
   end
   if rem(StartSample,2) % StartSample odd
      fseek(Fid,round(4.5*(StartSample-1)),'cof');
      Acc = Kal*single(fread(Fid,[3,N+1],'bit12=>int16')');
      Acc = Acc(2:end,:);
   else % StartSample even
      fseek(Fid,round(4.5*StartSample),'cof');
      Acc = Kal*single(fread(Fid,[3,N],'bit12=>int16')');
   end
end

N = SF*fix(length(Acc)/SF); %make shure that number of samples corresponds to integer number of seconds,
Acc = Acc(1:N,:);

fclose(Fid);