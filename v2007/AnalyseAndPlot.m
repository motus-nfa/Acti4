function [AktTid,IncTid,AH,HRRdist] = AnalyseAndPlot(ID,FilThigh,FilHip,FilArm,FilTrunk,VrefThigh,~,VrefTrunk,ThresTrunk,ThresArm,...
                                     SF,Start,Slut,Ylab,Vis,PlotMappe,OnOffManInt,Ntype,Tbeat,RR,ActiHeartDelay,HRrest,HRmax,Type,Pause,ColHeadAct,ColHeadInc,ShiftAxes)

% Principal function for reading, analysis and graphing of accelerometer and heartrate data for specified interval.
%
% Input:
% ID [string]: 5 character (digits) identification of subject.
% FilThigh [string]: Full name of AGthigh file.
% FilHip [string]: Full name of AGhip file.
% FilArm [string]: Full name of AGarm file.
% FilTrunk [string]: Full name of AGtrunk file.
% VrefThigh [3]: Angles of reference position for AGthigh [Inc, Forward/bachward, Sideways] (rad). 
% VrefTrunk [3]: Angles of reference position for AGtrunk [Inc, Forward/bachward, Sideways] (rad). 
% ThresTrunk [4]: Interval angles (deg) for trunk inclination summary.  
% ThresArm [5]: Interval angles (deg) for arm inclination summary.                             
% SF: Sample frequency.                                 
% Start: Start time of interval (datenum value).
% Slut: End time of interval (datenum value).
% Ylab [2 cell]: Cell array of activity labels, (1) if data is found for AGthigh and AGhip/AGtrunk
%                and (2) if only AGthigh data exists.
% Vis: Flag (0/1) for graphing of data (1) or not (0).
% PlotMappe [string]: Directory for export of graphs (if empty no export).
% OnOffManInt [cell]: Specification of manual/forced worn/not-worn intervals if any (a code for which AG and start/stop times)
% Ntype: Type (0,1,2,3,4) of diary period (digit from A1,A2,A3,A4,B1,B2,B3,B4,C0,C4).
% Type: A1,A2,A3,A4,B1,B2,B3,B4,C0,C4
% Tbeat: Array of datenum values for heart beats.
% RR: Array of inter-beat intervals (msec) of heart beats.
% ActiHeartDelay: Delay (sec) of AH re AG.
% HRrest: Resting heart rate (beats per sec) for calculation of HRR.
% HRmax: Calculated maximum heart rate (beats per sec) for calculation of HRR.
% ColHeadAct: Headings for output file. 
% ColHeadInc: Headings for output file.
% ShiftAxes{4,1}: For possible shift of accelerometer axis (se function CheckBatchString)
%
% Output: Definition and units of the below parameters are found in document Acti4OutputParameters.docx.
% AktTid: Time,HipOff,HipTrunkOffLS,VrefThighAP,VrefThighLat,ThighOff,lie,sit,stand,move,walk,run,stairs,cycle,row,sleep,Steps,
%              SitLie_Tmax,SitLie_P50,SitLie_T50,SitLie_P10,SitLie_P90,SitLie_T30min,SitLie_N30min,Nrise,Stand_Tmax,StandMove_Tmax,
% IncTid: ArmOff,IncArm30,IncArm60,IncArm90,IncArm120,IncArm150,IncArmMax90,
%              IncArmSit30,IncArmSit60,IncArmSit90,IncArmSit120,IncArmSit150,IncArmSitMax90,
%              IncArmStandMove30,IncArmStandMove60,IncArmStandMove90,IncArmStandMove120,IncArmStandMove150,IncArmStandMoveMax90,
%              IncArmUpright30,IncArmUpright60,IncArmUpright90,IncArmUpright120,IncArmUpright150,IncArmUprightMax90,
%              NArmInc,IncArmPrctile10,IncArmPrctile50,IncArmPrctile90,IncArmVelRMS,IncArmVelPrctile10,IncArmVelPrctile50,IncArmVelPrctile90,
%         VrefTrunkAP,VrefTrunkLat,TrunkOff,ForwIncTrunk20,ForwIncTrunk30,ForwIncTrunk60,ForwIncTrunk90,IncTrunkMax60,
%              ForwIncTrunkSit20,ForwIncTrunkSit30,ForwIncTrunkSit60,ForwIncTrunkSit90,IncTrunkSitMax60,
%              ForwIncTrunkStandMove20,ForwIncTrunkStandMove30,ForwIncTrunkStandMove60,ForwIncTrunkStandMove90,IncTrunkStandMoveMax60,
%              ForwIncTrunkUpright20,ForwIncTrunkUpright30,ForwIncTrunkUpright60,ForwIncTrunkUpright90,IncTrunkUprightMax60,
%              IncTrunkWalk.
% AH: AHTime,NBeat,BeatErrPct,HRmin,HRmean,HRsleep,HRRmean,HRoff,HRlie,HRsit,HRstand,HRmove,HRwalk,HRrun,HRstairs,HRcycle,HRrow,HRsleep,
%              HRRoff,HRRlie,HRRsit,HRRstand,HRRmove,HRRwalk,HRRrun,HRRstairs,HRRcycle,HRRrow.
% HRRdist [100]: HRR_1,HRR_2,...HRR_100.
%
% If the user includes a function Acti4ExternFunction(D), it will be excecuted for each call to AnalyseAndPlot.
% se line 558 for structure of input variabel D.

 SETTINGS = getappdata(findobj('Tag','Acti4'),'SETTINGS'); %data from AnalysisSetup

[AccThigh,AccHip,AccTrunk,AccArm] = deal([]);  %All of these variable must exist if 
[Vthigh,Vhip,Vtrunk,Varm3,HRf,RRf] = deal([]); %Acti4ExternFunction is going to be called
OffHipTrunk = [];
ObsThighRef = '';

if ~isempty(FilThigh) %11/5-19: to make it possible to view heart rate data alone

 [Vthigh,AccThigh] = Vinkler(FilThigh,Start,Slut,ShiftAxes(1));
 T = Start + (0:length(AccThigh)-1)/SF/86400;
 if isnan(VrefThigh(1)) %no reference interval found
    [VrefThigh,ObsThighRef] = EstimateRefThigh(ID,AccThigh,Vthigh,SF,T); %15/1-19
 end
 
 % Find the type of the thigh accelerometer, important for SENS accelerometers only (20/2-20)
 AccThighVer = '0';
 [~,~,Ext] = fileparts(FilThigh);
 if strcmpi(Ext,'.act4')
    [~,~,~,~,~,~,~,~,AccThighVer] = ACT4info(FilThigh);
    AccThighVer = num2str(AccThighVer);
 end
    
 [Akt,Tid,FBthigh,StdThigh] = ActivityDetect(AccThigh,SF,T,VrefThigh,AccThighVer);

 %Finds manual (forced) worn (on)/ not worn (off) intervals if any:
 OnOffMan = NaN(length(Tid),4); %columns refer to: leg, hip, arm and back Actigraph positions
 if ~isempty(OnOffManInt)  
    StartOnOff = cell2mat(OnOffManInt(:,2));
    EndOnOff = cell2mat(OnOffManInt(:,3));
    Codes = reshape(str2num([OnOffManInt{:,1}]'),4,[])';
    %In case of more than one interval (i>1), the intervals must not overlap
    for i=1:size(Codes,1)
        for j=1:4 %leg, hip, arm and back Actigraph
            OnOffMan(StartOnOff(i) < Tid & Tid < EndOnOff(i),j) = Codes(i,j);
        end
    end
 end
 
 OffThigh = OffFnc('Thigh',Vthigh,AccThigh,SF,Tid,Ntype,OnOffMan); 
 Akt(OffThigh==1) = 0;
 [OffHip,OffTrunk,OffArm] = deal(ones(length(OffThigh),1)); %ones: if files are missing (whole period is off)
 
 Fstep = TrinAnalyse(AccThigh(:,1),Akt,SF);
 Akt(Akt==5 & Fstep>2.5) = 6; %Slow/quiet running correction could be misclassified as walk (24/10-12)
 Akt = AktFilt(Akt,'run'); %27/8-14
 Akt = AktFilt(Akt,'walk'); %31/3-16
 Ntrin = round(sum(Fstep(Akt==5|Akt==6|Akt==7)));
 AvgSpeed = mean(Fstep(Akt==5|Akt==6|Akt==7));

 WalkSlow = sum(Fstep<SETTINGS.Threshold_slowfastwalk/60 & Akt==5)/3600; %duration of slow walking, 3/6-19: changed from 100
 WalkFast = sum(Fstep>=SETTINGS.Threshold_slowfastwalk/60 & Akt==5)/3600; %duration of fast/moderate walking
 
 if ~isempty(FilHip)
    [Vhip,AccHip] = Vinkler(FilHip,Start,Slut,ShiftAxes(2));
    HipLie = Lying(AccHip,SF,65);
    OffHip = OffFnc('Hip',Vhip,AccHip,SF,Tid,Ntype,OnOffMan);
    HipLie(OffHip==1) = NaN;
    Akt(Akt==2 & HipLie'==1) = 1;
 end
 
 ThresTrunk = pi*ThresTrunk/180;
 TrunkData = NaN(1,4*(length(ThresTrunk)+1));
 IncTrunkWalk = NaN;
 ObsTrunkRef = '';
 BF = NaN;
 if ~isempty(FilTrunk)
    [Vtrunk,AccTrunk,AccTrunkFilt,Ltrunk] = Vinkler(FilTrunk,Start,Slut,ShiftAxes(4));
    OffTrunk = OffFnc('Trunk',Vtrunk,AccTrunk,SF,Tid,Ntype,OnOffMan);
    BF = BackFront(FilTrunk); %find from file name if trunk AG is at back (1) or front (-1)
    if isnan(VrefTrunk(1)) %no reference interval found
       [VrefTrunk,ObsTrunkRef] = EstimateRefTrunk(ID,Vtrunk,SF,Akt,OffTrunk,BF); %15/1-19
    end
    
    Rot1 = [cos(VrefTrunk(2)) 0 sin(VrefTrunk(2)); 0 1 0; -sin(VrefTrunk(2)) 0 cos(VrefTrunk(2))]; %ant/pos rotation matrix
    Rot2 = [cos(VrefTrunk(3)) sin(VrefTrunk(3)) 0; -sin(VrefTrunk(3)) cos(VrefTrunk(3)) 0; 0 0 1]; %lateral rotation matrix
    Rot = Rot1*Rot2; %first ant/pos then lat rotation
    Rot(:,2:3) = BF*Rot(:,2:3); %direction of y- and z-axes are reversed for front mounted AG
    AccTrunkRot = AccTrunkFilt*Rot;
    Vtrunkrot = real([acos(AccTrunkRot(:,1)./Ltrunk),-asin(AccTrunkRot(:,3)./Ltrunk),-asin(AccTrunkRot(:,2)./Ltrunk)]);
               %real: single/truncation calculation errors can produce complex part
    TrunkLie = Lying(AccTrunkRot,SF,45);
    TrunkLie(OffTrunk==1) = NaN; %means that TrunkLie not used for trunk off periods
    %Modification of sit/lie by trunkdata:
    Akt(Akt==1 & TrunkLie'==0) = 2; %lying hip and sitting trunk -> sitting
    Akt(Akt==2 & TrunkLie'==1 & OffHip'==1) = 1; %no hip data vailable so trunk inclination decides lying posture
    %31/8-12:sitting hip and lying trunk could mean: sitting and leaning forward or imprecise hip data,
    %if trunk is bacwards or sideways more than 45°, the posture is clsassified as lying (hip overruled):
    Ibackward45 = Vtrunkrot(1:SF:end,2)*180/pi<-45 | abs(Vtrunkrot(1:SF:end,3))*180/pi>45;
    Akt(Akt==2 & Ibackward45'==1 & OffTrunk'==0) = 1;
    %30/3-15: If hip not present: sitting and leaning forward have incorrectly been classified as lying, 
    Akt(OffTrunk'==0 & Akt==1 & Vtrunkrot(1:SF:end,2)'*180/pi>0 & FBthigh'>45 ) = 2; %Ej liggende hvis trunk fremad og ben fremad (5/12-18)
    Akt(OffTrunk'==0 & Akt==1  & abs(Vtrunkrot(1:SF:end,1)'- Vtrunkrot(1:SF:end,2)')*180/pi<10 & ...
        Vtrunkrot(1:SF:end,1)'*180/pi<65 & Vtrunkrot(1:SF:end,2)'*180/pi<65) = 2; %Trunk direkte frem op til 65 -> sidde (5/12-18)
    %27/1-20: OffTrunk'==0 tilfgøjet i 2 foregående linjer, ligge kunne blive fejlagtigt ændret til sidde i perioder med trunk off. 
    
    %Note: No distinction was made between lie and sit (lie not defined) when median filtering was done in ActivityDetect (aug14)
     % 29/5-15: disse 2 linjer var fejlagtigt (?) placeret efter linje 177 hvor optælling er foretaget
     Akt = AktFilt(Akt,'sit'); 
     Akt = AktFilt(Akt,'lie');
     
    IonTrunk = ~reshape(repmat(logical(OffTrunk'),SF,1),1,[])'; %Indices for which Trunk is not off
    IpositiveU = Vtrunkrot(:,2)>=0;
    InotLie = ~reshape(repmat(Akt==1|Akt==0,SF,1),1,[])'; %Indices for not lying (in order to exclude lying on the belly)
    %added 7/12-12: not lying must not include Akt==0 (if Akt==0 activity state is undefined) 
    IforwardInc = IonTrunk & InotLie & IpositiveU;
    IsitFwd = reshape(repmat(Akt==2,SF,1),1,[])' & IforwardInc; %Indices for sitting and forward inclined
    IstandmoveFwd = reshape(repmat(Akt==3|Akt==4,SF,1),1,[])' & IforwardInc; %Indices for stand/move and forward inclined
    IuprightFwd = reshape(repmat(3<=Akt&Akt<=7,SF,1),1,[])' & IforwardInc; %Indices for stand/move/walk/run/stair and forward inclined (oct13)
    for ith = 1:length(ThresTrunk)
        IncTrunk(ith) = sum(Vtrunkrot(IonTrunk,1) >= ThresTrunk(ith));
        PctTrunk(ith) = 100*IncTrunk(ith)/length(Vtrunkrot(IonTrunk,1));
        ForwardIncTrunk(ith) = sum(Vtrunkrot(IforwardInc,1) >= ThresTrunk(ith))/SF;
        ForwardIncTrunkSit(ith) = sum(Vtrunkrot(IsitFwd,1) >= ThresTrunk(ith))/SF;
        ForwardIncTrunkStandMove(ith) = sum(Vtrunkrot(IstandmoveFwd,1) >= ThresTrunk(ith))/SF;
        ForwardIncTrunkUpright(ith) = sum(Vtrunkrot(IuprightFwd,1) >= ThresTrunk(ith))/SF;  %oct13
    end
    IncTrunkMax60 = MaxIncTid(Vtrunkrot(:,1),IforwardInc,ThresTrunk(3),SF);
    IncTrunkSitMax60 = MaxIncTid(Vtrunkrot(:,1),IsitFwd,ThresTrunk(3),SF);
    IncTrunkStandMoveMax60 = MaxIncTid(Vtrunkrot(:,1),IstandmoveFwd,ThresTrunk(3),SF);
    IncTrunkUprightMax60 = MaxIncTid(Vtrunkrot(:,1),IuprightFwd,ThresTrunk(3),SF); %oct13
    TrunkData = [ForwardIncTrunk,IncTrunkMax60,ForwardIncTrunkSit,IncTrunkSitMax60,ForwardIncTrunkStandMove,IncTrunkStandMoveMax60,...
                 ForwardIncTrunkUpright,IncTrunkUprightMax60]; %oct13
    
    %Find median inclination of trunk during walk:
    Iw = Akt==5 & OffTrunk'==0; %walk and trunk not off
    if sum(Iw)>60 %if more than 1 minutes of walk is found
       Vtrunkplot = (180/pi)*Vtrunkrot(1:SF:end,:); 
       IncTrunkWalk = double(median(Vtrunkplot(Iw,1))); 
    end
 end
 
 %If both hip and trunk data are missing for an interval (or all time) lying is not
 %detected. At nighttime the activity of such interval is set to lying at
 %night and sitting at daytime:
 OffHipTrunk = OffHip & OffTrunk;
 if any(OffHipTrunk) && ~isempty(Ntype)
    if Ntype==4
       Akt(Akt==2 & OffHipTrunk'==1) = 1; %night
    else
       Akt(Akt==1 & OffHipTrunk'==1) = 2; %day
    end
 end
 OffHipTrunk12 = OffHipTrunk' & (Akt==1 | Akt==2); %uncertain sit/lie times

 AktTid = zeros(1,37);
 AktTid(1) = 24*(Slut-Start); %length of period
 if isempty(FilHip)
    AktTid(2) = NaN; 
 else
    AktTid(2) = sum(OffHip)/3600; %length of period in which hip accelerometer not worn 
 end
 AktTid(3) = sum(OffHipTrunk12)/3600; %length of uncertain sit/lie period determination
 AktTid(4:5) = round(180*VrefThigh(2:3)/pi);
 for A = 6:15, AktTid(A) = sum(Akt==A-6)/3600; end
 %AktTid(16), for sleep (se below) 
 AktTid(17) = Ntrin;
 AktTid(18:19) = [WalkSlow,WalkFast];

 [Sit_Tmax,Sit_P50,Sit_T50,Sit_P10,Sit_P90,Sit_T30min,Sit_N30min,NriseSit] = AktDistAnalyse(Akt,'Sit');
 AktTid(20:27) = [Sit_Tmax,Sit_P50,Sit_T50,Sit_P10,Sit_P90,Sit_T30min,Sit_N30min,NriseSit];
 [SitLie_Tmax,SitLie_P50,SitLie_T50,SitLie_P10,SitLie_P90,SitLie_T30min,SitLie_N30min,NriseSitLie] = AktDistAnalyse(Akt,'SitLie');
 AktTid(28:35) = [SitLie_Tmax,SitLie_P50,SitLie_T50,SitLie_P10,SitLie_P90,SitLie_T30min,SitLie_N30min,NriseSitLie];
 Stand_Tmax = AktDistAnalyse(Akt,'Stand');
 StandMove_Tmax = AktDistAnalyse(Akt,'StandMove');
 AktTid(36:37) = [Stand_Tmax,StandMove_Tmax];
 
 ThresArm = pi*ThresArm/180;
 ArmData = NaN(1,4*(length(ThresArm)+1));
 ArmDataExtra = NaN(1,3);%11);
 if ~isempty(FilArm)
    [Varm3,AccArm] = Vinkler(FilArm,Start,Slut,ShiftAxes(3));
    OffArm = OffFnc('Arm',Varm3,AccArm,SF,Tid,Ntype,OnOffMan);
    Varm = Varm3(:,1);
    IonArm = ~reshape(repmat(logical(OffArm'),SF,1),1,[])'; %Indices for which Arm is not off
    InotLie = ~reshape(repmat(Akt==1|Akt==0,SF,1),1,[])'; %was not calculated (above) if trunk data did not exist
    %7/12-12: Akt==0 added above
    IokArm = IonArm & InotLie;
    Isit = reshape(repmat(Akt==2,SF,1),1,[])' & IonArm; %Indices for sitting and arm on (IonArm: 17/9-12)
    Istandmove = reshape(repmat(Akt==3|Akt==4,SF,1),1,[])' & IonArm; %Indices for standing/moving and arm on (IonArm: 17/9-12)
    Iupright = reshape(repmat(3<=Akt&Akt<=7,SF,1),1,[])' & IonArm; %Indices for stand/move/walk/run/stair and arm on oct13
    for ith = 1:length(ThresArm)
        IncArm(ith) = sum(Varm(IokArm) >= ThresArm(ith))/SF;
        IncArmSit(ith) = sum(Varm(Isit) >= ThresArm(ith))/SF;
        IncArmStandMove(ith) = sum(Varm(Istandmove) >= ThresArm(ith))/SF;
        IncArmUpright(ith) = sum(Varm(Iupright) >= ThresArm(ith))/SF; %oct13
    end
    PctArm = 100*IncArm/(length(Varm(IokArm))/SF); %used for plotting only
    IncArmMax90 = MaxIncTid(Varm,IokArm,ThresArm(3),SF);
    IncArmSitMax90 = MaxIncTid(Varm,Isit,ThresArm(3),SF);
    IncArmStandMoveMax90 = MaxIncTid(Varm,Istandmove,ThresArm(3),SF);
    IncArmUprightMax90 = MaxIncTid(Varm,Iupright,ThresArm(3),SF); %oct13
    ArmData = [IncArm,IncArmMax90,IncArmSit,IncArmSitMax90,IncArmStandMove,IncArmStandMoveMax90,...
               IncArmUpright,IncArmUprightMax90]; %oct13
    ArmDataExtra = zeros(1,3); %11);
    if ~isempty(Varm(IokArm))
       IncArmPrctiles = round((180/pi)*prctile(Varm(IokArm),[10,50,90])); %apr14: 10, 50 and 90 percentiles (degree)
       ArmDataExtra = IncArmPrctiles;
   end
 end
 
 %Sleep:
 if any(OffTrunk) && any(OffArm)
    Psleep = 'Thigh';
    Asleep = AccThigh;
    Asleep(reshape(repmat(OffTrunk',SF,1),[],1)==1,:) = NaN;
 elseif all(~OffTrunk) && any(OffArm)
     Psleep = 'Trunk';
     Asleep = AccTrunk;
 elseif all(~OffArm)
     Psleep = 'Arm';
     Asleep = AccArm;
 end
 Sleep = SleepFun(Akt,Asleep,SF,Psleep);
 AktTid(16) = sum(Sleep==0)/3600; %0:sleep, 1:awake

 
 if SETTINGS.CheckBatch 
    CheckMisOrientation(ID,Type,Start,Slut,AktTid,SF,Vthigh,StdThigh,Vhip,Varm3,Vtrunk,BF,OffThigh,OffHip,OffArm,OffTrunk,IncTrunkWalk,...
                        AccThigh,AccTrunk,ObsThighRef,ObsTrunkRef) 
 end

 IncTid = [[sum(OffArm),ArmData]/3600,ArmDataExtra,round(180*VrefTrunk(2:3)/pi),[sum(OffTrunk),TrunkData]/3600,IncTrunkWalk];

 %Export of Activity classification to txt/mat file:
 if SETTINGS.ActivityExportTxt || SETTINGS.ActivityExportMat
    if exist('Varm','var')
        ActivityExport(ID,Tid,Akt,SETTINGS,Varm,IonArm,SF) %11/12-17
    else
        ActivityExport(ID,Tid,Akt,SETTINGS)
    end
 end
  
 %EVA analysis (6/12-17):
 if SETTINGS.EVAanalysis
    EVAactiGenerel3(ID,Type,Start,Slut,Akt,Fstep,OffHipTrunk12)
 end
  
 if SETTINGS.Calf
    KneelDetection(ID,Type,Start,Slut,Tid,Akt,SF,FilThigh,Vthigh,OffThigh,ShiftAxes(5),AktTid,SETTINGS.Threshold_kneel)
 end
  
else %to view a heart rate file alone (11/5-19)
   Tid = Start:1/86400:Slut;
   T = [Tid(1),Tid(end)];
   Akt = zeros(size(Tid));
   Fstep = NaN(size(Tid));
   [Ntrin,AvgSpeed] = deal(NaN);
   AktTid = zeros(1,15);
   [OffThigh,OffHipTrunk12] = deal(ones(size(Akt)));
end

 %HR analysis:
 HRf = [];
 AH = NaN(1,28);
 HRA = NaN(1,10); %mean HR for the different Activities
 HRRA = NaN(1,10); %mean HRR for the different Activities
 HRRdist = NaN(1,100);
 if exist('RR','var') && ~isempty(RR) && Start<Tbeat(end) && Tbeat(1)<Slut && any(Start<=Tbeat & Tbeat<=Slut)
  [TBeatf,RRf,HRf,HRminInt,HRmaxInt] = HRanalysis(Tbeat,RR,Start,Slut); %HRmaxInt: HRmax i intervallet ikke at forveksle med HRmax globalt
  % Aug. 19: AHanalysis2 replaced by the new HRanalysis
 
  AHTime = 24*(TBeatf(end)-TBeatf(1)); %last interval is typically incomplete 
  NBeat = length(TBeatf);
  Iok = ~isnan(RRf);
  RRok = RRf(~isnan(RRf));
  %14/5-19: NBeatErr removed, PctBeatErr redefined to make consistency between Actiheart and Bodyguard2 data
  %NBeatErr = NBeat-sum(Iok); 
  %PctBeatErr = 100*NBeatErr/NBeat
  PctBeatErr = 100*(1-(sum(RRok)/(1000*86400))/(Slut-Start)); %percentage of time without valid RR data
  [HRmean,HRRmean,HRsleep] = deal(NaN);
  if PctBeatErr<99
     if PctBeatErr<50 % at least 50% (arbitrary) ok values required
        HRmean = 60000/mean(RRok); % =60000/(sum(RRok)/length(RRok));
        if exist('HRmax','var') && exist('HRrest','var') && ~isempty(HRmax) && ~isempty(HRrest)
           %Only actual ok RR values are used for calculation of HRR distribution, no interpolated values used: 
           HRRmean = 100*(HRmean-HRrest)/(HRmax-HRrest);
           RRbin = 60000./linspace(HRmax,HRrest,101);
           RRbinC  = mean([RRbin(1:end-1);RRbin(2:end)]); %Bin centers
           Hist = histc(RRok,RRbin)';
           Hist = [Hist(1:end-2),sum(Hist(end-1:end))];
           HRRdist = cumsum((fliplr(Hist.*RRbinC)))/3600000; %hours
        end
     end
     %combined activity and AH:
     AktIntp = interp1(Tid,Akt,TBeatf,'nearest','extrap'); %Activity (nearest) at beat times
     for i=0:9
         Ii = AktIntp==i;
         if sum(Ii & Iok)/sum(Ii) > .5  % at least 50% (arbitrary) ok values required for calculation of mean value 
            RRi = RRf(AktIntp==i & Iok);                    
            HRA(i+1) = 60000/mean(RRi); 
         end
     end
     SleepIntp = interp1(Tid,Sleep,TBeatf,'nearest','extrap'); %Sleep (nearest) at beat times ,25/5-20
     if sum(SleepIntp==0 & Iok)/sum(SleepIntp==0) > .5
        RRsleep = RRf(SleepIntp==0 & Iok);                    
        HRsleep = 60000/mean(RRsleep); 
     end
     if exist('HRmax','var') && exist('HRrest','var') && ~isempty(HRmax) && ~isempty(HRrest)
        HRRA = 100*(HRA-HRrest)/(HRmax-HRrest);
     end
     %if HRV analysis:
     if SETTINGS.HRVanalysis
        Vtrunk2HRV = [];
        if exist('Vtrunkrot','var')
           Vtrunk2HRV = Vtrunkrot(1:SF:end,:); %1 sammple per sec.
        end
        HRVanalyse(ID,Type,Tid,Akt,Fstep,TBeatf,RRf,Vtrunk2HRV,OffTrunk); 
     end
  end
  AH = [AHTime,NBeat,PctBeatErr,HRminInt,HRmaxInt,HRmean,HRsleep,HRRmean,HRA,HRRA];
  
end
  
%The rest is plotting if 'Show' is checked*******************************************************************************************************
 if Vis
     if  isempty(FilTrunk) && isempty(FilArm) && isempty(HRf)
         Pos = [.02 .4 .5 .5];
         SubPos1 =[.13 .5 .775 .4];
         SubPos2 = [.13 .15 .775 .25];
     elseif isempty(FilTrunk) && isempty(FilArm)
         Pos = [.02 .25 .5 .65];
         SubPos1 = [.13 .6 .775 .3];
         SubPos2 = [.13 .4 .775 .1];
         SubPos5 = [.13 .1 .775 .2];
     else
         Pos = [.02 .045 .5 .85];
         SubPos1 = [.13 .75 .775 .2];
         SubPos2 = [.13 .64 .775 .06];
         SubPos3 = [.13 .47 .775 .14];
         SubPos4 = [.13 .28 .775 .14];
         SubPos5 = [.13 .11 .775 .12];
     end
     
     h = findobj('Tag','ActiFig');
     if isempty(h)
        h = figure('Units','Normalized','PaperPosition',[.5 2.5 20 20],'Position',Pos,'Tag','ActiFig','Toolbar','Figure');
        set(zoom,'ActionPostCallback',@UpdateZoom);
     else
         figure(h);
         delete(findobj('Tag','DateTick'))
         delete(findobj('Tag','HR'))
         delete(findobj('Tag','HRR%'))
     end
     if exist('ActiHeartDelay','var')
        set(datacursormode(h),'DisplayStyle','window','UpdateFcn',{@CursorFunktion,ID,ActiHeartDelay})
     end
        
     %Activity plot:
     subplot('Position',SubPos1);
     if ~any(OffHipTrunk) % lie and sit detected all the way (10/2-20)   
       plot(Tid,Akt,'-k')
       axis tight
       datetick('x','HH:MM','keeplimits')
       Xakse = xlim;
       set(gca,'Ylim',[-.1 9.1])
       Apct = num2str(100*AktTid(6:15)'/AktTid(1),'%4.1f');
       set(gca,'YTick',0:9,'YTickLabel',Ylab{1},'Ygrid','on')
       set(gca,'Tag','DateTick')
       title([ID,' / ',datestr(Start,1)],'Interpreter','none')
       % Procentvædier skrives i højre side:
       text(1.02,1.08,'%','Units','Normalized','Tag','Percent')
       text(repmat(1.01,1,10),(0:9)/9.2+1/92,Apct,'Units','Normalized','Tag','Percent')
       text(0,1.05,datestr(Start,'HH:MM'),'Units','Normalized','HorizontalAlignment','Left','Tag','TimeLeft')
       text(1,1.05,datestr(Slut,'HH:MM'),'Units','Normalized','HorizontalAlignment','Right','Tag','TimeRight')
       hold on
       if exist('Sleep','var')
          plot(Tid(Sleep==0),Sleep(Sleep==0)+.95,'x') %'bold' line for sleep
       end
     else % lie and sit not seperately detected in whole or part of interval (10/2-20)
       Akt(Akt==1) = 2;
       Akt(Akt==0) = 1;
       plot(Tid,Akt,'-k')
       axis tight
       datetick('x','HH:MM','keeplimits')
       Xakse = xlim;
       set(gca,'Ylim',[.9 9.1])
       Apct = num2str(100*[AktTid(6),sum(AktTid(7:8)),AktTid(9:15)]'/AktTid(1),'%4.1f');
       set(gca,'YTick',1:9,'YTickLabel',Ylab{2},'Ygrid','on')
       set(gca,'Tag','DateTick')
       title([ID,' / ',datestr(Start,1)],'Interpreter','none')
       % Procentvædier skrives i højre side:
       text(1.02,1.08,'%','Units','Normalized','Tag','Percent')
       text(repmat(1.01,1,9),(0:8)/8.2+1/82,Apct,'Units','Normalized','Tag','Percent')
       text(0,1.05,datestr(Start,'HH:MM'),'Units','Normalized','HorizontalAlignment','Left','Tag','TimeLeft')
       text(1,1.05,datestr(Slut,'HH:MM'),'Units','Normalized','HorizontalAlignment','Right','Tag','TimeRight')
       hold on
       if exist('Sleep','var')
          plot(Tid(Sleep==0),Sleep(Sleep==0)+1.95,'x') %'bold' line for sleep
       end
     end
     if any(OffThigh)
          hold on
          plot(Tid(OffThigh==1),Akt(OffThigh==1),'y')
          hold off
     end
     drawnow 
     
     %Step plot:
      subplot('Position',SubPos2); 
       plot(Tid,Fstep,'-k')
       set(gca,'Xlim',Xakse,'Ylim',[0 max([Fstep,1])]); %max(Fstep) can be 0
       datetick('x','HH:MM','keeplimits')
       set(gca,'Tag','DateTick')
       ylabel('Steps/sec')
       text(.25,1.15,['Total steps: ',num2str(Ntrin) ', Avg.speed: ',num2str(AvgSpeed,3),' steps/s'],'Units','Normalized');
       drawnow 
     
     %Arm inclination plot:
     if ~isempty(FilArm)
       subplot('Position',SubPos3);
       Tplot = T(1:SF:length(Varm));
       Varmplot = (180/pi)*(Varm(1:SF:end)); 
       plot(Tplot,Varmplot,'-k')
       set(gca,'Xlim',Xakse,'Ylim',[0 180],'Ytick',[0,180*ThresArm/pi],'Ygrid','on')
       datetick('x','HH:MM','keeplimits')
       set(gca,'Tag','DateTick')
       ylabel('Arm (°)')
       text(1.02,1.08,'%','Units','Normalized','Tag','Percent')
       text(repmat(1.01,1,5),(1:5)/6,num2str(PctArm','%3.0f'),'Units','Normalized','Tag','Percent')
       if any(OffArm) %if Arm is off somewhere in the interval
          hold on
          plot(Tplot(OffArm==1),Varmplot(OffArm==1),'y')
          hold off
       end   
       drawnow
     end
     
     %Trunk inclination plot:
     if ~isempty(FilTrunk) && ~isempty(VrefTrunk) && all(~isnan(VrefTrunk))
       h = subplot('Position',SubPos4);
       Tplot = T(1:SF:length(Vtrunkrot));
       Vtrunkplot = (180/pi)*Vtrunkrot(1:SF:end,:);
       plot(Tplot,Vtrunkplot)
       set(gca,'Xlim',Xakse,'Ylim',[-90,120],'Ytick',[-90,-60,-30,0,180*ThresTrunk(2:end)/pi],'Ygrid','on') % 20° is excluded from the plot
       datetick('x','HH:MM','keeplimits')
       set(gca,'Tag','DateTick')
       ylabel('Trunk (°)')
       Vr = int2str(180*VrefTrunk'/pi);
       L = legend(['Inc(ref=',Vr(1,:),'°)'],['Ant/Pos(ref=',Vr(2,:),'°)'],['Lat(ref=',Vr(3,:),'°)'],'Orientation','Horizontal');
       legend(L,'boxoff')
       PlotPos = get(h,'Position'); 
       set(L,'Position',[.5,PlotPos(2)+PlotPos(4),.001,.02])
       text(1.02,1.08,'%','Units','Normalized','Color',[0 0 1],'Tag','Percent')
       text(repmat(1.01,1,3),(4:6)/7,num2str(PctTrunk(2:end)','%3.0f'),'Units','Normalized','Color',[0 0 1],'Tag','Percent')
       if any(OffTrunk) %if Trunk is off somewhere in the interval
          hold on
          plot(Tplot(OffTrunk==1),Vtrunkplot(OffTrunk==1,:),'y')
          hold off
       end
       drawnow
     end
    
     %Heart rate plot:
     if ~isempty(HRf)
        ax1 = axes('Position',SubPos5);
        set(ax1,'Xlim',[T(1),T(end)],'Tag','HR','Box','on')
        line(TBeatf,HRf,'color',[0 0 0]);
        datetick('x','HH:MM','keeplimits')
        ylabel('HR')
        Ymax = min([max(HRf),250]);
        if PctBeatErr<99, set(ax1,'Ylim',[min(HRf),Ymax]), end
        if isnan(HRRmean)
           text(.25,1.1,['BeatErr: ', num2str(PctBeatErr,'%4.1f'),'%, HRmean: ',num2str(HRmean,'%5.1f'),', ',...
                         'HRmin: ',num2str(HRminInt,'%5.1f'),', HRmax: ',num2str(HRmaxInt,'%5.1f')],'Units','Normalized');
        else
            text(.25,1.1,['BeatErr: ', num2str(PctBeatErr,'%4.1f'),'%, HRmean: ',num2str(HRmean,'%5.1f') '(',num2str(HRRmean,'%5.1f'),'%), ',...
                          'HRmin: ',num2str(HRminInt,'%5.1f'),', HRmax: ',num2str(HRmaxInt,'%5.1f')],'Units','Normalized');
        end
        if exist('HRmax','var') && ~isempty(HRmax) && ~isnan(HRmax) && exist('HRrest','var') && ~isempty(HRrest) && ~isnan(HRrest)
           set(ax1,'Xlim',Xakse,'Ylim',[HRrest,HRmax],'Box','off')
           line(Xakse,[HRmax,HRmax],'Color','k')
           Ax1 = get(ax1,'Position');
           ax2 = axes('Position',[Ax1(1)+Ax1(3),Ax1(2),.0001,Ax1(4)],'YaxisLocation','right','Color','none','Xtick',[],'TickLength',[.05 0]);
           set(ax2,'Ylim',[0 100])
           ylabel('HRR (%)')
           set(ax2,'Tag','HRR%','UserData',[HRrest,HRmax])
         end
     end
  
 end
 
 if ~isempty(PlotMappe)
    set(gcf,'PaperPosition',[0 0 20 29])
    saveas(gcf,fullfile(PlotMappe,[ID,'_',datestr(Start,30)]),'bmp'); %File name: ID_StartDataTime
 end
 
%*********************************************************************************************************************************
 
 %Flg. 2 linjer bruges hvis der skal produceres tilbagemeldingsplot: 
 %if ~exist('HRf','var')||isempty(HRf), [TBeatf,HRf,HRmax,HRrest] = deal([]); end
 %RapportIndivid(Tid,T,Akt,Start,Slut,AktTid,ID,TBeatf,HRf,HRmax,HRrest,FilTrunk,Pause,Ntrin,ForwardIncTrunkUpright)

%**********************************************************************************************************************************
%skal ikke inkluderes generelt
 %WalkStepDist(ID,Type,Start,Slut,Akt,Fstep,OffThigh)
%************************************************************************************************************************************

%Evt. kald af ekstern brugerspecificeret funktion:
if exist('Acti4ExternFunction.m','file')
   %generering af struktur variabel D:
   VarList = {...
   'ID','Type','FilThigh','FilHip','FilArm','FilTrunk','VrefThigh','VrefTrunk','SF','Start','Slut','Ylab','PlotMappe',...
   'AccThigh','AccHip','AccTrunk','AccArm','Vthigh','Vhip','Vtrunk','Varm3','Tid','Akt'};
   for i=1:length(VarList)
       D.(VarList{i}) = eval(VarList{i});
   end
   
   if isfield(ColHeadAct,'Time')
      for i=1:length(ColHeadAct)
          D.(ColHeadAct{i}) = AktTid(i);
      end
      for i=1:length(ColHeadInc)
          D.(ColHeadInc{i}) = IncTid(i);
      end
   end
   
   if SETTINGS.IncludeAH && exist('AHTime','var')
      VarListHR = {'Tbeat','RR','ActiHeartDelay','HRrest','HRmax','AHTime','NBeat','PctBeatErr','HRminInt','HRmaxInt','HRmean','HRRmean','TBeatf','HRf','RRf'};
      for i=1:length(VarListHR)
          D.(VarListHR{i}) = eval(VarListHR{i});
      end
      HRAlist = {'HRoff','HRlie','HRsit','HRstand','HRmove','HRwalk','HRrun','HRstairs','HRcycle','HRrow'};
      for i=1:length(HRAlist)
          D.(HRAlist{i}) = HRA(i);
      end
      HRRAlist = {'HRRoff','HRRlie','HRRsit','HRRstand','HRRmove','HRRwalk','HRRrun','HRRstairs','HRRcycle','HRRrow'};
      for i=1:length(HRAlist)
          D.(HRRAlist{i}) = HRRA(i);
      end
      for i=1:100
          D.(['HRR_',num2str(i)]) = HRRdist(i);
      end
   end
   Acti4ExternFunction(D)
end
%**********************************************************************************************************************************

function Text = CursorFunktion(~,event_obj,ID,OldDelay)
% Display the position of the data cursor
% obj          Currently not used (empty)
% event_obj    Handle to event object
% output_txt   Data cursor text string (string or cell array of strings).

persistent Time
SubP = 1 + strcmp('HR',get(get(gca,'Ylabel'),'String')); %2 when called from HR subplot, 1 else
pos = get(event_obj,'Position');
Time(SubP) = pos(1);
if length(Time)==2 && all(Time)
   AHdelay = num2str(round(86400*diff(Time)));
   NewDelay = OldDelay + str2double(AHdelay);
   Ans = questdlg(['Save new ActiHeart time offset = ',num2str(NewDelay),' seconds?']);
   if strcmp(Ans,'Yes')
      Excel = actxGetRunningServer('Excel.Application'); %Excel setup-fil supposed to be open
      Sheets = Excel.ActiveWorkbook.WorkSheets;
      RowRange = get(get(Sheets,'Item',ID),'Range','A1:A8'); %to find the line of 'ActiHeart' (12/9-2012):
      AHline = num2str(find(strcmp('ActiHeart',get(RowRange,'Value'))));
      Range = get(get(Sheets,'Item',ID),'Range',['G',AHline]);
      set(Range,'Value',NewDelay)
      invoke(Excel.ActiveWorkbook,'Save');
   end
   set(datacursormode(findobj('Tag','ActiFig')),'Enable','off') %causes a datacursor error, 
   %however else a data cursor "run-away" problem shows up?
   clear Time 
end
Text = {datestr(pos(1),'HH:MM:SS')};
clipboard('copy',datestr(pos(1)))
%**********************************************************************************************************************************

function RapportIndivid(Tid,T,Akt,Start,Slut,AktTid,ID,TBeatf,HRf,HRmax,HRrest,FilTrunk,Pause,Ntrin,ForwardIncTrunkUpright)
 %Til produktion af grafer til Vuggestueprojekt tilbagemeldinger
 persistent A2 A13 IDold
 if ~strcmp(ID,IDold) || isempty(IDold), A2=0; A13=0; end
 GemmeSti = 'P:\Ny mappe\';
 hNow = findall(0,'Tag','NowAnalysing');
 Activity = get(findobj(hNow,'Tag','Activity'),'String');
 Activity = Activity{1}(1:2);
 Day = num2str(weekday(mean([Start,Slut])-1)); %weekday of midtime, monday = day 1
 Filnavn = [ID,'_',Activity,'_',Day];
 Fil = [GemmeSti,Filnavn];

 if Pause %if pause is on, files can be individually selected for export, else an automatic scheme is used:
    if strcmp('Yes',questdlg(['Export ',Filnavn,' ?'])), 
        save(Fil)
    end
 else
    Ta2 = 4;
    Ta13 = 4;
    %Først vælges en A2 længere end Ta2 timer, dernæst først
    %forekommende A1 eller A3 længere end Ta13 timer:  
    if strcmp('A2',Activity) && Slut-Start>Ta2/24 && A2==0
       save(Fil)
       A2=1;
    end
    if any(strcmp({'A1','A3'},Activity)) && Slut-Start>Ta13/24 && A2==1 && A13==0
       save(Fil)
       A13=1;
    end
    IDold = ID;
 end      

 %***************************************************************************************************************************************************************
 %skal ikke inkluderes generelt
 function WalkStepDist(ID,Type,Start,Slut,Akt,Fstep,OffThigh)
     
 persistent Fid
 if isempty(Fid) 
    [FilNavn,Sti] = uiputfile('*.txt','Angiv filnavn til "WalkStepDist" resultater');
    Fil = fullfile(Sti,FilNavn);
    Fid = fopen(Fil,'w');
    fprintf(Fid,'LbNr, Type, Start, Stop, Off, <80, 80:90, 90:100, 100:110, 110:120, 120:130, 130:140, >=140\r\n');
 end
 Walk = Fstep(Akt==5);
 Ndist = histc(Walk*60,[-Inf,80:10:140,Inf]);
 Ndist = Ndist(1:end-1);
 WalkDist = Ndist/3600;
 StartT = datestr(Start,'dd/mm/yyyy/HH:MM:SS');
 SlutT = datestr(Slut,'dd/mm/yyyy/HH:MM:SS');
 Off = sum(OffThigh)/3600;
 fprintf(Fid,'%s, %s, %s, %s, ', ID, Type, StartT, SlutT);
 fprintf(Fid,'%7.4f, %7.4f, %7.4f, %7.4f, %7.4f, %7.4f, %7.4f, %7.4f, %7.4f \r\n',Off, WalkDist); 