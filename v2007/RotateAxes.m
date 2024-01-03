function RotateAxes

% Rotation of accelerometer axes (any 90° shift)
%
% By the RotationSelect figure a 90° axis shift can be specified. 
% act4-files are selected and rotated accordingly and saved with names indicating the selected rotation.
% The user must ensure that the selected axes shift is valid.


I = RotationSelect;
if isempty(I), return, end
%
[FileNames,PathName] = uigetfile('.act4','Select act4-files for axes rotation','MultiSelect','on');
if isnumeric(FileNames), return, end
if ~iscell(FileNames), FileNames={FileNames}; end

cd(PathName);

T = {'x','-x','y','-y','z','-z'};
r = [1,1,2,2,3,3;1,-1,1,-1,1,-1];

for i=1:length(FileNames)
    File = fullfile(PathName,FileNames{i});
    [Acc,SF,Start,SN,AccType] = ReadACT4(File);
     
     Acc = [r(2,I(1))*Acc(:,r(1,I(1))), r(2,I(2))*Acc(:,r(1,I(2))), r(2,I(3))*Acc(:,r(1,I(3)))];
     
    [~,Name] = fileparts(FileNames{i});
    rotname = [Name,'_Rot(',T{I(1)},T{I(2)},T{I(3)},').act4'];
    FileRot = fullfile(PathName,rotname); 
    disp([FileNames{i},' ---> ',rotname]) 
    WriteAct4(Acc,FileRot,AccType,SN,SF,Start)
end
  