function varargout = Reference(varargin)
% REFERENCE MATLAB code for Reference.fig
%
% For plotting and editing of reference intervals; edited intervals are saved in the Setup file.
%
% Input arguments
% #1: Running number of subject (ID = name of worksheet in setup file)
% #2: Full file name of AG trunk
% #3: Start of reference time (datenum)
% #4: Stop of reference time (datenum)
% #5: Indices numbers in time array (T) corresponding to reference interval
% #6: Time array (datenum), normally approx. ±10 minuttes in each side of reference interval
% #7: Row number for reference data in setup file (ID worksheet)
% #8: Column number for reference data in setup file (ID worksheet)
% #9: Angles (Inc,U,V) of all AGs in time interval T [struct]
% #10: Full file name of AG thigh

% Output is the string 'Next' or 'Cancel'

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Reference_OpeningFcn, ...
                   'gui_OutputFcn',  @Reference_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Reference is made visible.
function Reference_OpeningFcn(hObject, ~, H, varargin)
H.output = hObject;
argin = varargin{1};
H.data.ID = argin{1}; %running number of subject
[~,H.data.FilTrunkNavn] = fileparts(argin{2}); %full file name of AG trunk
H.data.RefStart = argin{3}; %start of reference time (datenum)
H.data.RefEnd = argin{4}; %end of reference time (datenum)
Iref = argin{5}; %indices in time array (T) corresponding to reference interval
H.data.DateOffset = fix(argin{6}(1) - 10); %in order to zoom into very small time intervals
H.data.T = argin{6} - H.data.DateOffset; %20 (normally) minuttes time array, datenum values offset to approx. 10 
H.data.Irow = argin{7}; %row number for reference data in setup file (ID worksheet)
H.data.Icol = argin{8}; %column number for reference data in setup file (ID worksheet)
set(H.RefStart,'string',datestr(argin{3},'dd/mm/yyyy/HH:MM:SS'))
set(H.RefEnd,'string',datestr(argin{4},'dd/mm/yyyy/HH:MM:SS'))
V = argin{9}; %angles (Inc,U,V) of all AGs in time interval T
H.data.V = V;
[~,H.data.FilThighNavn] = fileparts(argin{10}); %full file name of AG thigh

% Plot angles (Inc,U,V) of the 4 AGs for the reference interval:
subplot(H.thighgraf);
  plot(V.Thigh(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Thigh (°)')
subplot(H.hipgraf);
  plot(V.Hip(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Hip (°)')
subplot(H.armgraf);
  plot(V.Arm(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Arm (°)')
subplot(H.trunkgraf);
  plot(V.Trunk(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Trunk (°)')

%Plot angles (Inc,U,V) of AG trunk and thigh in the 20 minuttes graph: 
subplot(H.thighgraf20)

  plot(H.data.T,V.Thigh)
  datetick('x','HH:MM:SS')
  axis tight
  ylabel('Thigh (°)');
  line([H.data.T(Iref(1)),H.data.T(Iref(end));H.data.T(Iref(1)),H.data.T(Iref(end))],[ylim',ylim'],'Color','k','LineStyle',':')
subplot(H.trunkgraf20)
  plot(H.data.T,V.Trunk)
  ylabel('Trunk (°)');
  datetick('x','HH:MM:SS')
  axis tight
  line([H.data.T(Iref(1)),H.data.T(Iref(end));H.data.T(Iref(1)),H.data.T(Iref(end))],[ylim',ylim'],'Color','k','LineStyle',':')
Xakse = xlim;
  
set(H.Start,'string',datestr(Xakse(1),'HH:MM:SS'))
set(H.End,'string',datestr(Xakse(2),'HH:MM:SS'))
set(zoom,'ActionPostCallback',@OpdaterZoom);
set(zoom,'Enable','on');
set(H.Save,'Enable','Off')
set(H.Update,'Enable','Off')
guidata(hObject,H);

%Set up table for displaying mean values of AG angles and normal range values:
%Set column width in tables
set(H.INC,'Units','pixel')
Ppix = get(H.INC,'Position');
set(H.INC,'Units','Normalized')
Px = .93*Ppix(3);
Cwidth = num2cell([.26*[Px Px Px] .18*Px]);
set(H.INC,'ColumnWidth',Cwidth)
set(H.Uangle,'ColumnWidth',Cwidth)
set(H.Vangle,'ColumnWidth',Cwidth)

%Calculate mean values of angles and check for normal range
K = round([mean(V.Thigh(Iref,:))',mean(V.Hip(Iref,:))',mean(V.Arm(Iref,:))',mean(V.Trunk(Iref,:))']);
Ktable = Check(K,H);
set(H.INC,'Data',Ktable(1,:));
set(H.Uangle,'Data',Ktable(2,:));
set(H.Vangle,'Data',Ktable(3,:));
%Display mean angles in the figure 'RefValues' for displaying the different reference values of the subject  
hRefValues = findobj('Name','RefValues');
hCeller = findobj(hRefValues,'Tag','INCthigh');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(1,1)));
hCeller = findobj(hRefValues,'Tag','Uthigh');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(2,1)));
hCeller = findobj(hRefValues,'Tag','Vthigh');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(3,1)));
hCeller = findobj(hRefValues,'Tag','INChip');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(1,2)));
hCeller = findobj(hRefValues,'Tag','Uhip');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(2,2)));
hCeller = findobj(hRefValues,'Tag','Vhip');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(3,2)));
hCeller = findobj(hRefValues,'Tag','INCarm');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(1,3)));
hCeller = findobj(hRefValues,'Tag','Uarm');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(2,3)));
hCeller = findobj(hRefValues,'Tag','Varm');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(3,3)));
hCeller = findobj(hRefValues,'Tag','INCtrunk');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(1,4)));
hCeller = findobj(hRefValues,'Tag','Utrunk');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(2,4)));
hCeller = findobj(hRefValues,'Tag','Vtrunk');
set(hCeller,'Data',cat(2,get(hCeller,'Data'),K(3,4)));
uicontrol(H.Next)
uicontrol(H.Next)

uiwait(H.Reference);

function Ktable = Check(K,H)
%Check mean reference angles in K [3,4](Inv, U and V for 4 AGs) for 'normal' values, if outside
% a ±2std range (based on all BAuA data) 'Abnormal reference values' is displayed.
if BackFront(H.data.FilTrunkNavn) == 1 %AG at the back
   Kmin = [  6   0  0   9;... %minimum values for 'normal' K
           -25 -25 -9   9;...
           -10 -15 -16 -7];
   Kmax = [ 27  25  17  44;... %maximum values for 'normal' K
            -5  25  13  44;...
            10  15   8  7];
else %AG at the front, preliminary (Marts 15)
   Kmin = [  6   0  0   0;... %minimum values for 'normal' K
           -25 -25 -9   0;...
           -10 -15 -16 -7];
   Kmax = [ 27  25  17  30;... %maximum values for 'normal' K
            -5  25  13  30;...
            10  15   8  7];
end
for i=1:3
    for j=1:4
     Ktable{i,j} = [num2str(K(i,j)),'  [',num2str(Kmin(i,j)),':',num2str(Kmax(i,j)),']'];   
    end
end
Chk = any(K<Kmin | K>Kmax);
if any(Chk)
   if Chk(1)
       subplot(H.thighgraf);
       text(0.5,0.5,{'Abnormal','reference','value'},'Unit','Normalized','HorizontalAlignment','center','Color',[1 0 1]);
   end
   if Chk(2)
      subplot(H.hipgraf)
       text(0.5,0.5,{'Abnormal','reference','value'},'Unit','Normalized','HorizontalAlignment','center','Color',[1 0 1]);
   end
   if Chk(3)
      subplot(H.armgraf)
       text(0.5,0.5,{'Abnormal','reference','value'},'Unit','Normalized','HorizontalAlignment','center','Color',[1 0 1]);
   end
   if Chk(4)
      subplot(H.trunkgraf)
       text(0.5,0.5,{'Abnormal','reference','value'},'Unit','Normalized','HorizontalAlignment','center','Color',[1 0 1]);
  end
end

function OpdaterZoom(hObject,~)
%This function is called by the 'zoom' and updates the 20min-grafs and start and end times of the reference interval
H = guidata(hObject);
datetick('x','HH:MM:SS','keeplimits')
NyX = xlim;
xtick = get(gca,'XTick');
xticklabel = get(gca,'XTickLabel');
set(H.thighgraf20,'xlim',NyX,'Xtick',xtick,'XTickLabel',xticklabel)
set(H.trunkgraf20,'xlim',NyX,'Xtick',xtick,'XTickLabel',xticklabel)

Tstart = datestr(NyX(1)+H.data.DateOffset,'HH:MM:SS');
Tslut = datestr(NyX(2)+H.data.DateOffset,'HH:MM:SS');
set(H.Start,'string',Tstart)
set(H.End,'string',Tslut)
H.data.Iref = find(NyX(1)<H.data.T & H.data.T<NyX(2));
set(H.Update,'Enable','On')
guidata(hObject, H); 


% --- Executes on button press in Update.
function Update_Callback(hObject, ~, H)
% Updates the 4 plot of reference angles, calculates the mean angles and check for 'normal' range 
% and display values in figure 'RefValues':
Iref = H.data.Iref;
V = H.data.V;
subplot(H.thighgraf);
  plot(V.Thigh(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Thigh (°)')
subplot(H.hipgraf);
  plot(V.Hip(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Hip (°)')
subplot(H.armgraf);
  plot(V.Arm(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Arm (°)')
subplot(H.trunkgraf);
  plot(V.Trunk(Iref,:))
  set(gca,'Xtick',[],'Xlim',[1,length(Iref)])
  title('Trunk (°)')

StartEnd = datestr(get(H.thighgraf20,'xlim')+H.data.DateOffset,'dd/mm/yyyy/HH:MM:SS');
set(H.RefStart,'string',StartEnd(1,1:end))
set(H.RefEnd,'string',StartEnd(2,1:end))
  
K = round([mean(V.Thigh(Iref,:))',mean(V.Hip(Iref,:))',mean(V.Arm(Iref,:))',mean(V.Trunk(Iref,:))']);
set(H.INC,'Data',K(1,:));
set(H.Uangle,'Data',K(2,:));
set(H.Vangle,'Data',K(3,:));

set(H.Save,'Enable','On')
set(H.Update,'Enable','Off')

Ktable = Check(K,H);
set(H.INC,'Data',Ktable(1,:));
set(H.Uangle,'Data',Ktable(2,:));
set(H.Vangle,'Data',Ktable(3,:));

hRefValues = findobj('Name','RefValues');
UpdateRefValues(findobj(hRefValues,'Tag','INCthigh'),K(1,1))
UpdateRefValues(findobj(hRefValues,'Tag','Uthigh'),K(2,1))
UpdateRefValues(findobj(hRefValues,'Tag','Vthigh'),K(3,1))
UpdateRefValues(findobj(hRefValues,'Tag','INChip'),K(1,2))
UpdateRefValues(findobj(hRefValues,'Tag','Uhip'),K(2,2))
UpdateRefValues(findobj(hRefValues,'Tag','Vhip'),K(3,2))
UpdateRefValues(findobj(hRefValues,'Tag','INCarm'),K(1,3))
UpdateRefValues(findobj(hRefValues,'Tag','Uarm'),K(2,3))
UpdateRefValues(findobj(hRefValues,'Tag','Varm'),K(3,3))
UpdateRefValues(findobj(hRefValues,'Tag','INCtrunk'),K(1,4))
UpdateRefValues(findobj(hRefValues,'Tag','Utrunk'),K(2,4))
UpdateRefValues(findobj(hRefValues,'Tag','Vtrunk'),K(3,4))

guidata(hObject, H); 

function UpdateRefValues(hCeller,NewVal)
  Celler = get(hCeller,'Data');
  Celler{end} = NewVal;
  set(hCeller,'Data',Celler);

% --- Executes on button press in Save.
function Save_Callback(~, ~, H)
% Saves the new reference interval to setup file (ID worksheet) 
Tstart = get(H.RefStart,'string');
Tslut = get(H.RefEnd,'string');
Res = {Tstart,Tslut};
Celle = XLSrange([1,2],[H.data.Irow,H.data.Icol]);
Excel = actxGetRunningServer('Excel.Application'); %Excel Setup file supposed to be open
Sheet = get(Excel.ActiveWorkBook.Sheets,'Item', H.data.ID);
invoke(Sheet, 'Activate')
hRange = get(Sheet,'Range',Celle, Celle);
set(hRange, 'Value', Res)
invoke(Excel.ActiveWorkBook,'Save')
set(H.Save,'Enable','Off')

% --- Outputs from this function are returned to the command line.
function varargout = Reference_OutputFcn(~, ~, H) 
varargout{1} = H.output;
close(H.Reference)

% --- Executes on button press in Next.
function Next_Callback(hObject, ~, H)
% Proceed to next interval in setup file 
if strcmp('on',get(H.Save,'Enable'))
   Ans = questdlg('Close without saving updated intervals?','Close?','Yes','No','No');   
   if strcmp('Yes',Ans)
       H.output = 'Next';
       guidata(hObject, H); 
       uiresume(H.Reference)
   end  
else
   H.output = 'Next';
   guidata(hObject, H); 
   uiresume(H.Reference)
end

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, H)
H.output = 'Cancel';
guidata(hObject, H); 
uiresume(H.Reference)


% --- Executes when user attempts to next Reference.
function Reference_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject);

% --- Executes during object creation, after setting all properties.
function RefStart_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function RefEnd_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
