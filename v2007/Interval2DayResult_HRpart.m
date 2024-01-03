function S = Interval2DayResult_HRpart(ResColNames,Raw,Kat,Params,IDs,Type,Days,SumMethod,S,Crit,MethodDS)
%Kaldes fra Interval2DayResult, håndterer HR parametrene

AHTime = Raw{strcmp('AHTime',ResColNames)};
BeatErrPct =  Raw{strcmp('BeatErrPct',ResColNames)};
HRhours = AHTime - AHTime.*BeatErrPct/100; %reel måletid

HRpair = FunHRpair; %se til sidst

for id=1:size(IDs,1)
    iID = strcmp(IDs{id},Raw{1}); %indices for ID
    if any(strcmp({'LonW','WaL','Wol'},SumMethod))
       iID = iID & logical(Raw{6}); %only work days   
    end
    IDdays = unique(Days(iID)); %aktuelle datoer for ID
    [TimeHR,TimeHRpar] = deal(zeros(size(IDdays,1),size(Type,2)));
    for p=1:length(Params)
        Par = Params{p}; %aktuelt variabelnavn
        HRspc = ismember(Par,HRpair(:,1)); %dette er variablene HRoff, HRlie, HRsit...
        Res = nan(size(IDdays,1),size(Type,2));
        Data = Raw{strcmp(Par,ResColNames)}; %tilsvarende kolonne med data (variabelværdier)
        data = Data(iID); %data for aktuel ID
        hrhours = HRhours(iID);
        if all(isnan(hrhours))
           S(id).THRavg = NaN;
           for q=1:length(Params)
               S(id).(Params{q}) = NaN;
           end
           break
        end
        for d=1:length(IDdays)
            for i=1:size(Type,2)
                di = strncmp(Type(i),Raw{2}(iID),2) & Days(iID) == IDdays(d);
                %di er index for dag/interval relativt iID
                if any(di)
                   if HRspc %midling (tidsvægtet) af disse parametre kræver at de til hørende tider benyttes: 
                      HRhourspar = Raw{strcmp(HRpair(strcmp(Par,HRpair(:,1)),2),ResColNames)};
                      hrhourspar = HRhourspar(iID);
                      TimeHRpar(d,i) =  nansum(hrhourspar(di));
                      Res(d,i) = CalcSammeDag(Kat(:,[1,3]),Par,data(di),hrhourspar(di));
                   else
                      Res(d,i) = CalcSammeDag(Kat(:,[1,3]),Par,data(di),hrhours(di));
                   end
                end
                if p==1 %måletimer
                   TimeHR(d,i) = sum(hrhours(di));
                end
            end
        end
       
        if p==1 && ~all(isnan(hrhours)) %ved første parameter bestemmes 'average measured time' og hvilke dage der inkluderes,
                                        %se T:\Objektive målinger\Metode\Matlab\Criteria_accelerometry.docx (NGU)
           if strcmp(MethodDS,'Detailed')
              if strcmp('A',SumMethod) %whole day (waking time)
                 Ix = ismember(Type,{'A1','A2','A3','B1','B2','B3','C0'});
                 AvgMeasTime = FunAvgMeasTime(TimeHR(:,Ix));
                 tsum = sum(TimeHR(:,Ix),2);
                 Idays = AndOrCrit(tsum,10,.75*AvgMeasTime,Crit);
              end
              if strcmp('W',SumMethod) %work only
                 Ix = ismember(Type,{'A2','B2'});
                 AvgMeasTime = FunAvgMeasTime(TimeHR(:,Ix));
                 tsum = sum(TimeHR(:,Ix),2);
                 Idays = AndOrCrit(tsum,4,.75*AvgMeasTime,Crit);
              end
              if strcmp('LonW',SumMethod) %leisure on work days
                 Ix = ismember(Type,{'A1','A3','B1','B3'});
                 AvgMeasTime = FunAvgMeasTime(TimeHR(:,Ix));
                 tsum = sum(TimeHR(:,Ix),2);
                 Idays = AndOrCrit(tsum,4,.75*AvgMeasTime,Crit);
              end
              if strcmp('LonA',SumMethod) %leisure all days
                 Ix = ismember(Type,{'A1','A3','B1','B3','C0'});
                 AvgMeasTime = FunAvgMeasTime(TimeHR(:,Ix));
                 tsum = sum(TimeHR(:,Ix),2);
                 Idays = AndOrCrit(tsum,4,.75*AvgMeasTime,Crit);
              end
              if strcmp('WaL',SumMethod) || strcmp('WoL',SumMethod) %work AND/OR leisure
                 %work similar to point 2: 
                 Ix = ismember(Type,{'A2','B2'});
                 AvgMeasTime_2 = FunAvgMeasTime(TimeHR(:,Ix));
                 tsum = sum(TimeHR(:,Ix),2);
                 Idays_2 = AndOrCrit(tsum,4,.75*AvgMeasTime_2,Crit);
                 %leisure similar to point 3:
                 Ix = ismember(Type,{'A1','A3','B1','B3'}); 
                 AvgMeasTime_3 = FunAvgMeasTime(TimeHR(:,Ix));
                 tsum = sum(TimeHR(:,Ix),2);
                 Idays_3 = AndOrCrit(tsum,4,.75*AvgMeasTime_3,Crit);
                 if strcmp('WaL',SumMethod)
                    Idays = Idays_2 & Idays_3;
                 end
                 if strcmp('WoL',SumMethod)
                    Idays = Idays_2 | Idays_3;
                 end
                 AvgMeasTime = (AvgMeasTime_2 + AvgMeasTime_3)/2; %not important
              end
              if strcmp('B',SumMethod) %time in bed
                 Ix = ismember(Type,{'A4','B4','C4'});
                 AvgMeasTime = FunAvgMeasTime(TimeHR(:,Ix));
                 tsum = sum(TimeHR(:,Ix),2);
                 Idays = tsum>=4;
              end
           end
           
           if strcmp(MethodDS,'Simplified')
              switch SumMethod 
                 case 'A' %whole day (waking time)
                   Ix = ismember(Type,{'A1','A2','A3','B1','B2','B3','C0'});
                 case 'W' %work only
                   Ix = ismember(Type,{'A2','B2'});
                case 'LonW' %leisure on work days
                   Ix = ismember(Type,{'A1','A3','B1','B3'});
                 case 'LonA' %leisure all days
                   Ix = ismember(Type,{'A1','A3','B1','B3','C0'}); 
                 case 'B' %time in bed
                   Ix = ismember(Type,{'A4','B4','C4'});
              end
              time = TimeHR(:,Ix);
              Idays = ~all(time==0|isnan(time),2);
              sumint = nansum(time(Idays,:),2); %sum across intervals 
              AvgMeasTime = sum(sumint.^2)/sum(sumint); %time weighted average across days 
           end
           
           S(id).THRavg = AvgMeasTime;
        end
        
        if strcmp(MethodDS,'Detailed')
           if HRspc
              S(id).(Par) = CalcPerDag(Kat(:,2:3),Par,Res(Idays,Ix),TimeHRpar(Idays,Ix)); 
           else
              S(id).(Par) = CalcPerDag(Kat(:,2:3),Par,Res(Idays,Ix),TimeHR(Idays,Ix)); 
           end
        end
        if strcmp(MethodDS,'Simplified')
           data = Res(Idays,Ix);
           hour = TimeHR(Idays,Ix) .* ~isnan(data);
           if Kat{strcmp(Par,Kat(:,3)),2} == 2 %sum within days then time weighted average between days
              S(id).(Par) = nansum(nansum(data,2) .* nansum(hour,2)) / sum(nansum(hour,2));
           end  
           if Kat{strcmp(Par,Kat(:,3)),2} == 7 %max within days the time weighted average between days
              S(id).(Par) = nansum(nanmax(data,[],2) .* nansum(hour,2)) / sum(nansum(hour,2)); 
           end
           if Kat{strcmp(Par,Kat(:,3)),2} == 8 %min within days the time weighted average between days
              S(id).(Par) = nansum(nanmin(data,[],2) .* nansum(hour,2)) / sum(nansum(hour,2)); 
           end
           if Kat{strcmp(Par,Kat(:,3)),2} == 10 && ~HRspc %HRmean, HRsleep, HRRmean: time weighted average of all intervals  
              S(id).(Par) = nansum(nansum(hour.*data))/sum(nansum(hour));
           end
           if Kat{strcmp(Par,Kat(:,3)),2} == 10 && HRspc % time weighted average of all intervals
              hour = TimeHRpar(Idays,Ix) .* ~isnan(data);
              S(id).(Par) = nansum(nansum(hour.*data))/sum(nansum(hour));
           end
           
        end
       
    end
    
disp(IDs{id})    
end

%.............................................................................................................................

function res = CalcSammeDag(Kat,Par,data,hours)
ak = Kat{strcmp(Par,Kat(:,2)),1}; %summeringskategori for aktuel parameter
data = double(data);
switch ak
  case 1
    res = nansum(data);
  case 5
    res =  nanmax(data);
  case 6
    res =  nanmin(data);
  case 10
    res = nansum(hours.*data)/sum(hours.*(~isnan(data)));
end
if all(isnan(data))
   res = NaN;
end

function AvgMeasTime = FunAvgMeasTime(time)
%Calculate average measured time
time = time(~all(time==0|isnan(time),2),:); %måledage er kun dage hvor måletiden ikke er 0, size(time,1) bestemmer antal måledage
if isempty(time)
   AvgMeasTime = NaN;
end
if size(time,1) == 1 %
  AvgMeasTime =  sum(time,2);
end
if size(time,1) == 2 %max of the two
   AvgMeasTime =  max(sum(time,2));
end
if size(time,1) > 2 %average of the two days with maximum measurement period
    aux = sort(sum(time,2),'descend');
    aux = aux(~isnan(aux));
    AvgMeasTime = mean(aux(1:2));
end


function res = CalcPerDag(Kat,Par,data,hour)

ak = Kat{strcmp(Par,Kat(:,2)),1}; %summeringskategori for aktuel parameter
switch ak
%  case 1
 %   res = nansum(nansum(data,2)) ; %first sum within days then sum between days
  case 2
    res = nanmean(nansum(data,2)); %first sum within days then mean between days
  case 7
     res = nanmean(nanmax(data,[],2)); %first max within days then mean between days
  case 8
     res = nanmean(nanmin(data,[],2)); %first min within days then mean between days
  case 10
     res = nansum(nansum(hour.*data))/sum(nansum(hour.*(~isnan(data)))); %hr time weighted average of all intervals  
end
if all(all(isnan(data)))
   res = NaN;
end

function HRpair = FunHRpair
%Liste af HR parameter og tilsvarende varighedsparameter
HRpair = {...
      'HRoff','ThighOff';...
      'HRlie','lie';...
      'HRsit','sit';...
      'HRstand','stand';...
      'HRmove','move';...
      'HRwalk','walk';...
      'HRrun','run';...
      'HRstairs','stairs';...
      'HRcycle','cycle';...
      'HRrow','row';...
      'HRRoff','ThighOff';...
      'HRRlie','lie';...
      'HRRsit','sit';...
      'HRRstand','stand';...
      'HRRmove','move';...
      'HRRwalk','walk';...
      'HRRrun','run';...
      'HRRstairs','stairs';...
      'HRRcycle','cycle';...
      'HRRrow','row'};
  
function Idays = AndOrCrit(tsum,hr,avg,Crit)
  %Find which days meet duration criterium (or/and)
  if strcmp(Crit,'|')
      Idays = tsum >= hr | tsum >= avg; 
  else
      Idays = tsum >= hr & tsum >= avg; 
  end
