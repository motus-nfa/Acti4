function Cwa2Acti4

% Convert AX3 cwa-files to binary data file (.Act4) to be used by Acti4, and save in the same directory as the cwa-file.
% Calibration optional.
% Data are saved to a file name like Actigraph recordings, but AX3 serial number is added.
% Data are resampled to 30 Hz. 
% The floating point data of the cwa-data are converted to integers: Data = 1000*(Data+10) 
% See end of below function 'Convert' for file structure

%Ask for calibration and if orientation needs to be changed:
[Kalibration, Orientation] = Calibrate_ChangeAxesOrientation; %Kalibration - 1/0, Orientation: 1 - no change, 2 - up/down, 3 - in/out, 4 - both 
if Orientation == 5, return, end %Cancel

[FileNames,PathName] = uigetfile('.cwa','Select AX3 cwa-files','MultiSelect','on');
if isnumeric(FileNames), return, end %Cancel

cd(PathName)
if ischar(FileNames), FileNames = {FileNames}; end % Only one file selected
%Sortering efter løbenr. (ID):
for i=1:length(FileNames)
    ID(i) = str2double(FileNames{i}(end-13:end-4));
end
[~,ii] = sortrows(ID');
FileNames = FileNames(ii);

%Find local user numbers of AX3 units in AxivityNumbers.xlsx and join to file name list:
%First column in AxivityNumbers must contain the Axivity serial numbers and the second the local number (or text);
%data must start in row 2 (use 1 header line) of AxivityNumbers sheet.
AX3NoFile = [fileparts(which('Acti4')),'\AxivityNumbers.xlsx'];
AX3table = [];
if exist(AX3NoFile,'file')
   [~,~,AX3table] = xlsread(AX3NoFile);
end
FileNameNum = FileNames; %if no local numbers available
if ~isempty(AX3table) %AxivityNumbers.xlsx found
  for i=1:length(FileNames) %add local numbers:
      j = find(str2double(FileNames{i}(1:5))==cell2mat(AX3table(2:end,1)))+1; %find row with actual AX3 unit
      if ~isempty(j)
         No{i} = AX3table{j,2};
         if ~isnan(No{i}) %AX3 unit has a local number (or text) 
            if isnumeric(No{i}), No{i} = num2str(No{i}); end
            FileNameNum{i} = [FileNames{i},' (',No{i},')']; %combined filename and local number of AX3 unit
         end
      end
  end
end

hTableFig = figure('MenuBar','none','Position',[100,200,550,400]);
axes('Units','pixels','Position',[20 50 525 350])
axis off
text(175,325,'Select positions','Units','pixels','Fontsize',12)
hTable = uitable(hTableFig,'Data',cat(2,FileNameNum',num2cell(false(size(FileNames,2),6))),...
                 'ColumnName',{'Filename','Thigh','Hip','Arm','Back','Front','Calf'},...
                 'ColumnFormat',{'char','logical','logical','logical','logical','logical','logical'},...
                 'ColumnEditable',[false,true,true,true,true,true,true],...
                 'Position',[20 50 507 300],...
                 'ColumnWidth',{175 50 50 50 50 50 50});
uicontrol('Style','Togglebutton','String','OK','Callback','uiresume','Units','pixels','Position',[400 15 50 20],'FontSize',10);
hCancel = uicontrol('Style','Togglebutton','String','Cancel','Callback','uiresume','Units','pixels','Position',[300 15 50 20],'FontSize',10);
uiwait

if get(hCancel,'Value'), close(hTableFig), return, end
Data = get(hTable,'Data');
Pos = cell2mat(Data(:,2:7));
PosNames = {'Thigh','Hip','Arm','Back','Front','Calf'};

h = waitbar(0);
for i=1:length(FileNames)
  waitbar((i-1)/length(FileNames),h,['Wait..., now converting file ',num2str(i),' of ',num2str(length(FileNames))])
  if sum(Pos(i,:)) ~= 1
     hWarn = warndlg({'Missing or illegal selection for ',FileNames{i},'File not processed!'}); 
  else
    Convert(fullfile(PathName,FileNames{i}),PosNames{Pos(i,:)},Kalibration,Orientation)
  end
end
if exist('hWarn','var'), waitfor(hWarn), end
close(hTableFig)
close(h)


function Convert(File,Pos,Kalibration,Orientation)

SF = 30; %read cwa file and resample to 30Hz: 
[D,Start,info] = ReadCWA(File,SF);

[PathName,FileName] = fileparts(File);
SN = num2str(FileName(1:5)); %the first 5 digits of the file name = serial number of AX3


        %SesId = num2str(info.sessionId); %10 available digits:
        %File name also contain sessionId, but could have been changed/corrected afterwards,
        %so maybe best to use filename
       

% FileSaveName: Data are saved to file name like Actigraph recordings, but AX3 serial number is added.
% In FileName last 5 characters must be the ID and first 5 characters must be AX3 serial number.
FileSaveName = [FileName(end-4:end),'_',Pos,'_',datestr(Start,'(yyyy-mm-dd)'),'_',FileName(1:5),'.act4'];  

if Orientation > 1
   D = ChangeAxes(D,'Axivity',Orientation);
end

AccType = 2;
if Kalibration
   [Dcal,Exit] = AutoCalibration(D,SF,SN,FileSaveName);
   if ~strcmp(Exit,'Failed')
      D = Dcal;
      AccType = 21; %calibrated accelerometer type: '1' added 
   end
end

Data = uint16(1000*(-D+10)); %OBS: data transformed to integer (2 bytes) and shift of sign for all axis (-)
Nsamples = length(Data);
End = Start + (Nsamples-1)/SF/86400; %end time of recording
Stop = NaN;
Down = NaN;

Fid = fopen(fullfile(PathName,FileSaveName),'w'); %overwrite if exist
fprintf(Fid,'%s',repmat(' ',100)); %first part of file flushed with 'spaces'
fseek(Fid,0,'bof');
fprintf(Fid,'%d\n',AccType); %version 2 file (21 if calibrated), converted cwa data
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
