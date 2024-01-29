function [StartActi,StopActi,SF] = CheckFiles(varargin)

% Check the accelerometer files for identical start time and sample frequency  
% If start times are different (for Axivity >5sec) a warning is displayed;  
% If sample frequencies are different an error message is shown and execution stops.

% Input:
% AccFiles {n,1} or {1,n}

% Output:
% StartActi [datenum]: The maximun start time of recordings (error corrected 2/3-16)
% StopActi [datenum]: The minimum stop times of all recordings with subtraction of 1 minut.
% SF: Sample frequency

% 13/9-16: This version of CheckFiles was selected to make StartActi = max(StartAcc), otherwise error showed up in ver. a.
% This version of CheckFiles was made for ver. b where input files were cell{n,1}, but for ver. a input files are cell{1,4},
% where hip/arm/trunk can be empty: 
AccFiles = varargin';
AccFiles = AccFiles(~cellfun(@isempty,AccFiles));

Ver = zeros(size(AccFiles)); %30/4-19: så kan ganle BAuA og 3F data læses
for i=1:size(AccFiles,1)
    [~,~,Ext] = fileparts(AccFiles{i});
     if strcmpi('.gt3x',Ext)
        CheckIfVersion5(AccFiles{i},1); %if not, error
        [~,SFacc(i),StartAcc(i),StopAcc(i)] = GT3Xinfo(AccFiles{i});
     end
     if strcmpi('.act4',Ext), [~,SFacc(i),StartAcc(i),StopAcc(i),~,~,~,~,Ver(i)] = ACT4info(AccFiles{i}); end
     
     if Ver(i) == 1 %Actigraph file
        if StartAcc(i) ~= StartAcc(1), FejlStart(AccFiles{i},AccFiles{1},StartAcc(i),StartAcc(1)), end %start time error
        if SFacc(i) ~= SFacc(1), FejlSF(AccFiles{i},AccFiles{1},SFacc(i),SFacc(1)), end %sample frequency error
     end
     if Ver(i) == 2 %Axivity file; if any Start deviates more than 5 sec re. thigh Start, a warning is displayed (added 13/9-16)
        if abs(StartAcc(i) - StartAcc(1)) >5/86400, FejlStart(AccFiles{i},AccFiles{1},StartAcc(i),StartAcc(1)), end %start time error
        if SFacc(i) ~= SFacc(1), FejlSF(AccFiles{i},AccFiles{1},SFacc(i),SFacc(1)), end %sample frequency error
     end
end

StartActi = max(StartAcc); %2/3-2016: must be the latest start for the group; 

% ½ minute is subtracted in order to include synchronization uncertainty:
%StopActi = min(StopAcc) - .5/1440; %2/3-16: mayby unnessary now
StopActi = max(StopAcc); %9/12-19: NaNs are used missing data
SF = SFacc(1);
%...................................................................................................................   
   
function FejlStart(FilX,FilThigh,StartX,StartThigh)
       warndlg({'START TIME DIFFERENCE:';'';[FilX,': ',datestr(StartX)];'';[FilThigh,': ',datestr(StartThigh)]})
       
function FejlSF(FilX,FilThigh,SFX,SF)
       errordlg({'SAMPLE FREQUENCY ERROR:';'';[FilX,': ',int2str(SFX),'Hz'];'';[FilThigh,': ',int2str(SF),'Hz']})
       error(' ')
 
       