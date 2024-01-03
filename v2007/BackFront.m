function BF = BackFront(FilTrunk)
%Finds if the FilTrunk refers to back or front accelerometer position
[~,Navn] = fileparts(FilTrunk);
if isempty(cell2mat(regexp(lower(Navn),{'front','chest','sternum','bryst'})))
   BF = 1; %back
else
   BF = -1; %front
end
