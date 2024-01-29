function HRVanalyse(ID,Type,Tid,Akt,Fstep,TBeat,RRf,Vtrunk,OffTrunk)

% HRV analyse of 5 min. intervals (se document: HRV analysis by Acti4.pdf)
% This function is called by AnalyseAndPlot if 'HRV' is selected in 'Analysis setup'.
% The output from the analysis are not included in the standard output by Acti4, but saved in a separate user selected file.
 

global FidHRV %idetifier for fil til resultater 
persistent Method %RPD eller FFT analysemetode

if isempty(FidHRV) %defineres som tom i ActiG ved start af 'Batch' (sikrer mulighed for at vælge ny fil når Batch køres igen)
   Method = questdlg('Specify method for frequency analysis','HRV analysis','Robust Periocity Detection (RPD)','Fast Fourier Transform (FFT)','Robust Periocity Detection (RPD)');
   if isempty(Method), return, end
   Method = Method(end-3:end-1);
   WB = get(actxGetRunningServer('Excel.Application'),'ActiveWorkbook'); %Finder Setup filen:
   SetupFil = get(WB,'Name');
   [FilNavn,Sti] = uiputfile('*.txt','Select file name for HRV results',[SetupFil(1:end-4),'_',Method]); %uiputfile checker for fil eksistens
   if isnumeric(FilNavn), return, end %Cancel selected
   Fil = fullfile(Sti,FilNavn);
   FidHRV = fopen(Fil,'w');
   %Overskrifter:
   fprintf(FidHRV,'LbNr, Type, Date, Start, N5, OffThighPct, OffTrunkPct, LiePct, SitPct, StandPct, AllMovePct, UprightPct, Steps, TrunkMove, Nbeat, BeatErrPct, Stationarity, ');
   fprintf(FidHRV,'AVRR, RMSSD, SDNN, pNN50, Ptotal, VLF, LF, HF, VHF, LF/HF, LFnu, HFnu, \r\n');
end

if strcmp('FFT',Method) %4 Hz lineær interpolation:
   Tid4Hz = (Tid(1):1/(86400*4):Tid(end))';
   iiOk = ~isnan(RRf);
   RRintp = interp1(TBeat(iiOk),RRf(iiOk),Tid4Hz); %4Hz linear interpolation
end

Ts = fix(Tid(1)) + ceil(rem(Tid(1),1)*288)/288; %5 minutters afrunding
Te = Ts + 1/288; %5 minutters analyseinterval
while Te <= TBeat(end)
  disp([ID,' (',datestr(Ts),')'])
  iiAkt = Ts<= Tid & Tid<Te;
  akt = Akt(iiAkt);
  N5 = round(rem(Ts,1)*288) +1; %nummerering af 5 minutters intervaller for et døgn (1,2,...,288)
  n300 = length(akt);
  OffThighPct = round(100*sum(akt==0)/n300);
  LiePct = round(100*sum(akt==1)/n300);
  SitPct = round(100*sum(akt==2)/n300);
  StandPct = round(100*sum(akt==3)/n300);
  AllMovePct = round(100*sum(akt>3)/n300);
  UprightPct = round(100*sum(akt>2)/n300);
  Trin = round(sum(Fstep(iiAkt)));
  TrunkMov = NaN;
  if ~isempty(Vtrunk)
     TrunkMov = round(max(180*range(Vtrunk(iiAkt,:))/pi)); %max range of movement (°, inclination, forward or sideways)
  end
  OffTrunkPct = round(100*sum(OffTrunk(iiAkt))/n300);
  
  iiBeat = Ts<=TBeat & TBeat<Te;
  tbeat = TBeat(iiBeat);
  rrf = RRf(iiBeat);
  nbeat = length(tbeat);
  rrok = rrf(~isnan(rrf));
  beatErrPct = 100*(1-(sum(rrok)/(1000*86400))/(Te-Ts)); %percentage of time without valid RR data
  if beatErrPct<0, beatErrPct=0; end %afrundingsfejl kan give smmå negative værdier (ned til -.4)
  
  [pv,AVRR,RMSSD,SDNN,pNN50,Ptotal,VLF,LF,HF,VHF,LFnu,HFnu] = deal(NaN);
  if beatErrPct<50 %ingen beregninger hvis mere end 50% fejl
     AVRR = nanmean(rrf);
     SDNN = nanstd(rrf);
     RMSSD = sqrt(nanmean(diff(rrf).^2));
     absdiff = abs(diff(rrf));
     pNN50 = sum(absdiff>50)/sum(~isnan(absdiff));
     ii = ~isnan(rrf);
     rrfi = rrf(ii);
     x = detrend(rrfi);
     pv = Stationaritet(x,5); % test af stationaritet
     
     if strcmp('FFT',Method)
        ii4Hz = Ts<= Tid4Hz & Tid4Hz<Te;
        rrintp = RRintp(ii4Hz);
        rrintp = rrintp(~isnan(rrintp));
        rrintp = detrend(rrintp);
        [Pxx,F] = pwelch(rrintp,256,128,1024,4);
        dF = F(2)-F(1);
     end
     
%    Iter=1;
     if strcmp('RPD',Method)
        warning off stats:statrobustfit:IterationLimit
        t = (tbeat-tbeat(1))*86400;
        ti = t(ii);
        [y,F] = fitSp_corr_1(x,ti); %RPD beregning
        n = length(ti);
        dt = (ti(end)-ti(1))/(n-1);
        dF = F(2)-F(1);
        Pxx = y*2*dt;
%       if strcmp(lastwarn,'Iteration limit reached.')
%          Iter=0; 
%          lastwarn('')
%       end
     end 
  
     Ptotal = dF*sum(Pxx(0.003<F & F<=0.5));
     VLF = dF*sum(Pxx(0.003<F & F<=0.04));
     LF = dF*sum(Pxx(0.04<F & F<=0.15));
     HF = dF*sum(Pxx(0.15<F & F<=0.4));
     VHF = dF*sum(Pxx(0.4<F & F<=0.5));
     LFnu = LF/(LF+HF+VHF);
     HFnu = HF/(LF+HF+VHF);
  end

%   Testplot:
%   H = findobj('Name','Testplot');
%   if isempty(H), figure('Name','Testplot'), else figure(H), end
%   subplot(2,1,1)
%     plot(tbeat,rrf,'Color',[0 0 0])
%     datetick('x')
%     text(.7,.85,['BeatErrPct = ',num2str(beatErrPct,'%4.1f'),'%'],'units','normalized')
%     title([ID,' (',datestr(Ts),')'])
%   subplot(2,1,2)
%     if exist('F','var')
%        plot(F(F<=.5),Pxx(F<=.5))
%        xlabel('Hz')
%     end
   
  fprintf(FidHRV,'%s, %s, %s, %s, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %5.1f, %5.3f, %6.1f, %6.1f, %6.1f, %5.3f, %6.1f, %6.1f, %6.1f, %6.1f, %6.1f, %4.1f, %5.3f, %5.3f, \r\n',...
          ID,Type,datestr(Ts,'dd:mm:yyyy'),datestr(Ts,'HH:MM'),N5,OffThighPct,OffTrunkPct,LiePct,SitPct,StandPct,AllMovePct,UprightPct,Trin,TrunkMov,nbeat,beatErrPct,pv,...
          AVRR, RMSSD, SDNN, pNN50, Ptotal, VLF, LF, HF, VHF, LF/HF, LFnu, HFnu);

  Ts = Ts + 1/288; 
  Te = Ts + 1/288;
  
end

