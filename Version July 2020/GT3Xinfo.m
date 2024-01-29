function [SN,SF,Start,End,Stop,Down,IbyteStart,Nsamples] = GT3Xinfo(File)

% Read basic information in ActiGraph gt3x-file (ver. 5, zip-file) necessary for reading binary acceleration data.

% Output:
% SN: Serial number of ActiGraph unit
% SF: Sample frequency (Hz)
% Start: Start time of recording (datenum value)
% End: End time of recording (datenum value)
% Stop: Stop time of recording (datenum value or NaN if stop time was not set)
% Down: Download time of recording (datenum value)
% IbyteStart: Byte offset for start of recorded data (only ActiLife ver. 5)
% Nsamples: Number of samples sets (triple value) in recording (only ActiLife ver. 5)

% ActiLife ver. 5:
% The GT3X file is a zip-archive including several uncompressed files of which two are 
% the 'info.txt' (SN, SF, Start etc. information) and 'activity.bin' (recorded binary data) files.
% The reading of information in zip file is not formally correct
% General references to zip file structure:
% http://en.wikipedia.org/wiki/ZIP_(file_format)
% http://www.pkware.com/documents/APPNOTE/APPNOTE_6.2.0.txt

% ActiLife ver. 6:
% The data GT3X file is compressed and this function does not return information that 
% can be used for reading of the acceleration data. The function GT3Xinfo is not used by the 'Acti4' 
% for ActiLife ver. 6 files (ACT4info is used to read the converted GT3X -> ACT4 files), however it 
% returns correctly the first 6 output parameters.

if nargin == 0
    [FileName,PathName] = uigetfile('.gt3x','Select Actigraph gt3x-file');
    if ~ischar(FileName), return, end  %cancel
    File = [PathName,FileName];
    cd(PathName);
end 

if ~exist(File,'file')
   errordlg({'ACTIGRAPH GT3X-FILE NOT FOUND:';'';File})
   error(['ACTIGRAPH GT3X-FILE NOT FOUND: ',File])
end

%Read last part of (zip) file which include the 'info.txt' file and central
%directory:
Fid = fopen(File,'r');
fseek(Fid,-3000,'eof');
A = fread(Fid,Inf,'*char')';

%Find and read text data from 'info.txt':
InfoTextStart = strfind(A,'Serial Number');
InfoTxt = A(InfoTextStart:InfoTextStart+300); %increase if to include subject data 
Info = textscan(InfoTxt,'%s','Delimiter','\n');
Info = Info{1};
SNline = char(Info(1));
SN = SNline(strfind(SNline,':')+2:end);
SFline = char(Info(strncmp('Sample Rate',Info,11)));
SF = str2double(SFline(strfind(SFline,':')+2:end));
Startline = char(Info(strncmp('Start Date',Info,10)));
Start = 367 + str2double(Startline(strfind(Startline,':')+2:end))/10^7/86400;
Stopline = char(Info(strncmp('Stop Date',Info,9)));
Stop = 367 + str2double(Stopline(strfind(Stopline,':')+2:end))/10^7/86400;
Downline = char(Info(strncmp('Download Date',Info,13)));
Down = 367 + str2double(Downline(strfind(Downline,':')+2:end))/10^7/86400;

%No stop time (0) found:
if Stop==367, Stop = NaN; end

if strcmp(SN(1:3),'NEO') %ActiLife version 5
   %Find the 'activity.bin' file name in the central directory and read the
   %position (just before) of the local file:
   aux = strfind(A,'activity.bin'); 
   ActFileHeadPos = typecast(cast(A(aux-4:aux-1),'uint8'),'uint32');
   fseek(Fid,ActFileHeadPos+22,'bof'); %position of file size in local file header
   Nbytes = fread(Fid,1,'uint32'); %number of bytes in file
   LengthFE = sum(fread(Fid,2,'uint16')); %sum of file name length and extra field length 
   fseek(Fid,LengthFE,'cof'); %Start position of data:
   IbyteStart = ftell(Fid);
   Nsamples = Nbytes/4.5; %1 sample-set = 3 x 12bits = 36bits = 4.5bytes
   End = Start + Nsamples/SF/86400;
end

if strcmp(SN(1:3),'CLE') %ActiLife version 6
    if isnan(Stop), End = Down; else End = Stop; end
    [IbyteStart,Nsamples] = deal([]); 
end

fclose(Fid);