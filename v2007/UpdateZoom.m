function UpdateZoom(~,~)
    %ActionPostCallback function for 'zoom' in plot with datetick x-axis and Tag = 'DateTick'.
    %Gets 'Xlim' of the current axis and updates other datetick axis in the same figure accordingly, 
    %writes min and max of axis in separat text fields. 
    
    Xakse=get(gca,'Xlim');
    h = findobj('Tag','DateTick');
    for i=1:length(h)
      set(h(i),'Xlim',Xakse)
      datetick(h(i),'x','keeplimits')
    end
    set(findobj('Tag','TimeLeft'),'String',datestr(Xakse(1),'HH:MM'))
    set(findobj('Tag','TimeRight'),'String',datestr(Xakse(2),'HH:MM'))
      
    %Rightside percent values are hided at Activity plot(not correct after zoom)
    set(findobj('Tag','Percent'),'Color',[.8 .8 .8])
     
    %Special if HR plot exists:
    ax1 = findobj(gcf,'Tag','HR');
    if ~isempty(ax1)
      set(ax1,'Xlim',Xakse)
      datetick(ax1,'x','keeplimits')
      Yax1 = get(ax1,'Ylim');
      ax2 = findobj('Tag','HRR%');
      UD = get(ax2,'UserData');      
      if ~isempty(ax2), set(ax2,'Ylim',100*[Yax1(1)-UD(1),Yax1(2)-UD(1)]/(UD(2)-UD(1))), end
    end
    
  