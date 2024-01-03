function [IntMod,WorkDay] = Modify2Day(Int)
%
% Modify2Day takes as input the basic (diary) intervals and splits intervals, which include 2 dates,
% into 2 intervals according to date. Also returns a WorkDay parameter telling which day include a workday interval.
%
% Input: Int {N,5} (N is number of intervals) cellarray with type of interval in 1. column, weekday in 2. column,  
%        start times in 3. column and end times in 4. column (Column 5 is used for changing accelerometer axes)  
%        The intervals in Int must be chronological order. 
% Output: IntMod {Nmod,5}, cellarray like Int with midnight intervals split into 2 intervals.
%         Workday [Nmod], 1 if the date of the interval include a work interval (A2 or B2), 0 otherwise. 
% 1/4-14
% 11/5-20: column 5 in Int added (for changing accelerometer axes)

    Type = Int(:,1);
    StartTimes = Int(:,3); 
    EndTimes = Int(:,4);
    Col5 = Int(:,5); %11/5-20
    
    Start = floor(AfkodTid(StartTimes(1))); %start day of first interval 
    End = floor(AfkodTid(EndTimes(end))); %end day of last interval
    R = {}; %table of the modified intervals

    for i=Start:End %go through all the days
        fStart = floor(AfkodTid(StartTimes));%start days
        fEnd = floor(AfkodTid(EndTimes));%end days
        Li = find(i~=fStart & i==fEnd);
        if ~isempty(Li) %interval to split - second part of interval
            R = cat(1,R,{Type{Li},' ',datestr(i,'dd/mm/yyyy/HH:MM:SS'),EndTimes{Li},Col5{Li}});
        end
        Ai = find(i==fStart & i==fEnd); %intervals not to split
        R = cat(1,R,cat(2,Type(Ai),cell(size(Ai)),StartTimes(Ai),EndTimes(Ai),Col5(Ai)));
        Fi = find(i==fStart & i~=fEnd);
        if ~isempty(Fi) %interval to split - first part of interval
           R = cat(1,R,{Type{Fi},' ',StartTimes{Fi},datestr(i+1,'dd/mm/yyyy/HH:MM:SS'),Col5{Fi}}); 
        end
        R = R((AfkodTid(R(:,4))-AfkodTid(R(:,3))~=0),:); %remove an interval with duration 0
    end
    R(:,2) = num2cell(weekday(AfkodTid(R(:,3))-1));
    IntMod = R;
    
    WorkInt = find(strncmp('A2',IntMod(:,1),2) | strncmp('B2',IntMod(:,1),2)); %work
    StartNew = IntMod(:,3);
    WorkDay = zeros(size(StartNew));
    for k=1:size(WorkInt)
        WorkDay(strncmp(StartNew(WorkInt(k)),StartNew,10)) = 1;
    end