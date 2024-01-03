function [Acc,Start] = ReadSENSbin(File,SF)

%Reads Sens binary file and resample to SF Hz

Fid = fopen(File);
D = fread(Fid,[6,Inf],'int16=>int16',0,'b')'; %6 bytes (Unix ms), 2 bytes (X), 2 bytes (Y), 2 bytes (Z)
fclose(Fid);
A = single(D(:,4:6))*.008; %Acceleration
T = double([typecast(D(:,1),'uint16'),typecast(D(:,2),'uint16'),typecast(D(:,3),'uint16')]) * [2^32,2^16,1]';
Tsens = datenum('1970/01/01') + T/1000/86400 + 2/24; %UTC
Time = Tsens(1):1/(86400*SF):Tsens(end);
Acc = interp1(Tsens,A,Time,'linear');
Start = Tsens(1);    