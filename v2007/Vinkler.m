function  [V,A,M,L,m] = Vinkler(Fil,Start,Slut,ShiftAxes)

% Reading of acceleration data from file and calculation of angles (2Hz low-pass filtered).
% Acceleration values are assumed to be caused by gravitation (quasi-stationarity).  
% 16/1-20: New synchronization method pads NaNs in the beginning/end of some files, 
% which cause filter to fail. NaNs are replaced with zeroes before filtering and replaced again after filtering.  
% 4/2-20: possibility to shift axes for mis-orientated accelerometer, se function CheckBatchString
%
% Input:
% Fil: Full name of AG data file.
% Start: Start time (datenum).
% Slut: End time (datenum).
% ShiftAxes: 1, 2 or 3 for shifting accelerometer orientation up/down, in/out or both (4/2-20)
%
% Output:
% V [N,3]: Inclination, forward/backward angle, sideways angle (rad).
% A [N,3]: Acceleration (G).
% M [N,3]: 2 Hz low-pass filtered acceleration.
% L [N]: Length of acceleration vector (filtered).
% m [N,3]: Normalized M

   [A,SF] = ReadAG(Fil,Start,Slut);
   if ShiftAxes %4/2-20
      A = ShiftAxesFnc(ShiftAxes,A); 
   end
   
   ErNan = any(any(isnan(A))); %16/1-20
   if ErNan
      A(isnan(A)) = 0; 
   end
   
   [Blp,Alp] = butter(6,2/(SF/2));
   M = filter(Blp,Alp,A);
 
   if ErNan %16/1-20
      M(isnan(A)) = NaN; 
   end
   
   L = sqrt(M(:,1).^2 + M(:,2).^2 + M(:,3).^2);
   L(L<.001) = NaN; %1/5-20
   m = M./repmat(L,1,3);
   Inc = acos(m(:,1));
   U = -asin(m(:,3));
   V = [Inc,U,-asin(m(:,2))];

   
function Y = ShiftAxesFnc(ShiftAxes,X)
% Shift of acclerometer orientation, 4/2-20

 if ShiftAxes == 1 %up/down shift
    Y = [-X(:,1),-X(:,2),X(:,3)]; 
 end
 if ShiftAxes == 2 % in/out shift
    Y = [X(:,1),-X(:,2),-X(:,3)]; 
 end
 if ShiftAxes == 3 % both shifts
    Y = [-X(:,1),X(:,2),-X(:,3)]; 
 end
   
   