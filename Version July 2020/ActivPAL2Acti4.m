function ActivPAL2Acti4

% Convert ActivPAL csv-files to binary data file (.act4) to be used by Acti4, and save in the same directory as the ActivPAL file.
% Data are saved to a file name like Actigraph recordings, but ActivPAL serial number is added.
% Calibration optional.
% Data are resampled to 30 Hz. 
% ActivPAL accelerations are converted to integers [1000*(Data+10)] and stored in the .act4 file (se end of function for file structure)
% Bit resolution of data must be 10.

[Kalibration,Orientation] = Calibrate_ChangeAxesOrientation;
if Orientation == 5, return, end %Cancel

[FileNames,PathName] = uigetfile('.csv','Select exported ActiPAL data files (csv)','MultiSelect','on');
if isnumeric(FileNames), return, end %Cancel
if ischar(FileNames), FileNames = {FileNames}; end % Only one file selected
cd(PathName);

hTableFig = figure('MenuBar','none','Position',[100,200,525,400]);
axes('Units','pixels','Position',[20 50 450 350])
axis off
text(160,325,'Select positions','Units','pixels','Fontsize',12)
hTable = uitable(hTableFig,'Data',cat(2,FileNames',num2cell(false(size(FileNames,2),5))),...
                 'ColumnName',{'Filename','Thigh','Hip','Arm','Back','Front'},...
                 'ColumnFormat',{'char','logical','logical','logical','logical','logical'},...
                 'ColumnEditable',[false,true,true,true,true,true],...
                 'Position',[20 50 480 300],...
                 'ColumnWidth',{175 50 50 50 50 50});
uicontrol('Style','Togglebutton','String','OK','Callback','uiresume','Units','pixels','Position',[400 15 50 20],'FontSize',10);
hCancel = uicontrol('Style','Togglebutton','String','Cancel','Callback','uiresume','Units','pixels','Position',[300 15 50 20],'FontSize',10);
uiwait

if get(hCancel,'Value'), close(hTableFig), return, end
Data = get(hTable,'Data');
Pos = cell2mat(Data(:,2:6));
PosNames = {'Thigh','Hip','Arm','Back','Front'};

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

SF = 30; %read bin file and resample to 30Hz: 
[D,Start,SN,ID] = ReadActivPALcsv(File,SF);

[PathName,FileName] = fileparts(File);
     
FileSaveName = [ID,'_',Pos,'_',datestr(Start,'(yyyy-mm-dd)'),'_',SN,'.act4'];         
File =fullfile(PathName,FileSaveName);
if Orientation > 1
   D = ChangeAxes(D,'ActivPAL',Orientation);
end

D = -D; 
 
AccType = 3; %ActivPAL accelerometer
if Kalibration
   [Dcal,Exit] = AutoCalibration(D,SF,SN,FileSaveName);
   if ~strcmp(Exit,'Failed')
      D = Dcal;
      AccType = 31; %calibrated accelerometer type: '1' added 
   end
end

WriteAct4(D,File,AccType,SN,SF,Start)



% for i = 1:length(FileNames)
%   waitbar((i-1)/length(FileNames),h,['Wait..., now converting file ',num2str(i),' of ',num2str(length(FileNames))])  
%   Fil = fullfile(PathName,FileNames{i}); %datafil
%   [D,Start,SN,ID] = ReadActivPALcsv(Fil,30);
%   End = Start + (size(D,1)-1)/(30*86400);
% 
%   D = ChangeAxes(D,'ActivPAL',Orientation);
%   
%   ts = strfind(FileNames{i},'-'); %tankestregspositioner
%   Pos = FileNames{i}(1:ts(1)-1); %accelerometerpositioner er første del af ActivPAL-filenavnet (ActivPAL 'Download id')
%   % FileSaveName: Data are saved to file name like Actigraph recordings, but PAL serial number is added.
%   FileSaveName = [num2str(ID),'_',Pos,'_',datestr(Start,'(yyyy-mm-dd)'),'_',SN,'.act4']; 
%   
%   AccType = 3;
%   if Kalibration
%      [Dcal,Exit] = AutoCalibration(D,30,SN,FileSaveName);
%      if ~strcmp(Exit,'Failed')
%         D = Dcal;
%         AccType = 31; %calibrated accelerometer type: '1' added 
%      end
%   end
%   
%   %Nu gemmes i act4 fil:
%   Data = uint16(1000*(-D+10)); %OBS: data transformed to integer (2 bytes) and shift of sign for all axis (-)
%   Nsamples = length(Data);
%   Stop = NaN;
%   Down = NaN; %kunne findes i %DownloadLog filen
%   
%   Fid = fopen(fullfile(PathName,FileSaveName),'w'); %overwrite if exist
%   fprintf(Fid,'%s',repmat(' ',100)); %first part of file flushed with 'spaces'
%   fseek(Fid,0,'bof');
%   fprintf(Fid,'%d\n',AccType); %version 3 file, converted PAL data
%   fprintf(Fid,'%s\n',SN);
%   fprintf(Fid,'%d\n',30);
%   fprintf(Fid,'%f\n',Start);
%   fprintf(Fid,'%f\n',End);
%   fprintf(Fid,'%f\n',Stop);
%   fprintf(Fid,'%f\n',Down);
%   fprintf(Fid,'%d\n',Nsamples);
% 
%   fseek(Fid,100,'bof'); %data always start at byte 100
%   fwrite(Fid,Data','uint16');
%   fclose(Fid);
% end
% close(h)








