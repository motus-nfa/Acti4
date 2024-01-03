function  [Acal,Exit1] = AutoCalibration(varargin)

% Auto calibration of act4-files.
%
% varargin empty: Called from main menu.
% User selection of act4-file for calibration and specification of folder for saving the
% calibrated files. Filenames for calibrated (output) files are identical with input files. 
% If no folder is selected for saving, the calibration procedure is performed and the result 
% are displayed without saving of calibrated files.
%
% vargin{1:4}: Acceleration, samplefrequency, serial number, file name.
% Called from one of the functions converting raw acceleration to act4-file.
%
% Calibration results are displayed in a Excel sheet with the columns:  
% File: Filename
% Ser.No: Serial number of accelerometer
% Date: Date
% Npoint: Number of points in calibration data set
% HullVol: Volume of minimal convex hull for data set
% Err: Calibration error (mean, absolute value of residuals by fit to ellipsoid surface)
% Ax, Bx, Ay, By, Az, Bz: Calibration coefficients for the 3 accelerometer axes 
% p: estimated p-value for risk of any calibration coefficient to be more than 0.05 off  
% Outcome (=Exit1): OK, Uncertain, Failed
%
% Method
% Acceleration are split in 10 seconds intervals and intervals with std<.013 in all directionsless
% are selected (van Hess et al.: J. Appl Physiol 117: 738-744,2014). A subset of points with
% mutual distances > 0.05 is fitted to an ellipsoid, which determines the calibration coefficients. 
% Volume of the convex hull for the subset are used for estimating accuracy of the calibration. 

persistent CalibrationSheet %(relevant when called with input list)

if isempty(varargin)
   [FileNames,PathName] = uigetfile('.act4','Select act4-files for calibration','MultiSelect','on');
   if isnumeric(FileNames), return, end
   if ~iscell(FileNames), FileNames={FileNames}; end
   cd(PathName);
   cd ..
   SaveFolder = uigetdir([],'Select folder for saving calibrated act4-files');
   if strcmp(SaveFolder,PathName(1:end-1))
      Ans = questdlg('act4-file will be overwritten!','Warning','OK','Cancel','Cancel');
      if strcmp(Ans,'No'), return, end
   end
   
   Sheet = StartExcel; %Opens a new excel sheet for writing result, writes column names
   
   for j=1:length(FileNames)
       disp([num2str(j),': ',FileNames{j}])
       File = fullfile(PathName,FileNames{j});
       [SN,SF,Start,End,Stop,Down,~,Nsamples] = AGinfo(File);
       [A,~,~,~,AccType] = ReadACT4(File);
       [Acal,Exit1] = Auto1(A,SF,SN,FileNames{j},Sheet);    
   
      %Save if save folder selected and calibration did not fail:
       if ischar(SaveFolder) && ~strcmp(Exit1,'Failed')
          Data = uint16(1000*(Acal+10)); %OBS: data transformed to integer (2 bytes)
          AccTypeCal = str2num([num2str(AccType),'1']); %calibrated accelerometer type: '1' added 
          Fid = fopen(fullfile(SaveFolder,FileNames{j}),'w'); %overwrite if exist
          fprintf(Fid,'%s',repmat(' ',100)); %first part of file flushed with 'spaces'
          fseek(Fid,0,'bof');
          fprintf(Fid,'%d\n',AccTypeCal); 
          fprintf(Fid,'%s\n',SN);
          fprintf(Fid,'%d\n',SF);
          fprintf(Fid,'%f\n',Start);
          fprintf(Fid,'%f\n',End);
          fprintf(Fid,'%f\n',Stop);
          fprintf(Fid,'%f\n',Down);
          fprintf(Fid,'%d\n',Nsamples);
          fseek(Fid,100,'bof'); %data always start at byte 100
          fwrite(Fid,Data','uint16');
          fclose(Fid);
       end   
   end
   
else %called from one of the functions converting raw data to act4-files
    [A,SF,SN,FileName] = varargin{1:4};
    if isempty(CalibrationSheet)
      CalibrationSheet = StartExcel; %Opens a new excel sheet for writing result
    end
    try %check if Sheet is still open, if not open a new one
      dummy = get(CalibrationSheet.Application);
    catch
      CalibrationSheet = StartExcel;
    end
    [Acal,Exit1] = Auto1(A,SF,SN,FileName,CalibrationSheet);
end


 function [Acal,Exit] = Auto1(A,SF,SN,FileName,Sheet)
  
    %Calculate calibration data 
    [Acal,N,Vol,K,Err,Exit,V] = Auto2(A,SF,.05); 
    if strcmp(Exit,'Failed')
       [Acal,N,Vol,K,Err,Exit,V] = Auto2(A,SF,.2); %if falure, try a smaller data set
    end        
        
    % Logistic regression for prediction of uncertainty of calibration coefficient from convex hull volume 
    % Regression coefficients (B) are obtained from analysis of 
    % data from Vuggestue R1 and 3F (1666 files), goodness of fit for model: ROC curve area 0.87.
    B = [-0.475237870840026;-3.15446875719019];
    p(1) = NaN;
    if ~strcmp(Exit,'Failed')
       p = mnrval(B,Vol); % estimate p-value for risk of calibration coefficient to be more than 0.05 off
       if p(1) > .05 || Err >.01   %Err (17/2-20)
          Exit = 'Uncertain';
       end 
    end
  
    NextRow = Sheet.UsedRange.Rows.Count+1;
    Res = cat(2,{num2str(NextRow-1),FileName,SN,datestr(now,1),num2str(N),num2str(Vol,'%4.2f')},num2str(Err,'%5.3f'),...
                cellstr(num2str(reshape(flip(K),[],1),'%5.3f '))',num2str(p(1),'%5.3f'),Exit);
  
    %Write data to next row in Excel sheet: 
    Range = get(Sheet,'Range',['A',num2str(NextRow),':O',num2str(NextRow)]);
    set(Range,'Value',Res)
    set(Range,'HorizontalAlignment',3)
    Sheet.UsedRange.Columns.AutoFit;
    Range = get(Sheet,'Range',['G',num2str(NextRow),':N',num2str(NextRow)]);
    set(Range,'NumberFormat','#,##0.000');

    
    %Ellipsoid plot in case on 'Uncertain' or 'Failed' result
    if strcmp(Exit,'Uncertain') || strcmp(Exit,'Failed')
       PlotUncertain(K,V,FileName)
    end


function [Acal,N,Vol,K,Err,Exit,V] = Auto2(A,SF,d)
   %Calculate calibration, d is min. mutual distance between points  
   Vol = [];
   Acal = [];
   Err = NaN;
   K = NaN(2,3);
   nsek=10;
   Vf = FindCalSegment(A,SF,nsek,d); %search from the start of data
   Ab = flip(A);
   Vb = FindCalSegment(Ab,SF,nsek,d); %search from the end of data
   V = [Vf;Vb]; %merge both
   N = length(V);
   if N<6
      Exit = 'Failed'; 
      return
   end
   [~,Vol] = convhull(V);
   if Vol<.1 || Vol>4.2 %max Vol er 4pi/3 = 4.12, invalide data
      Exit = 'Failed'; 
      return
   end
   [K,Err,Vol,Exit,V] = BeregnK(V); %inkluderer 3 betingelser der kan give 'Failed' 
   Acal = [K(2,1)*A(:,1)+K(1,1),K(2,2)*A(:,2)+K(1,2),K(2,3)*A(:,3)+K(1,3)];
       
function V = FindCalSegment(A,SF,nsek,d)
  %Find data set for calibration
  V = [];
  Al = sqrt(sum(A.^2,2)); %vektorlængder
  A = A(Al>.5,:); %defekte data hvor acceleration er [0,0,0] kan forekomme, fjernes (ellers går lsqnonlin ned)
  A = A(1:nsek*SF*fix(length(A)/(nsek*SF)),:); %length(A) skal være multiplum af n sek
 
  Am = squeeze(mean(reshape(A',3,nsek*SF,[]),2))'; %mddel over n sek. for hver akse
  %Arng = squeeze(range(reshape(A',3,nsek*SF,[]),2))'; %max-min over n sek. for hver akse
  Astd = squeeze(std(reshape(A',3,nsek*SF,[]),0,2))'; %mddel over n sek. for hver akse
  %I = find(all(Arng<.02,2));
  I = find(all(Astd<.013,2));
  if isempty(I)
     return
  end
  V = Loop(I,Am,d);
 
  function V = Loop(I,Am,d)
    %Selection of subset with mutual distances > d  
    V = zeros(1000,3);    
    V(1,:) = Am(I(1),:);
    j=2;
    for i=2:length(I)
        if all(sqrt(sum((V(1:j-1,:)-repmat(Am(I(i),:),j-1,1)).^2,2)) >d)
           V(j,:) = Am(I(i),:);
           j=j+1;
        end
    end
    V = V(1:j-1,:);
    V = V(sum(V.^2,2)<2,:); %extreme outliers removed (17/-20)
    
function [K,Err,Vol,Exit,V] = BeregnK(V)
   %Ellipsoid fitting 
   options = optimoptions('lsqnonlin','Jacobian','on','Display','off');
   [K,~,res] = lsqnonlin(@(x) fun(x,V),[0,0,0;1,1,1],[],[],options);
   %res er lig Lng = sqrt(sum(Vcal.^2,2)) -1;
   %Ny beregning kun med punkter hvor normaliserede residualer < 2.5 (outliers fjernes)
   V = V(abs(res/std(res))<2.5,:); %ny V
   Err = mean(abs(res)); %kalibreringsfejl
   [K,~,~,ExitFlag] = lsqnonlin(@(x) fun(x,V),K,[],[],options);
   [~,Vol] = convhull(V);
 
   Exit = 'OK';
   %3 betingelser for 'Failed':
   if  ExitFlag <0 || any(abs(K(1,:))>.5) || any(abs(K(2,:)-1)>.5) || Err > .1 %Err ændret (17/2-20)
       Err = NaN;
       K = NaN(2,3);
       Exit = 'Failed'; 
   end
  
function [F,J] = fun(x,b)
   bx = [x(2,1)*b(:,1)+x(1,1), x(2,2)*b(:,2)+x(1,2), x(2,3)*b(:,3)+x(1,3)];
   F = sqrt(sum(bx.^2,2))-1; 
   dfdx11 = (x(2,1)*b(:,1)+x(1,1))./(F+1);
   dfdx21 = b(:,1).*dfdx11;
   dfdx12 = (x(2,2)*b(:,2)+x(1,2))./(F+1);
   dfdx22 = b(:,2).*dfdx12;
   dfdx13 = (x(2,3)*b(:,3)+x(1,3))./(F+1);
   dfdx23 = b(:,3).*dfdx13;
   J = [dfdx11,dfdx21,dfdx12,dfdx22,dfdx13,dfdx23];
  
function PlotUncertain(K,V,File) 
   %Ellipsoid plot in case of 'Uncertain' 
   Vcal =  [K(2,1)*V(:,1)+K(1,1),K(2,2)*V(:,2)+K(1,2),K(2,3)*V(:,3)+K(1,3)];
   figure
   [X,Y,Z] = sphere;
   surf(X,Y,Z,'FaceColor',[.95 .95 .95],'FaceAlpha',.5)
   axis([-1.25 1.25 -1.25 1.25 -1.25 1.25])
   xlabel('X'), ylabel('Y'), zlabel('Z')
   line(V(:,1),V(:,2),V(:,3),'LineStyle','none','Marker','*')
   title(File,'Interpreter','None') 
   line(Vcal(:,1),Vcal(:,2),Vcal(:,3),'LineStyle','none','Marker','o','MarkerEdgeColor','r','MarkerFaceColor','none')
  
function Sheet = StartExcel
   Excel = actxserver('Excel.Application');
   set(Excel, 'Visible', 1);
   invoke(Excel.Workbooks,'Add');
   Sheet = get(Excel.ActiveWorkBook.Sheets,'Item',1);
   invoke(Sheet,'Activate');
   Range = get(Sheet,'Range','A1:O1');
   set(Range,'Value', {'No','File','Ser.No','Date','Npoint','HullVol','Err','Ax','Bx','Ay','By','Az','Bz','p','Outcome'})
   Range.EntireRow.Font.Bold = true;
   set(Range,'HorizontalAlignment',3)
   Sheet.Name = 'Act4_Calibration';
