function BodyguardSdf2mat

% Convert Firstbeat Bodyguard2 files to Matlab data files.

% Select Bodyguard2 sdf files (heart beat data) and corresponding zip-files (accelerometer data, optional).
% sdf files will be converted to mat files and zip files are converted to 'front' act4 accelerometer files.
% Beat times are stored in the vector 'Tbeat' (datenum) and interbeat intervals as 'RR' (millisec.). 
% Recordings with more files will be merged into one file (one mat and one act4 file)
% Output files are saved into the same directory as the input files.

[FileNames,PathName] = uigetfile({'*.sdf;*.zip'},'Select Bodyguard2 sdf/zip-files','MultiSelect','on');
if isnumeric(FileNames), return, end %Cancel

cd(PathName)
FileNames = sortrows(FileNames);
if ischar(FileNames), FileNames = {FileNames}; end % Only one file selected

IDs = cellfun(@(x) x(1:5),FileNames,'UniformOutput',false);
IDs = unique(IDs);
h = waitbar(0);
for i=1:length(IDs)
    waitbar((i-1)/length(IDs),h,{'Wait..., now converting ';[FileNames{i},' (',int2str(i),' of ',int2str(length(IDs)),')']})
    Files = fullfile(PathName,FileNames(strncmp(IDs(i),FileNames,5))); %An ID may have more recordings, which will be merged
    ERsdf = cellfun(@(x) ~isempty(x),strfind(Files,'.sdf'));
    sdfFiles = Files(ERsdf);
    
    %Find start time and sort accordingly (27/4-20):
    for j=1:length(sdfFiles)
       Fid = fopen(sdfFiles{j});
       fgetl(Fid);fgetl(Fid);
       STARTTIME = fgetl(Fid);
       Start(j) = datenum(STARTTIME(11:end),'dd.mm.yyyy HH:MM.SS');
       fclose(Fid);
    end
    [~,I] = sort(Start);
    sdfFiles = sdfFiles(I);
  
    SN = FileNames{1}(7:10);
    RR = [];
    Tbeat = [];
    for j=1:length(sdfFiles) %must be sorted according to start time
       Fid = fopen(sdfFiles{j});
       fgetl(Fid);fgetl(Fid);
       STARTTIME = fgetl(Fid);
       Start = datenum(STARTTIME(11:end),'dd.mm.yyyy HH:MM.SS');
       fgetl(Fid);fgetl(Fid);
       RRtext = textscan(Fid,'%d');
       rr{j} = double(RRtext{1});
       tbeat{j} = Start + cumsum([0;rr{j}(1:end-1)/1000])/86400;
       fclose(Fid);
    end
    for k = 1:length(sdfFiles) %merge more recordings
        if k>1, RR(end) = 86400*(tbeat{k}(1)-tbeat{k-1}(end)); end
        RR = [RR;rr{k}];
        Tbeat = [Tbeat;tbeat{k}];
    end
    save(fullfile(PathName,[IDs{i},'.mat']),'Tbeat','RR');
    
    %processing of optional acceleromter files:
    ERzip = cellfun(@(x) ~isempty(x),strfind(Files,'.zip'));
    AccFiles = Files(ERzip);
    if ~isempty(AccFiles)
       ReadBodyguardAccFile(IDs{i},SN,AccFiles,PathName) 
    end
end
close(h)


function ReadBodyguardAccFile(ID,SN,AccFiles,PathName)
%Read and convert accelerometer data to 'front' act4 file. 
for j=1:length(AccFiles)
   CsvFile = unzip(AccFiles{j},PathName); %temporary unzipped file, will be deleted again
   Fid = fopen(CsvFile{1});
   STARTTIME = fgetl(Fid);
   start(j) = datenum(STARTTIME(strfind(STARTTIME,';')+1:end),'dd.mm.yyyy HH:MM.SS');
   GSCALE = fgetl(Fid);
   gscale = str2double(GSCALE(strfind(GSCALE,';')+1:end-1));
   SAMPLING = fgetl(Fid);
   sf = str2double(SAMPLING(strfind(SAMPLING,';')+1:end-2));
   SAMPLESIZE = fgetl(Fid);
   bit = str2double(SAMPLESIZE(strfind(SAMPLESIZE,';')+1:end-3));
   fgetl(Fid);
   D = textscan(Fid,'%*d%d%d%d','CollectOutput',true,'Delimiter',';');
   fclose(Fid);
   delete(CsvFile{1});

   A = gscale/2^(bit-1) * double(D{1});
   t = (0:length(A)-1)/sf;
   SF = 30;
   Ac = interp1(t,A,0:1/SF:t(end),'spline'); %resample to 30 Hz
   Acc{j} = single([-Ac(:,2),Ac(:,1),Ac(:,3)]); %Bodyguard accelerometer orientation changed
end

   Dact4 = dir( [ID,'_Thigh*.act4']);
   if isempty(Dact4)
       errordlg({['Thigh/act4-file not found for ID: ',ID];'(Convert accelerometer data before BodyGuard files)'})
       error(' ')
   else
   [~,~,StartThigh,EndThigh] = ACT4info(Dact4.name);
   end
   %Thigh accelerometer determines the start/end-time, normally the thigh accelerometer starts before HR recordings 
   %Merge more files, breaks are set to NaN
   N = round(SF*86400 *(EndThigh - StartThigh)); %number of samples to be found in merged file (if more files) 
   ACC = single(nan(N,3)); %merged accelerations, NaN in breaks 
   for j=1:length(start)
       ns = round(SF*86400*(start(j)-StartThigh));
       if ns>=0
           ACC(ns+1:ns+length(Acc{j}),:) = Acc{j}; %normal case where thigh accelerometer starts before Bodyguard accelerometer
       else
           ACC(1:ns+length(Acc{j}),:) = Acc{j}(1-ns:end,:); %a special case where a Bodyguard file starts before the thigh accelerometer
       end
   end
   
   Start = StartThigh;
   %Convert to .act4 file:
   Data = uint16(1000*(ACC+10)); %OBS: data transformed to integer (2 bytes), breaks (NaN) are transformed to 0
   Nsamples = length(Data);
   End = Start + (Nsamples-1)/SF/86400; %end time of recording
   Stop = NaN;
   Down = NaN;

   FileSaveName = [num2str(ID),'_Front_',datestr(Start,'(yyyy-mm-dd)'),'_',SN,'.act4']; 
   Fid = fopen(fullfile(PathName,FileSaveName),'w'); %overwrite if exist
   fprintf(Fid,'%s',repmat(' ',100)); %first part of file flushed with 'spaces'
   fseek(Fid,0,'bof');
   fprintf(Fid,'%d\n',4); %version 4 file, converted Bodyguard2 accelerometer data
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
  
