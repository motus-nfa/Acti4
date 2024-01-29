function S = Interval2DayResult_ACCpart(ResColNames,Raw,Kat,Params,IDs,Type,Days,Hours,SumMethod,S,Crit,MethodDS)
%Kaldes fra Interval2DayResult, håndterer accelerometer parametrene

for id=1:size(IDs,1)
    iID = strcmp(IDs{id},Raw{1}); %indices for ID
    if any(strcmp({'LonW','WaL','Wol'},SumMethod))
       iID = iID & logical(Raw{6}); %only work days   
    end
    IDdays = unique(Days(iID)); %aktuelle datoer for ID
    Time = zeros(size(IDdays,1),size(Type,2));
    for p=1:length(Params)
        Par = Params{p}; %aktuelt variabelnavn
        Res = nan(size(IDdays,1),size(Type,2));
        Data = Raw{strcmp(Par,ResColNames)}; %tilsvarende kolonne med data (variabelværdier)
        data = Data(iID); %data for aktuel ID
        hours = Hours(iID);
        for d=1:length(IDdays)
            for i=1:size(Type,2)
                di = strncmp(Type(i),Raw{2}(iID),2) & Days(iID) == IDdays(d);
                %di er index for dag/interval relativt iID
                if any(di)
                   Res(d,i) = CalcSammeDag(Kat(:,[1,3]),Par,data(di),hours(di)); %1. kolonne i Kat bruges her
                end
                if p==1 %måletimer
                   Time(d,i) = sum(hours(di));
                end
            end
        end
        
        if p==1 %ved første parameter bestemmes 'average measured time' og hvilke dage der inkluderes,
                %se T:\Objektive målinger\Metode\Acti4\CriteriaExtractDayResults.docx (NGU)
           if strcmp(MethodDS,'Detailed')    
              if strcmp('A',SumMethod) %whole day (waking time)
                 Ix = ismember(Type,{'A1','A2','A3','B1','B2','B3','C0'});
                 AvgMeasTime = FunAvgMeasTime(Time(:,Ix));
                 tsum = sum(Time(:,Ix),2);
                 Idays = AndOrCrit(tsum,10,.75*AvgMeasTime,Crit);
              end
              if strcmp('W',SumMethod) %work only
                 Ix = ismember(Type,{'A2','B2'});
                 AvgMeasTime = FunAvgMeasTime(Time(:,Ix));
                 tsum = sum(Time(:,Ix),2);
                 Idays = AndOrCrit(tsum,4,.75*AvgMeasTime,Crit);
              end
              if strcmp('LonW',SumMethod) %leisure on work days
                 Ix = ismember(Type,{'A1','A3','B1','B3'});
                 AvgMeasTime = FunAvgMeasTime(Time(:,Ix));
                 tsum = sum(Time(:,Ix),2);
                 Idays = AndOrCrit(tsum,4,.75*AvgMeasTime,Crit); 
              end
               if strcmp('LonA',SumMethod) %leisure all days
                 Ix = ismember(Type,{'A1','A3','B1','B3','C0'});
                 AvgMeasTime = FunAvgMeasTime(Time(:,Ix));
                 tsum = sum(Time(:,Ix),2);
                 Idays = AndOrCrit(tsum,4,.75*AvgMeasTime,Crit); 
              end
              if strcmp('WaL',SumMethod) || strcmp('WoL',SumMethod) %work AND/OR leisure
                 %work similar to point 2: 
                 Ix = ismember(Type,{'A2','B2'});
                 AvgMeasTime_2 = FunAvgMeasTime(Time(:,Ix));
                 tsum = sum(Time(:,Ix),2);
                 Idays_2 = AndOrCrit(tsum,4,.75*AvgMeasTime_2,Crit);
                 %leisure similar to point 3:
                 Ix = ismember(Type,{'A1','A3','B1','B3'}); 
                 AvgMeasTime_3 = FunAvgMeasTime(Time(:,Ix));
                 tsum = sum(Time(:,Ix),2);
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
                 AvgMeasTime = FunAvgMeasTime(Time(:,Ix));
                 tsum = sum(Time(:,Ix),2);
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
              time = Time(:,Ix);
              Idays = ~all(time==0|isnan(time),2);
              sumint = nansum(time(Idays,:),2); %sum across intervals 
              AvgMeasTime = sum(sumint.^2)/sum(sumint); %time weighted average across days 
            end
           
           S(id).Ndays = sum(Idays);    
           S(id).Tavg = AvgMeasTime;
           
        end
        
        if strcmp(MethodDS,'Detailed')
           S(id).(Par) = CalcPerDag(Kat(:,2:3),Par,Res(Idays,Ix),Time(Idays,Ix)); %2. kolonne i Kat bruges her
        end
        if strcmp(MethodDS,'Simplified')
           data = Res(Idays,Ix);
           hr = Time(Idays,Ix) .* ~isnan(data);
           if Kat{strcmp(Par,Kat(:,3)),2} == 2 %sum within days the time weighted average between days
              S(id).(Par) = nansum(nansum(data,2) .* sum(hr,2)) / sum(sum(hr,2));
           end
           if any(Kat{strcmp(Par,Kat(:,3)),2} == [3,4]) %mean within days the time weighted average between days
              S(id).(Par) = nansum(nanmean(data,2) .* sum(hr,2)) / sum(sum(hr,2));
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
  case 2
    res =  nanmean(data); 
  case 4
    res =  nansum(hours.*data)/sum(hours);
  case 5
     res =  nanmax(data);
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
if size(time,1) == 1
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
  case 2
    res = nanmean(nansum(data,2)); %first sum within days then mean between days
  case 3
    res = nanmean(nanmean(data,2)); %average of all
  case 4
    res = nansum(nansum(hour.*data))/sum(sum(hour)); %time weighted average of all intervals
end
if all(all(isnan(data)))
   res = NaN;
end

function Idays = AndOrCrit(tsum,hr,avg,Crit)
  %Find which days meet duration criterium (or/and)
  if strcmp(Crit,'|')
      Idays = tsum >= hr | tsum >= avg; 
  else
      Idays = tsum >= hr & tsum >= avg; 
  end

