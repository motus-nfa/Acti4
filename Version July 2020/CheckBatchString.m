function ShiftAxes = CheckBatchString(Str)

% Decoding of string in column E in Setup file for change of accelerometer orientation (5/5-20)
%
% Str: general format, ThighXHipXArmXTrunkXCalfX, or any substring e.g. ThighX, HipXTrunkX, ...
% X: 1 - up/down shift, 2 - front/back shift, 3 - up/down and front/back shift
% ShiftAxes [5,1]: Contains the value X for each accelerometer, row 1...5: Thigh, Hip, Arm, Trunk, Calf.
% Se function Vinkler for use of ShiftAxes.

ShiftAxes = zeros(5,1);
try
    iThigh = strfind(Str,'Thigh');
    if ~isempty(iThigh)
       ShiftAxes(1) = str2double(Str(iThigh+5));
    end
catch
end

try
    iHip = strfind(Str,'Hip');
    if ~isempty(iHip)
       ShiftAxes(2) = str2double(Str(iHip+3));
    end
catch
end

try
    iArm = strfind(Str,'Arm');
    if ~isempty(iArm)
       ShiftAxes(3) = str2double(Str(iArm+3));
    end
catch
end
    
try    
    iTrunk = strfind(Str,'Trunk');
    if ~isempty(iTrunk)
       ShiftAxes(4) = str2double(Str(iTrunk+5));
    end
catch
end

try    
    iCalf = strfind(Str,'Calf');
    if ~isempty(iCalf)
       ShiftAxes(5) = str2double(Str(iCalf+4));
    end
catch
end

for i=1:5
    if ~any(ShiftAxes(i)==[1,2,3])
       ShiftAxes(i) = 0;
    end
end
