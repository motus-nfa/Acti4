function Acc12 = Acc60(Acc,SF)
% Re-arrangement of data in Acc matrix.
% The function dublicatse and arrange the array data in Acc [N,3] into an
% array Acc12 [2*SF,N,3], in which each column contains data for every 2 adjacent seconds.
% Use for calculation of resumé parameters calculated for 2 seconds intervals in 1 second steps. 
% SF: Sample frequency
% Length of Acc must be N*SF (N integer) 

Acc1 = [Acc(1:SF,:);Acc];
Acc2 = [Acc;Acc(end-SF+1:end,:)];
Acc12 = [reshape(Acc1,SF,[],3);reshape(Acc2,SF,[],3)];
Acc12 = Acc12(:,1:end-1,:); %first second is dublicated
