function CheckMisOrientation(ID,Type,Start,Stop,AktTid,SF,Vthigh,StdThigh,Vhip,Varm,Vtrunk,BF,OffThigh,OffHip,OffArm,OffTrunk,...
                             IncTrunkWalk,AccThigh,AccTrunk,ObsThighRef,ObsTrunkRef) 

% Quality check during batch run.
%
% Checking for misoriented accelerometer axes, unusual trunk angle
% during walking, confused thigh/trunk accelerometers and row activity.
% An Exceel sheet is opened for writing of comment on issues that should be checked.

persistent InfoSheet

try %check if InfoSheet is (still) open, if not open a new one
  dummy = get(InfoSheet.Application);
catch
  InfoSheet = StartExcel;
end

Info = Check(AktTid,SF,Vthigh,StdThigh,Vhip,Varm,Vtrunk,BF,OffThigh,OffHip,OffArm,OffTrunk,IncTrunkWalk,AccThigh,AccTrunk,ObsThighRef,ObsTrunkRef);

if ~isempty(Info)
   NextRow = InfoSheet.UsedRange.Rows.Count+1;
   Res = {ID,Type,datestr(Start),datestr(Stop),Info};
   %Write data to next row in Excel sheet: 
   Range = get(InfoSheet,'Range',['A',num2str(NextRow),':E',num2str(NextRow)]);
   set(Range,'Value',Res)
   set(Range,'HorizontalAlignment',3)
   InfoSheet.UsedRange.Columns.AutoFit;  
end


function  Info = Check(AktTid,SF,Vthigh,StdThigh,Vhip,Varm,Vtrunk,BF,OffThigh,OffHip,OffArm,OffTrunk,IncTrunkWalk,AccThigh,AccTrunk,ObsThighRef,ObsTrunkRef)
  Info = [];
  isDay = AktTid(7)/AktTid(1)<.25; %less than 25% of lying
  
  if sum(OffThigh)/length(OffThigh)>.99, OffThigh = ones(length(OffThigh),1); end
  if sum(OffTrunk)/length(OffTrunk)>.99, OffTrunk = ones(length(OffTrunk),1); end
  if sum(OffHip)/length(OffHip)>.99, OffHip = ones(length(OffHip),1); end
  if sum(OffArm)/length(OffArm)>.99, OffArm = ones(length(OffArm),1); end
  
  %AktTid: 6-off, 7-lie, 8-sit, 9-stand, 10-move, 11-walk, 12-run, 13-stairs, 14-cycle, 15-row, 16-steps
  
  Vthigh = 180*[mean(reshape(Vthigh(:,1),SF,[]))',mean(reshape(Vthigh(:,2),SF,[]))',mean(reshape(Vthigh(:,3),SF,[]))']/pi; %per sec.
  if isDay && mean(Vthigh(StdThigh(:,1)>.1 & ~OffThigh,1))>120
     Info = 'Thigh accelerometer up-down axis/ ';
  end
  if isDay && mean(Vthigh(StdThigh(:,1)<.1 & ~OffThigh & Vthigh(:,1)>45 ,2))<0 ...%during sitting (mainly)
           && mean(Vthigh(StdThigh(:,1)>.1 & ~OffThigh & Vthigh(:,1)>30 & Vthigh(:,1)<85 ,2))<0 %during activity
     Info = [Info,'Thigh accelerometer forward-backward axis/ '];
  end
 
  if ~isempty(ObsThighRef)
     Info = [Info,'Unexpected shift in thigh reference angle/ '];  
  end
  
  if ~isempty(Vhip)
     Vhip = 180*mean(reshape(Vhip(:,1),SF,[]))/pi; %per sec.
     if mean(Vhip(StdThigh(:,1)>.1 & ~OffThigh & ~OffHip)) > 120
        Info = [Info,'Hip accelerometer up-down axis/ '];
     end
  end
  
  if ~isempty(Varm)
     Varm = 180*mean(reshape(Varm(:,1),SF,[]))/pi; %per sec.
     if mean(Varm(StdThigh(:,1)>.1 & ~OffThigh & ~OffArm)) > 120
        Info = [Info,'Arm accelerometer up-down axis/ '];
     end
  end
  
  if ~isempty(Vtrunk)
      Vtrunk = 180*[mean(reshape(Vtrunk(:,1),SF,[]))',mean(reshape(Vtrunk(:,2),SF,[]))',mean(reshape(Vtrunk(:,3),SF,[]))']/pi; %per sec.
      if mean(Vtrunk(StdThigh(:,1)>.1 & ~OffThigh & ~OffTrunk,1)) > 120 
         Info = [Info,'Trunk accelerometer up-down axis/ '];
      end
      if BF==1 && isDay && mean(Vtrunk(StdThigh(:,1)>.1 & ~OffThigh & ~OffTrunk,2)) < 0 %during walk (mainly), only for back accelerometer
         Info = [Info,'Trunk accelerometer forward-backward axis/ '];
      end
      if BF==-1% Front accelerometer: If lying ("flat", more than 1 minute) is present:
         ii = (abs(Vthigh(:,2)>60 & abs(Vtrunk(:,2))>60)) ...
              & ~OffThigh & ~OffTrunk & (abs(Vthigh(:,3))<30 & abs(Vtrunk(:,3)<30)); %Lying at the back or belly
         if sum(Vthigh(ii,2).*Vtrunk(ii,2) >0)/sum(ii)<.5  && sum(ii)>60 %signs of forward/backward angle should be equal
            Info = [Info,'Trunk (or thigh) accelerometer forward-backward axis/ '];
         end
      end
      if ~isempty(ObsTrunkRef)
         Info = [Info,'Unexpected shift in trunk reference angle/ '];  
      end  
      if IncTrunkWalk<5 || 25<IncTrunkWalk
         Info = [Info,'Unusual mean trunk inclination during walk: ',num2str(IncTrunkWalk,'%4.1f°/ ')];
      end
  end
  
  % Dynamic accelaration is normally higher at the thigh than at the trunk: 
  if isDay && AktTid(1)>1 && sum(std(AccThigh))/sum(std(AccTrunk)) <1 && ~any(OffThigh | OffTrunk) 
     Info = [Info,'Confusion of thigh accelerometer with trunk accelerometer/ '];  
  end
  
  if AktTid(15) > .016667 && AktTid(15)/AktTid(1) > .01
     Info = [Info,['Row activity encountered (',num2str(AktTid(15)*60,'%4.1f minutes)')]]; 
  end
      
  
function InfoSheet = StartExcel
   Excel = actxserver('Excel.Application');
   set(Excel, 'Visible', 1);
   invoke(Excel.Workbooks,'Add');
   InfoSheet = get(Excel.ActiveWorkBook.Sheets,'Item',1);
   invoke(InfoSheet,'Activate');
   Range = get(InfoSheet,'Range','A1:E1');
   set(Range,'Value', {'ID','Type','Start','Stop','Issue to check'})
   Range.EntireRow.Font.Bold = true;
   set(Range,'HorizontalAlignment',3)
   InfoSheet.Name = 'BatchInfo';