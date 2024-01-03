function Off = OffFnc(Pos,V,Acc,SF,Tid,Ntype,OnOffMan)

% Estimation of 'Off' periods for accelerometers
%
% Calls the function 'NotWorn' for estimation of not-worn periods. For sleep periods the not-worn criteria is modified
% so not-worn periods with less than 50% of not-worn are considered worn. Manually selected off intervals (Setup) overrule 
% the automatic procedure.
%
% Input:
% Pos [string]: Either Thigh, Hip, Arm or Trunk.
% V [N,3]: Inclination, forward/backward angle, sideways angle (rad), (calculated by the function 'Vinkler')
% A [N,3]: Acceleration (G), (calculated by the function 'Vinkler').
% SF: Sample time (N=SF*n).
% Tid [n]: Time array (1 sec. step, datenum values).
% Ntype: One of the numbers 0, 1, 2, 3 or 4 refeering to the diary activities A1, A2, A3, A4, B1, B2, B3, B4, C0 or C4,
%        only Ntype=4 refeering to a sleep periods does matter.
% OnOffMan [n,4]: Indices for forced worn/not worn (column corresponds to Thigh, Hip, Arm, Trunk)
%
% Output:
% Off [n]: Array of 0/1, 1 = Not-worn, 0 = worn

Off = NotWorn(V,Acc,SF); % Estimation of not-worn periods 
Off = Night(Off,Tid,Ntype); %Night time modification
%Manual selected periods of worn/not-worn overrules the above procedure:
Npos = strcmp(Pos,{'Thigh','Hip','Arm','Trunk'});
Off(OnOffMan(:,Npos)==1) = 0;
Off(OnOffMan(:,Npos)==0) = 1;


function OffOut = Night(OffIn,T,Ntype)
    %If Ntype=4 it is a sleep interval and the actual start/end times are
    %used (only if called from 'Batch')
    T = rem(T,1);
    if ~isempty(Ntype) && Ntype==4
       NightStart = T(1);
       NightEnd = T(end);
    else
       NightStart = 22/24;
       NightEnd = 8/24;
    end
    Inight = T>NightStart | T<NightEnd;
    OffOut = OffIn;  
    if all(~Inight) %no night time at all
       return
    else
       %Find start and end of night periods (more than 1 is possible)
       Idiff = diff([false,Inight,false]);
       InightS = find(Idiff==1); %night period starts
       InightE = find(Idiff==-1)-1; %night period ends
       for i=1:length(InightS)
          Nnight(i) = InightE(i)-InightS(i)+1;
          %If Off-time in night periods is < 50%, no Off-time at all:
          if sum(OffIn(InightS(i):InightE(i))==1)/Nnight(i) < .5, 
             OffOut(InightS(i):InightE(i)) = 0;
          end
       end
    end