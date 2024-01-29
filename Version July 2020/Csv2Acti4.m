function Csv2Acti4

% Conversion of Actigraph csv-files to .act4 format.
%
% Convert Actigraph csv-files (exported from gt3x-file by ActiLife) to a
% binary data file (.act4) to be used by Acti4, and save in the same directory as the csv-file.
% Calibration optional.
% The floating point data in the csv-file are converted to integers: Data = 1000*(Data+10) 
% See end of below function 'Convert' for file structure

%Ask for calibration and if orientation needs to be changed:
[Kalibration, Orientation] = Calibrate_ChangeAxesOrientation; %Kalibration - 1/0, Orientation: 1 - no change, 2 - in/out, 3 - up/down, 4 - both 
if Orientation == 5, return, end %Cancel

[FileNames,PathName] = uigetfile('.csv','Select Actigraph csv-files','MultiSelect','on');
if isnumeric(FileNames), return, end %Cancel

cd(PathName)
FileNames = sortrows(FileNames);
if isnumeric(FileNames), return, end % Cancel was selected
if ischar(FileNames), FileNames = {FileNames}; end % Only one file selected

h = waitbar(0);
for i=1:length(FileNames)
  waitbar((i-1)/length(FileNames),h,['Wait..., now converting file ',num2str(i),' of ',num2str(length(FileNames))])
  Convert(fullfile(PathName,FileNames{i}),Kalibration,Orientation)
end
close(h)


function Convert(File,Kalibration,Orientation)

Fid = fopen(File,'r');
  Line = fgetl(Fid);
  %Find the ActiLife version (from v6.11.5 first 2 column in Data are interchanged), 6/5-15
  ActiLifeVer = Line(strfind(Line,'ActiLife')+10:strfind(Line,'Firmware')-2);
  Vercomp = cellfun(@str2num,regexp(ActiLifeVer,'\.','split'));
  
  Hzpos = strfind(Line,'Hz');
SF = str2double(Line(Hzpos-4:Hzpos-1)); % sample frequency
  Line = fgetl(Fid);
SN = Line(end-12:end); % serial number
  Line = fgetl(Fid);
StartTime = Line(end-8:end); %start time of recording
  Line = fgetl(Fid);
StartDate = Line(end-10:end); %start date of recording
StartDate = strrep(StartDate,'/','-'); %if "/" is found instead of "-"
  fgetl(Fid);
  Line = fgetl(Fid);
DownTime = Line(end-8:end); %download time 
  Line = fgetl(Fid);
DownDate = Line(end-10:end); %download date
DownDate = strrep(DownDate,'/','-'); %if "/" is found instead of "-"

Start = datenum(StartDate,'dd-mm-yyyy') + rem(datenum(StartTime,'HH:MM:SS'),1); 
Down = datenum(DownDate,'dd-mm-yyyy') + rem(datenum(DownTime,'HH:MM:SS'),1);

Data =  textscan(Fid,'%f32,%f32,%f32','Headerlines',3,'CollectOutput',1);
if isempty(Data{1}), Data =  textscan(Fid,'%f32,%f32,%f32','Headerlines',1,'CollectOutput',1); end 
if isempty(Data{1}), Data =  textscan(Fid,'%f32,%f32,%f32','Headerlines',1,'CollectOutput',1); end
%These extra reading attempts have been included because it seems that in some Actilife versions a extra
%header line ('Axis1,Axis2,Axis3') can be included (28/5-14).
if isempty(Data{1}) %if 'comma' is used as decimal point (26/5-14):
   errordlg({'No data found in ';File;'Probably due to wrong decimal point selection in computer setup.'},'Conversion error');
   error(' ');
end 
fclose(Fid);

Data = Data{1};

if Orientation > 1
   Data = ChangeAxes(Data,'ActiGraph',Orientation);
end

[PathName,Name] = fileparts(File);

AccType = 1;
if Kalibration
   [DataCal,Exit] = AutoCalibration(Data,SF,SN,Name);
   if ~strcmp(Exit,'Failed')
      Data = DataCal; 
      AccType = 11; %calibrated accelerometer type: '1' added 
   end
end

Data = uint16(1000*(Data+10)); %OBS: data transformed to integer (2 bytes)************************************
%from v6.11.5 first 2 column in Data are interchanged), 6/5-15
if Vercomp*[10^6,10^3,1]' >= 6011005
   Data = [Data(:,2),Data(:,1),Data(:,3)]; 
end

Nsamples = length(Data);
End = Start + (Nsamples-1)/SF/86400; %end time of recording
Stop = NaN; %Stop time (the time at which the AG was set to stop the recording) was used in ActiLife 5, but is not found 
% in the csv-file downloaded with ActiLife (6 only?).

Fid = fopen([fullfile(PathName,Name),'.act4'],'w'); %overwrite if exist

fprintf(Fid,'%s',repmat(' ',100)); %first part of file flushed with 'spaces'
fseek(Fid,0,'bof');
fprintf(Fid,'%d\n',AccType); %version 1 file (.Acti4)
fprintf(Fid,'%s\n',SN);
fprintf(Fid,'%d\n',SF);
fprintf(Fid,'%f\n',Start);
fprintf(Fid,'%f\n',End);
fprintf(Fid,'%f\n',Stop);
fprintf(Fid,'%f\n',Down);
fprintf(Fid,'%d\n',Nsamples);

fseek(Fid,100,'bof'); %data always start at byte 100
fwrite(Fid,Data','uint16');
fclose(Fid);
