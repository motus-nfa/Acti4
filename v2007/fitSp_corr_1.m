function [Y,f] = fitSp_corr_1(x,t)

% Robust spectral estimation of non-uniform sampled data.
% This is a slightly modified version of 'Y=fitSp_corr(inp,t,regrtype)' referenced in:
%    Miika Ahdesmäki, Harri Lähdesmäki, Andrew Gracey, llya Shmulevich and Olli Yli-Harja. 
%    Robust regression for periodicity detection in non-uniformly sampled time-course gene expression data.
%    BMC Bioinformatics 2007, 8:23.
%
% Compared to [Y] = fitSp_corr(inp,t,regrtype), [Y,f] = fitSp_corr_1(x,t) do not accept matrix input (inp) but only 
% 1-dimnesional input (x, vector) and there is no 'regrtype' option. The output includes the calculated frequencies (Hz). 
%
% Input: x is the input data vector, t is the time point vector. 
% Output: Y contains the estimated power spectrum at the frequencies f.
%........................................................................................................................
% The function finds a robust spectral estimate iteratively. The method
% uses residuals of the last fitting round to fit sinusoidals into the
% data. Performed this way we can avoid over fitting 

t = t(:); %must be column vector
x = x(:); 

N = length(t);
n = (t - t(1)) / (t(end) - t(1)) * (N-1); % Rational time indices
k = 0:floor(N/2); % if N is even, the pi-frequency (N/2) must be handled separately
isEven = 1-mod(N,2);
if isEven
   f = (k/N) * (N-1)/(t(end)-t(1));
else
   f = k/(t(end)-t(1));
end
K = length(k);
temp = kron(n,k);
sines = sin(2*pi*temp/N);   % The sines we use in regression
cosines = cos(2*pi*temp/N); % The cosines we use in regression
% Notice that the first columns in "sines" and "columns" are obsolete
% and will be ignored in the following by "clever" indexing

X = x;
A = zeros(K,2);
% first subtract the location
DC = location(X,N);
A(1,1) = DC;
for jj = 2:(K-1)
   B=othFreqs(X,sines(:,jj),cosines(:,jj));
   A(jj,:) = B;
end
if isEven  % if N is even then the a_N/2
   B=even_Pi(X,n);
   A(K,1) = B;
else
   B=othFreqs(X,sines(:,K),cosines(:,K));
   A(K,:) = B;
end
Y = N / 4 * (A(:,1).^2 + A(:,2).^2);

A = zeros(K,2);
tempsp = Y;
[~,index] = sort(tempsp,1,'descend');
% first subtract the location
[DC,RESID] = location(X,N);
A(1,1,1) = DC;
X = RESID;
for jj = 1:K
    if index(jj) == 1
        %do nothing, location has been already taken care of
    elseif index(jj)==K && isEven  % if N is even then the a_N/2)
        [B,RESID]=even_Pi(X,n);
        A(K,1) = B;
        X = RESID;
    else
        [B,RESID]=othFreqs(X,sines(:,index(jj)),cosines(:,index(jj)));
        A(index(jj),:) = B;
        X = RESID;
    end
end
Y = N / 4 * (A(:,1).^2 + A(:,2).^2);    % the factor N/4 is motivated in Priestley (1981) p. 397


%%%%%%%THE DC-LEVEL%%%%%%%%%%%%%%
function [DC,RESID] = location(X,N)
  [B,STATS] = robustfit(ones(N,1),X,'bisquare',4.6851,'off');   % location estimate
  DC = 2*B;
  RESID = STATS.resid;

%%%%%%%OTHER FREQUENCIES%%%%%%%%%
function [B,RESID] = othFreqs(X,sine,cosine)
% large tuning constant for gaussian noise, smaller for outlier-
% contaminated data
   [temp,STATS] = robustfit([sine,cosine],X,'bisquare',4.6851,'on');
   B = temp(2:3);
   RESID = STATS.resid;

%%%%%%%IN CASE N IS EVEN%%%%%%%%%%%%%%
function [B,RESID] = even_Pi(X,n)
    cosine = cos(pi*n)';
   [temp,STATS] = robustfit(cosine,X,'bisquare',4.6851,'on');   % location estimate
    B = 2*temp(2);
    RESID = STATS.resid;
