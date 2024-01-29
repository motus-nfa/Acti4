function OK = CheckIfVersion5(File,ErrFlag)

% Checks if the gt3x file is an ActiLife version 5 type; otherwise (version 6) it must be converted to an act4 file type
% OK is true for version 5, false otherwise
% If ErrFlag is 1, execution stops if OK is false

     Fid = fopen(File);
     Txt = fread(Fid,1000,'*char')';
     fclose(Fid);
     Str5 = ['8',char(0),'gt3xplus']; %this string seems only to found in ActiLife 5 versions of gt3x files
     if isempty(strfind(Txt,Str5))
        OK = false;  %version is not 5
        [~,Name,Ext] = fileparts(File);
        if ErrFlag
           errordlg([Name,Ext,' must be converted to "act4" file type'])
           error(' ')
        end
     else
        OK = true; %version is 5
     end