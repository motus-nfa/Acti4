function WriteAct4(Data,File,Ver,SN,SF,Start)


  Nsamples = length(Data);
  End = Start + (Nsamples-1)/SF/86400; %end time of recording
  Stop = NaN; %Stop time (used in ActiLife 5)
  Down = NaN; %Stop time (used in ActiLife 5)
  Data16 = uint16(1000*(Data+10)); %OBS: data transformed to integer (2 bytes)
  Fid = fopen(File,'w'); %overwrite if exist
  fprintf(Fid,'%s',repmat(' ',100)); %first part of file flushed with 'spaces'
  fseek(Fid,0,'bof');
  fprintf(Fid,'%d\n',Ver); 
  fprintf(Fid,'%s\n',SN);
  fprintf(Fid,'%d\n',SF);
  fprintf(Fid,'%f\n',Start);
  fprintf(Fid,'%f\n',End);
  fprintf(Fid,'%f\n',Stop);
  fprintf(Fid,'%f\n',Down);
  fprintf(Fid,'%d\n',Nsamples);
  fseek(Fid,100,'bof'); %data always start at byte 100
  fwrite(Fid,Data16','uint16');
  fclose(Fid);
