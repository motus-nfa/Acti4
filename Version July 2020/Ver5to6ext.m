function File = Ver5to6ext(AGAH,File)
% Adding file extension for old ver. 5 Actilife 
% Originally, setup-files using ActiLife ver. 5 gt3x datafiles, file extension were
% not included in the setup file. This function adds the missing extension.
[~,~,Ext] = fileparts(File);
if isempty(Ext)
   if strcmp(AGAH,'AG'), File = [File,'.gt3x']; end
   if strcmp(AGAH,'AH'), File = [File,'.mat']; end
end