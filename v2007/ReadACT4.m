function [Acc,SF,StartActi,SN,AccType] = ReadACT4(File,Start,End)
%Rev: 8/1-18
%Read data from .act4 file
%
%Output parameters:
%   Acc: Acceleration ([:,3] matrix), unit G

%Input parameters:
%   File: full input file
%   Start: start time of data to read
%   End: stop time of data to read
%   Start and End must be datenum variables.
%
%   If Start and End are missing or Start is empty: all data red
%   Hvis der forsøges at læse data efter slut på fil, sættes Acc=0 for intervallet efter slut (tillægges så Off status senere)

[SN,SF,StartActi,EndActi,~,~,ByteStart,N,AccType] = ACT4info(File);

Fid = fopen(File,'r');
fseek(Fid,ByteStart,'bof');

if nargin==1 || isempty(Start)
   Acc = single(fread(Fid,[3,N],'uint16')')/1000-10;
else
   if Start>End || Start<StartActi || End<StartActi, ReadError(File,StartActi,Start,End), end
   N = round((End-Start)*86400*SF); %number of sample-sets (ch1,ch2,ch3) to read
   StartSample = round((Start-StartActi)*86400*SF);
   if EndActi<End %forsøg på at læse data efter EndActi -> Acc=NaN (får Off status i NotWorn)
      Acc = single(NaN(N,3));
      Npart = fix((EndActi-Start)*86400*SF); %antal eksisterende samples
      if Npart>0
         fseek(Fid,6*StartSample,'cof'); %2*3 bytes per sample
         Acc(1:Npart,:) = single(fread(Fid,[3,Npart],'uint16')')/1000-10; %conversion from integers to real acceleration (G)
      end
   else %alle samples eksisterer:
      fseek(Fid,6*StartSample,'cof'); %2*3 bytes per sample
      Acc = single(fread(Fid,[3,N],'uint16')')/1000-10; %conversion from integers to real acceleration (G)
   end
end
fclose(Fid);
N = SF*fix(length(Acc)/SF); %make shure that number of samples corresponds to integer number of seconds,
Acc = Acc(1:N,:);

Acc(Acc==-10) = NaN; %restoring NaNs that have been saved as 0 in act4 files


function ReadError(File,StartActi,Start,End) %3/2-16
  errordlg({'ILLEGAL TIME COMBINATION READING FILE:';...
            File;...
            ['Accelerometer start: ',datestr(StartActi,'dd/mm/yyyy HH:MM:SS.FFF')];...
            ['Interval start: ',datestr(Start,'dd/mm/yyyy HH:MM:SS.FFF')];...
            ['Interval end: ',datestr(End,'dd/mm/yyyy HH:MM:SS.FFF')]});
  error(' ')
  
  
  