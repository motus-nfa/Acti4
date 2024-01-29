function Sens2Acti4

% Convert Sens bin-files to binary data file (.act4) to be used by Acti4, and save in the same directory as the Sens-file.
%
% Data are saved to a file name like Actigraph recordings, but Sens serial number is added.
% Sens filenames: Character 1:5 must be ID and 7:14 Sens ser.no.!!

%Ask for calibration and if orientation needs to be changed:
[Kalibration, Orientation] = Calibrate_ChangeAxesOrientation; %Kalibration - 1/0, Orientation: 1 - no change, 2 - up/down, 3 - in/out, 4 - both 
if Orientation == 5, return, end %Cancel

[FileNames,PathName] = uigetfile('.bin','Select Sens bin-files','MultiSelect','on');
if isnumeric(FileNames), return, end %Cancel

cd(PathName)
if ischar(FileNames), FileNames = {FileNames}; end % Only one file selected
%Sortering efter løbenr. (ID).
for i=1:length(FileNames)
    ID(i) = str2double(FileNames{i}(1:5));
end
[~,ii] = sortrows(ID');
FileNames = FileNames(ii);

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
[D,Start] = ReadSENSbin(File,SF);

[PathName,FileName] = fileparts(File);
ID = FileName(1:5);
SN = num2str(FileName(7:14)); % characters 7:14 must be serial number of Sens
     
FileSaveName = [ID,'_',Pos,'_',datestr(Start,'(yyyy-mm-dd)'),'_',SN,'.act4'];         
File =fullfile(PathName,FileSaveName);
if Orientation > 1
   D = ChangeAxes(D,'Sens',Orientation);
end

AccType = 4; %Sens accelerometer
if Kalibration
   [Dcal,Exit] = AutoCalibration(D,SF,SN,FileSaveName);
   if ~strcmp(Exit,'Failed')
      D = Dcal;
      AccType = 41; %calibrated accelerometer type: '1' added 
   end
end

%Side with Sens no. must be outwards 
D = -D; %for TEKSTSIDEN UDAD!

WriteAct4(D,File,AccType,SN,SF,Start)


