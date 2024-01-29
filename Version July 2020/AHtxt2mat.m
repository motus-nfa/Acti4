function AHtxt2mat

% Convert ActiHeart IBI text files to Matlab data files (.txt to .mat).
%
% Select one or more ActiHeart IBI text files and data will be stored as Matlab
% data files in the same directory. Beats times are stored in the vector 'Tbeat' (datenum) and
% interbeat intervals as 'RR' (millisec.).

[FileNames,PathName] = uigetfile('*.txt','Select ActiHeart IBI textfiles','MultiSelect','on');
if isnumeric(FileNames), return, end %Cancel

cd(PathName)
FileNames = sortrows(FileNames);
if isnumeric(FileNames), return, end % Cancel was selected
if ischar(FileNames), FileNames = {FileNames}; end % Only one file selected

h = waitbar(0);
for i=1:length(FileNames)
  waitbar((i-1)/length(FileNames),h,['Wait..., now converting ',FileNames{i},' (',int2str(i),' of ',int2str(length(FileNames)),')'])
  File = fullfile(PathName,FileNames{i});
  Fid = fopen(File);
   FP = textscan(Fid,'%s',1,'Delimiter','\n');
   Start = textscan(Fid,'%s%s',1);
   StartDate = datenum(strrep(Start{1},'okt','oct'));
   Datatxt = textscan(Fid,'%s%s');
  fclose(Fid);
  
  Times = Datatxt{1,1};
  Times = strrep(Times,'.',','); %in some time strings "." is found instead of "," 
  T = rem(datenum(Times,'HH:MM:SS,FFF'),1);
  %ActihHeart times includes only time not date information 
  Ilast = find(diff(T)<-.5); %index for last beat of the day
  if ~isempty(Ilast)
    Ilast = [Ilast;length(T)];
    for j=1:length(Ilast)-1 %day information is added:
      T(Ilast(j)+1:Ilast(j+1)) = j + T(Ilast(j)+1:Ilast(j+1));
    end
  end
  Tbeat = T + StartDate;  
  RR = str2double(strrep(Datatxt{1,2},',','.')); %interbeat distances  
   
  save([File(1:end-3),'mat'],'Tbeat','RR') 
  
end
close(h)
