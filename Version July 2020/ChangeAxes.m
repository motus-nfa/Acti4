function  Acc = ChangeAxes(Acc,Type,Orientation)

% Change the orientation of accelerometer axes during conversion of accelerometer data to act4-file. 
%
% Type (text): ActiGraph, Axivity, ActivPAL or Sens
% Orientation: 1, 2, 3 or 4
%
% Standard Acti4 orientationn: x downwards, z outward from body surface (Manufacturer serial number inward)
% For Sens accelerometer serial number side must be outwards!

if strcmp(Type,'ActiGraph') || strcmp(Type,'Axivity') || strcmp(Type,'Sens') %SENS MUST BE CHECKED!
   if Orientation == 2 %up/down shift, 23/12-19: text corrected
      Acc = [-Acc(:,1),-Acc(:,2),Acc(:,3)]; 
   end
   if Orientation == 3 %in/out shift, 23/12-19: text corrected
      Acc = [Acc(:,1),-Acc(:,2),-Acc(:,3)]; 
   end
   if Orientation == 4 %both up/down and in/out shift
      Acc = [-Acc(:,1),Acc(:,2),-Acc(:,3)]; %fortegnsfejl rettet 3/2-20 
   end
end

%Must be checked again:
if strcmp(Type,'ActivPAL')
   %ActiPAL's Y- and Z-axis are inverse to those of ActiGraph and Axivity 
   if Orientation == 1 %in/out
      Acc = [Acc(:,1),-Acc(:,2),-Acc(:,3)]; 
   end
   if Orientation == 2 %
      %unchanged 
   end
   if Orientation == 3 %up/down
      Acc = [-Acc(:,1),Acc(:,2),-Acc(:,3)]; 
   end
   if Orientation == 4 %in/out and up/down
      Acc = [-Acc(:,1),-Acc(:,2),Acc(:,3)];  
   end
end


