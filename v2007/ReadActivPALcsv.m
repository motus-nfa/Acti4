function [Data,Start,SN,ID] = ReadActivPALcsv(Fil,SF)

% Reads csv data exported from ActiPAL recordings (10bit,+/-4G), Ver. 2, 26/3-2020
%
% Reads compressed or uncompressed ActiPAL csv files and interpolate data to sample frequency SF
  
  %File name information:
  [~,FileName] = fileparts(Fil);
  ts = strfind(FileName,'-'); %ActivPAL danner filnavn med '-' som adskillelse mellem div. oplysninger, så 'download id' må ikke indeholde '-' 
  if length(ts)<5 || length(ts)>6
     errordlg({'Illegal number of hyphens ("-") in filename';FileName},'File name error')
     error(' ')
  end
  if length(ts)==6 %optional ID text has been entered during download of recorded data
     ID = FileName(ts(1)+1:ts(2)-1);
     rest = FileName(ts(2)+1:end);
  elseif length(ts)==5 %no optional ID text has been entered during download of recorded data
     ID = FileName(1:ts(1)-1);
     rest = FileName(ts(1)+1:end);
  end
  SN = rest(1:8); %Accelerometer serienummer, regner med at der altid er på 8 karakterer!
  ts = strfind(rest,'-'); %new ts
  StartTxt = rest(ts(1)-10:ts(1)+4);
  Start = datenum(StartTxt,'ddmmmyy HH-MMam'); %Starttid med minutopløsning (ingen sekund data i filnavn), am/pm ligegyldigt

  %Import af data fra csv-datafilen:
  Rec = importdata(Fil,';',2);
  time = Rec.data(:,1);  
  it = Rec.data(:,2); %sampleindex 
  acc = Rec.data(:,size(Rec.data,2)-2:size(Rec.data,2)); %last 3 columns
  clear Rec
  
  if length(it) < it(end)+1 %Compressed data
     t = interp1(it,time,0:it(end),'linear');
     Acc = interp1(time,acc,t,'nearest');
  else %uncompresses data
     t = time;
     Acc = acc;
  end
  
  tSF = time(1):1/(SF*86400):time(end); %30 Hz times
  Grange = 2*4; %range +/-4G
  Data = (interp1(t,Acc,tSF,'linear')-(1023+4)/2) * (Grange/(1023-4)); %interpolation 
  
  

 
