 function EVAactiGenerel3(ID,Type,Start,Slut,Akt,Fstep,OffHipTrunk12) %
 
% EVA analyse - Activity duration analysis (se document: EVA analysis by Acti4.pdf)
%
% Duration of the activity epocs according to a time classification scheme.
% The output from the analysis are not included in the standard output by Acti4, but saved in a separate user selected file.
 
   global FidEVA %initialiseres i ActiG ved start af 'Batch' 
   
   SETTINGS = getappdata(findobj('Tag','Acti4'),'SETTINGS'); %12/6-19
   WalkSlow = Fstep<SETTINGS.Threshold_slowfastwalk/60 & Akt==5; %slow walking
   Akt(Akt==5 & WalkSlow==1) = 5.1; %slow
   Akt(Akt==5 & WalkSlow==0) = 5.2; %fast
   Akt = AktFilt(Akt,'walkslow');
   Akt = AktFilt(Akt,'walkfast');

   % off,lie,sit,stand,move,walk,run,stair,cycle,row
   %  0 , 1 , 2 ,  3  ,  4 , 5  , 6 ,  7  ,  8  , 9
   Modes = {1,2,3,4,[5.1 5.2],5.1,5.2,6,7,8,9,... %basic
           [1 2],[3 4],[3 4 5.1 5.2 6 7],[3 4 5.1],[5.2 6 7 8 9]}; %combined
   ModeNames = {'Lie','Sit','Stand','Move','Walk','WalkSlow','WalkFast','Run','Stairs','Cycle','Row',...
                'LieSit','StandMove','OnFeet','LPA','MVPA'}; 
   Tint = [0,5,10,15,30,60,120,300,600,1200,1800,3600,7200,14400,28800,Inf]; %edges of time intervals for histc (sec)
   
   if isempty(FidEVA) %defineres som tom i ActiG ved start af 'Batch' (sikrer mulighed for at vælge ny fil når Batch køres igen)
       WB = get(actxGetRunningServer('Excel.Application'),'ActiveWorkbook'); %Finder Setup filen (12/6-19):
       SetupFil = get(WB,'Name');
      [FilNavn,Sti] = uiputfile('*.txt','Select file name for EVA results',[SetupFil(1:end-4),'_EVA']); %uiputfile checker for fil eksistens
      if isnumeric(FilNavn), return, end %Cancel selected
      Fil = fullfile(Sti,FilNavn);
      FidEVA = fopen(Fil,'w');
      fprintf(FidEVA,'LbNr, Type, Start, Stop, Time, OffThigh, OffHipTrunk, '); 
      for M=1:length(Modes)
          fprintf(FidEVA,['H_',ModeNames{M},' ,']); 
          for j=1:length(Tint)-1
              fprintf(FidEVA,'N_%s_T%s, H_%s_T%s, ',ModeNames{M},num2str(j),ModeNames{M},num2str(j));
          end
      end
      fprintf(FidEVA,'\r\n');
   end
   
   OffThigh = sum(Akt==0)/3660; %Thigh off time
   OffHipTrunk = sum(OffHipTrunk12)/3600;
   Time = 24*(Slut-Start);
   StartT = datestr(Start,'dd/mm/yyyy/HH:MM:SS');
   StopT = datestr(Slut,'dd/mm/yyyy/HH:MM:SS');
   fprintf(FidEVA,'%s, %s, %s, %s, %8.5f, %8.5f, %8.5f, ',ID,Type,StartT,StopT,Time,OffThigh,OffHipTrunk);
       
   for M=1:length(Modes)
       Mode = Modes{M}; %Activity for EVA analysis (or more activities merged)

       %merging:
       Imode = zeros(size(Akt'));
       for i=1:length(Mode)
           Imode(Akt==Mode(i)) = 1;
       end

       SSmode = [find(diff([0;Imode])==1),find(diff([Imode;0])==-1)]; %start and stop of 'mode' intervals.
       SSdur = SSmode(:,2)-SSmode(:,1) +1; %length of intervals (seconds)
       [Eva,SumBin] = deal(zeros(1,length(Tint)-1));
       if ~isempty(SSdur)
           Aux = histc(SSdur,Tint);
           Eva = Aux(1:end-1); 
           for i = 1:length(Tint)-1
               SumBin(i) = sum(SSdur(Tint(i)<=SSdur & SSdur<Tint(i+1)))/3600;
           end
       end
       SumMode = sum(SumBin); %total time of 'Mode'
       fprintf(FidEVA,'%8.5f, ',SumMode);
       for i=1:length(Tint)-1
           fprintf(FidEVA,'%d, %8.5f, ',Eva(i),SumBin(i));
       end
   end 
   fprintf(FidEVA,'\r\n');


