
function   [VrefTrunk,VrefArm,VrefHip,VrefThigh] = CalcRef(Intervals,FilTrunk,FilArm,FilThigh,FilHip)

% Calculation of reference data from ref intervals in the Setup file.
% Ref intervals are optional. If absent, NaNs are returned. Estimated reference angles are then
% calculated by EstimateRefThigh and EstimateRefTrunk called from AnalyseAndPlot. 

% Input:
% Intervals: Cell array [nx4] including type, day of week, start and stop times of all diary intervals
% FilTrunk,FilArm,FilThigh,FilHip: Full filenames of of AG thigh, hip, arm and trunk
% StartActi: Start time of AG recording (datenum)

% Output:
% VrefTrunk,VrefArm,VrefHip,VrefThigh [3]: Reference angles [INC,U,V] of AG trunk, arm, hip and thigh
% Removed 9/12-19: dT: Struct with the fields hip, arm and trunk, specifying delays relative to AG thigh

  % Reference:
     Rind = find(strncmp('F.',Intervals(:,1),2)); %row index in Intervals for Ref. intervals
     [VrefThigh,VrefHip,VrefArm,VrefTrunk] = deal(NaN(length(Rind),3));
     %Reference values outside these intervals are not accepted:
     %(based on all BAuA data: approx. ±3std)
     Vmin = (pi/180)*[  0   0  0   0;... 
                      -32 -35 -14  5;...
                      -15 -20 -22 -15];
     Vmax = (pi/180)*[ 32  32  22  53;... 
                        0  35  18  50;...
                       15  20  15  15];
                   
     if ~isempty(Rind)
         for i=1:length(Rind)
             
           ShiftAxes = zeros(4,1); %4/2-20: for realigning shifted axes, se function CheckBatchString
           if ~isempty(Intervals{Rind(i),5}) && ischar(Intervals{Rind(i),5})
              ShiftAxes = CheckBatchString(Intervals{Rind(i),5});
           end 
             
           RefStart = AfkodTid(Intervals{Rind(i),3});
           RefEnd = AfkodTid(Intervals{Rind(i),4});
           if ~isempty(FilThigh)
               Vthigh = mean(Vinkler(FilThigh,RefStart,RefEnd,ShiftAxes(1)));
               %29/11-12 all VrefThigh are accepted and the median value is used in 'ActivityDetect'
               %if all(Vmin(:,1)<Vthigh' & Vthigh'<Vmax(:,1)),  VrefThigh(i,:) = Vthigh; end
               VrefThigh(i,:) = Vthigh;
           end
           if ~isempty(FilHip)
               Vhip =  mean(Vinkler(FilHip,RefStart,RefEnd,ShiftAxes(2)));
               %if all(Vmin(:,2)<Vhip' & Vhip'<Vmax(:,2)),  VrefHip(i,:) = Vhip; end
               if sum(Vmin(:,2)<Vhip' & Vhip'<Vmax(:,2))>=2,  VrefHip(i,:) = Vhip; end %2 angles inside interval then ok (29/1-13)  
           end
           if ~isempty(FilArm)
              Varm = mean(Vinkler(FilArm,RefStart,RefEnd,ShiftAxes(3)));
              %if all(Vmin(:,3)<Varm' & Varm'<Vmax(:,3)),  VrefArm(i,:) = Varm; end
              if sum(Vmin(:,3)<Varm' & Varm'<Vmax(:,3))>=2,  VrefArm(i,:) = Varm; end %2 angles inside interval then ok (29/1-13)
           end
           if ~isempty(FilTrunk)
               Vtrunk = mean(Vinkler(FilTrunk,RefStart,RefEnd,ShiftAxes(4)));
               %if all(Vmin(:,4)<Vtrunk' & Vtrunk'<Vmax(:,4)),  VrefTrunk(i,:) = Vtrunk; end
               if sum(Vmin(:,4)<Vtrunk' & Vtrunk'<Vmax(:,4))>=2,  VrefTrunk(i,:) = Vtrunk; end %2 angles inside interval then ok (29/1-13)
            end
         end
     end

