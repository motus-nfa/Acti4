function  [pv,Varkoef] = Stationaritet(X,n)

% Test for stationarity of heart rate RR series (X)
% X is divided in n intervals and tested for equal variance across the
% intervals. Small pv -> probably not stationary data.

N = length(X);
for i=1:n  %Gruppering i n intervaller (1,2...,5)  
   I = 1+round((i-1)*N/n):round(i*N/n);
   Grp(I,1) = i;
   Variansn(i) = var(X(Grp==i));
end

%pv = vartestn(X,Grp,'off','robust'); %Levines test
pv = vartestn(X,Grp,'testtype','BrownForsythe','display','off');

Varkoef =  std(Variansn)/mean(Variansn);


