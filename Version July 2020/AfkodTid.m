function Time  = AfkodTid(TimeString)

% Converts the timestring used in Setup-files to a datenum value

Time = datenum(TimeString,'dd/mm/yyyy/HH:MM:SS');