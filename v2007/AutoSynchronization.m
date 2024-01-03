function AutoSynchronization

% Automatic synchronization of selected sets of act4-files (9/12-19, 4/5-20)
%
% One ore more set of act4-files for thigh, back, arm etc are
% automatically synchronized by means of covariance analysis. The thigh
% file is the reference file (must be present), and the other file are linearly
% synchronized/resampled to match (maximum covariance) the thigh file. 
% The synchronized file sets are saved in a selected folder with the same names
% (if no save folder is selected, synchronization procedure is run without any saving)
% Covariance are calculated for 30 sec. interval and for all intervals with 
% correlation coefficient above 0.4 a robust linear fit are calculated. 
% If median absolute deviation (MAD) exceeds 1 sec. or the intervals included in the fit 
% span less than 25% of the entire range, a warning is given for uncertain synchronization result.     

graph = 0;
Ans = questdlg('Show synchronization graphs?','','Yes','No','Yes');
if strcmp(Ans,'Yes'), graph=1; end

[FileNames,PathName] = uigetfile('.act4','Select act4-files for synchronizaton','MultiSelect','on');
if isnumeric(FileNames), return, end
cd(PathName);
cd ..
SaveFolder = uigetdir([],'Select folder for saving calibrated act4-files');
if strcmp(SaveFolder,PathName(1:end-1))
   Ans = questdlg('act4-file will be overwritten!','Warning','OK','Cancel','Cancel');
   if strcmp(Ans,'Cancel'), return, end
end

%Find the IDs by the thigh files:
LegTxt = {'thigh','leg','femur','ben','lår'};
IDs = unique(cellfun(@(x) x(1:5),FileNames,'UniformOutput',false));

for i = 1:length(IDs)
    %First, find the thigh file
    ThighFile = '';
    IDfiles = FileNames(strncmp(IDs{i},FileNames,5)); %files for IDs(i)
    for k=1:length(LegTxt)
        if any(cell2mat(strfind(lower(IDfiles),LegTxt{k})))
           ThighFile = IDfiles{~cellfun(@isempty,strfind(lower(IDfiles),LegTxt{k}))};
        end
    end
    if isempty(ThighFile)
       errordlg(['Thigh file not found for ID ',IDs{i}]);
       error(' ')
    end
    
    %Find the other files belonging to actual ID:
    [~,SF,Start] = AGinfo(fullfile(PathName,ThighFile));
    OtherFiles = IDfiles(~strcmp(IDfiles,ThighFile));
    Nchan = length(OtherFiles);
    X = cell(size(OtherFiles)); %for acceleration data
   
    %Read files:
    hMsg = msgbox({['Synchronization of ',num2str(Nchan+1),' act4-files by ID ',IDs{i}];...
                    '';'Reading files, wait...'},'CreateMode','replace');
    Athigh = ReadACT4(fullfile(PathName,ThighFile));
    if isempty(OtherFiles)
       warndlg(['No files found to synchronize with ',ThighFile])
    else
       for j=1:Nchan        
           [x,~,~,SN{j},Ver{j}] = ReadACT4(fullfile(PathName,OtherFiles{j}));
           X{j} = NaN(size(Athigh)); %4/5-20:
           x = x(1:min(end,length(Athigh)),:);
           X{j}(1:length(x),:) = x; %Now channels shorter than Athigh contains NaNs in the end
       end
       hMsg = msgbox({['Synchronization of ',num2str(Nchan+1),' act4-files by ID ',IDs{i}];...
                    '';'Synchronizing, wait...'},'CreateMode','replace');
       Xsync = Sync(Athigh,X,SF,OtherFiles,graph);
       if ~isnumeric(SaveFolder) %save selected
          hMsg = msgbox({['Synchronization of ',num2str(Nchan+1),' act4-files by ID ',IDs{i}];...
                    '';'Saving files, wait...'},'CreateMode','replace');
          if ~strcmp([SaveFolder,'\'],PathName)      
             copyfile(fullfile(PathName,ThighFile),fullfile(SaveFolder,ThighFile));
          end
          for j=1:Nchan
              SaveFile = fullfile(SaveFolder,OtherFiles{j});
              Ver{j} = str2double([num2str(Ver{j}),'2']); %2 added when synchronized
              WriteAct4(Xsync{j},SaveFile,Ver{j},SN{j},SF,Start)
          end
       end      
    end 
    if exist('hMsg','var'), delete(hMsg); end
end

function  Xsync = Sync(R,X,SF,OtherFiles,graph)
  
  N = length(R);
  nsek = 60;
  n = fix(N/(SF*nsek)); %number of nsek intervals
 
  Rrms = rms(R(:,[1 3]),2); %for covarians analyse (transverse axis not used)
  Xrms = cell2mat(cellfun(@(x) rms(x,2),X,'UniformOutput',false));

  Nchan = size(X,2);
  Corr = zeros(n,Nchan);
  Lag = NaN(n,Nchan);
  Xsync = cell(1,Nchan);

  for j=1:n; %every nsek
    iisync = nsek*SF*(j-1)+1:min(nsek*SF*(j+1),N);% +/- nsek intervals, 50% overlap
    if std(Rrms(iisync)) >.05 %some activity must be found
       Kryds = xcov([Rrms(iisync),Xrms(iisync,:)],2*nsek*SF,'coeff'); %max 2*nsek sec lag
       Kryds = Kryds(:,2:Nchan+1);
       [Corr(j,:),I(1:Nchan)] = max(Kryds);
       Lag(j,:) = 2*nsek*SF-I+1;
    end
  end

  t = (1:n)'*nsek/86400;
  tR = 0:length(R)-1;
  Fit = zeros(2,Nchan);
  Lfit = zeros(size(Lag));
  
  Lag(Corr<.4) = NaN; %changing this value can repair improper results
  if graph, hSync = figure('Units','Normalized','Position',[.55 .05 .4 min(.85,.1+Nchan*.19)]); end
  
  for k=1:Nchan
    disp(OtherFiles{k})  
    ii = ~isnan(Corr(:,k)) & ~isnan(Lag(:,k)); 
   
    if length(t(ii))>2
       warning('off')
       [Fit(1:2,k),stat] = robustfit(t(ii),Lag(ii,k),'bisquare',1);
       warning('on')
    elseif any(length(t(ii))== [1,2]) %17/2-20
       Fit(1:2,k) =  flip(polyfit(t(ii),Lag(ii,k),1));
       stat.mad_s = 0;
    elseif isempty(t(ii)) %17/2-20
       Xsync{k} = X{k};
       stat.mad_s = NaN;
    end
   
    Lfit(:,k) = polyval(flip(Fit(:,k)),t);
    SFratio = N/(N+Lfit(end,k)-Lfit(1,k));
    tX = polyval([SFratio,-Lfit(1,k)],0:length(X{k})-1);
    Xsync{k} = interp1(tX,X{k},tR,'linear',NaN); %outside values are set to NaN 
 
    if graph
       figure(hSync) 
       subplot(Nchan,1,k);
       plot(t(ii),Lag(ii,k)/SF,'k.',t,Lfit(:,k)/SF,'r')
       ylim([min(Lfit([1 end],k))/SF-2 max(Lfit([1 end],k))/SF+2])
       title(OtherFiles{k},'Interpreter','None')
       xlabel('day')
       ylabel('sec')
       text(.75,.075,['MAD = ',num2str(stat.mad_s/SF,'%6.3f')],'Units','Normalized')
       drawnow
    end
   
    if length(t(ii)) < 2 || stat.mad_s/SF > 1 || range(t(ii))/(t(end)-t(1)) < .25  %provisional
       text(.75,.9,'Uncertain!','Color',[1 0 0],'Units','Normalized')
       warndlg(['Uncertain synchronization for ',OtherFiles{k}])
    end
  end
 