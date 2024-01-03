function ActivityExport(ID,Time,Activity,SETTINGS,Varm,IonArm,SF)

% Export of 1 sec. data for Activity, Time and Arm inclination (degrees) to selected folder.
% Filenames are ID_HHMM-ddmmyy (ID and start of data)

persistent ExportFolder

if isempty(ExportFolder)
  ExportFolder = uigetdir('','Select folder for saving exported files');
  %The selection will apply for the rest of the session
end
if ~ischar(ExportFolder), return, end %Cancel selected

if nargin==7 %Arm data
   Varm(~IonArm) = NaN; 
   Varm = round(180*nanmean(reshape(Varm,SF,[]))/pi); %middel pr. sek
end


if SETTINGS.ActivityExportTxt %Export to text file
   FileTxt = fullfile(ExportFolder,[ID,'_',datestr(Time(1),'HHMM-ddmmyy'),'.txt']);
   Fid = fopen(FileTxt,'w+');
   Str = datestr(Time,'dd-mm-yyyy HH:MM:SS');
   if nargin==7
      for i=1:length(Activity), fprintf(Fid,'%s, %d, %d\r\n',Str(i,:),Activity(i),Varm(i)); end
   else
      for i=1:length(Activity), fprintf(Fid,'%s, %d\r\n',Str(i,:),Activity(i)); end
   end
   fclose(Fid);
end 

if SETTINGS.ActivityExportMat %Export to Matlab file
   FileMat = fullfile(ExportFolder,[ID,'_',datestr(Time(1),'HHMM-ddmmyy'),'.mat']);
   if nargin==7
      save(FileMat,'ID','Time','Activity','Varm'); 
   else
      save(FileMat,'ID','Time','Activity');
   end
end 


