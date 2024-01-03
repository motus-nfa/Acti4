function Fstep = TrinAnalyse(X,Akt,SF)

% Calculates instantaneous step frequency from the vertical acceleration of the AG at the thigh.
%
% Step frequency is calculated by FFT analysis of a 4 sec. (128 samples) running window with 1 sec. overlap. 
% Generally the spectrum of the vertical thigh acceleration contains peaks for the step frequency, half the step frequency 
% and double the step frequency and any of these could have the highest peak. For walking the acceleration is 1.5-2.5Hz 
% band-pass filtered; for running an additional 3Hz high-pass filter is included. The step frequency is found as the 
% frequency of highest peak in the filtered signals.    
%
% Input:
% X [N]: acceleration of thigh in vertrical direction (x-axis)
% Akt [n]: activity calculated by 'ActivityDetect' (1 sec time scale)
% SF: sample frequency (N=n*SF)
%
%Output:
% Fstep [n]: Step frequency (steps/sec) in a 1 sec time scale

[Bc,Ac] = butter(6,2.5/(SF/2));
Xc = filter(Bc,Ac,X); %2.5Hz low-pass frequency filtering
[Bw,Aw] = butter(6,1.5/(SF/2),'high');
Xw = filter(Bw,Aw,Xc); %1.5-2.5Hz band-pass filtering for walking
[Br,Ar] = butter(6,3/(SF/2),'high');
Xr = filter(Br,Ar,Xw); %extra 3Hz high-pass filter for running

[Fstep,Walk,Run,Stairs] = deal(zeros(size(Akt)));
Walk(Akt==5) = 1;
Run(Akt==6) = 1;
Stairs(Akt==7) = 1;
Alle = Walk+Run+Stairs;
N = length(X);

f = SF/2*linspace(0,1,256); %frequency scale
for i=1:length(Akt) %one calculation every 1 sec. 
  if Alle(i) == 1
    ii =  max(1,i*SF-63):min(i*SF+64,N); %128 samples
    x = detrend(Xw(ii)); %walk is default
    if Run(i)==1, x = detrend(Xr(ii)); end
    Y = fft(x,512);
    A = 2*abs(Y(1:256));
    [Max,I] = max(A);
    %Crest(i) = Max/mean(A);
    Fstep(i) = f(I);
    %  if rem(j,5)==0 % plot for test every 5th calculation
%       if Akt(i)==7
%         figure
%         subplot(2,1,1)
%         t = (0:length(x)-1)/SF;
%         plot(t,x)
%         xlabel('sek.')
%         subplot(2,1,2)
%         plot(f(f<=5),A(f<=5)) 
%         xlabel('Hz')
%      end
  end
end
Fstep = medfilt1(Fstep,3); %6/1-14: changed from 9 to 3 (re ActivityDetect)

%figure
%plot(Crest)

