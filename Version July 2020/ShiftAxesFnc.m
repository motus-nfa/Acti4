function Y = ShiftAxesFnc(ShiftAxes,X)

% Shift of acclerometer orientation. Called from Vinkler.m

 if ShiftAxes == 1 %up/down shift
    Y = [-X(:,1),-X(:,2),X(:,3)]; 
 end
 if ShiftAxes == 2 % in/out shift
    Y = [X(:,1),-X(:,2),-X(:,3)]; 
 end
 if ShiftAxes == 3 % both shifts
    Y = [-X(:,1),X(:,2),-X(:,3)]; 
 end

