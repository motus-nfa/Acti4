function [SN,SF,Start,End,Stop,Down,IbyteStart,Nsamples,Ver] = ACT4info(File)

%Reads header information of .act4-file.

if ~exist(File,'file')
   errordlg({'ACT4 DATA FILE NOT FOUND:';File;'';'(Maybe caused by wrong directory specified in Info-sheet in Setup-file)'})
   error(' ')
end

Fid = fopen(File,'r');
Ver = str2double(fgetl(Fid)); %version no.
SN = fgetl(Fid); %Serial number of ActiGraph unit
SF = str2double(fgetl(Fid)); %Sample frequency (Hz)
Start = str2double(fgetl(Fid)); %Start time of recording (datenum value)
End = str2double(fgetl(Fid)); %End time of recording (datenum value)
Stop = str2double(fgetl(Fid)); %Stop time of recording (NaN if stop time was not set)
Down = str2double(fgetl(Fid)); %Download time of recording (datenum value)
IbyteStart = 100; %Byte offset for start of recorded data, always 100
Nsamples = str2double(fgetl(Fid)); %Number of samples sets (triple value) in recording
fclose(Fid);
