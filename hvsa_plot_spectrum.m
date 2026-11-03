function hvsa_plot_spectrum(ax,result)
%HVSA_PLOT_SPECTRUM Visual QA view with explicit peak/criterion annotations.
%   Independently written plotting layer for HV-SESAME Analyzer. Marker
%   shapes as well as colors differentiate the three project-level classes.

if ~isgraphics(ax,'axes')
    error('HVSA:InvalidAxes','A valid MATLAB axes handle is required.');
end
% A plain cla(ax) does not delete graphics whose HandleVisibility is 'off'.
% In this plot, criterion guide lines and station markers use hidden handles
% to keep the legend clean. Without allchild, these annotations persist when
% navigating between stations and incorrectly look like extra HVSR peaks.
% Delete *all* axes children while retaining axes placement/format settings.
delete(allchild(ax));
hold(ax,'off');
f = result.tab(:,1);
a = result.tab(:,2);
lo = result.tab(:,3);
hi = result.tab(:,4);
peak = result.f0;
amp = result.A0;
colors = struct('mean',[0.12 0.24 0.34],'bounds',[0.45 0.51 0.60], ...
                'guide',[0.41 0.53 0.71],'pass',[0.08 0.53 0.28], ...
                'warn',[0.80 0.49 0.05],'fail',[0.73 0.19 0.22]);

if result.criteria.allPass
    status = 'ACCEPTED'; color = colors.pass; symbol = '^';
elseif result.criteria.controlled
    status = 'CONTROLLED ACCEPTANCE'; color = colors.warn; symbol = 's';
else
    status = 'REJECTED'; color = colors.fail; symbol = 'd';
end

hold(ax,'on');
plot(ax,f,lo,'--','Color',colors.bounds,'LineWidth',0.9,'DisplayName','Mean - 1 SD');
plot(ax,f,hi,'--','Color',colors.bounds,'LineWidth',0.9,'DisplayName','Mean + 1 SD');
plot(ax,f,a,'-','Color',colors.mean,'LineWidth',1.8,'DisplayName','Mean H/V');

vline(ax,peak,'-',colors.fail,1.2);
vline(ax,0.95*peak,':',colors.guide,0.9);
vline(ax,1.05*peak,':',colors.guide,0.9);
vline(ax,peak/4,':',[0.18 0.48 0.38],0.8);
vline(ax,4*peak,':',[0.18 0.48 0.38],0.8);
plot(ax,[max(min(f),peak/4),min(max(f),4*peak)],[amp/2 amp/2],':', ...
     'Color',colors.fail,'LineWidth',1.1,'HandleVisibility','off');

idx = find(abs(f-peak)==min(abs(f-peak)),1,'first');
plot(ax,f(idx),a(idx),symbol,'Color',color, ...
    'MarkerFaceColor',color,'MarkerSize',9,'HandleVisibility','off');

set(ax,'XScale','log','Color','white','XColor',[0.12 0.18 0.25], ...
    'YColor',[0.12 0.18 0.25]);
xlim(ax,[min(f) max(f)]);
ylim(ax,[0,max(hi)*1.38]);
grid(ax,'on'); box(ax,'on');
xlabel(ax,'Frequency (Hz)'); ylabel(ax,'H/V amplitude');

names = arrayfun(@(k)sprintf('V%d',k),1:9,'UniformOutput',false);
pass = cellfun(@(name)result.criteria.(name),names);
for k = 1:9
    if pass(k)
        thisColor = colors.pass; mark = 'PASS';
    else
        thisColor = colors.fail; mark = 'FAIL';
    end
    text(ax,0.02,0.71-0.068*(k-1),sprintf('V%d: %s',k,mark), ...
        'Units','normalized','FontSize',13.5,'Color',thisColor, ...
        'FontWeight','bold','Interpreter','none');
end
text(ax,0.02,0.97,sprintf('%s  |  f0 = %.4f Hz',status,peak), ...
    'Units','normalized','VerticalAlignment','top', ...
    'Color',color,'FontWeight','bold','FontSize',16,'Interpreter','none');
text(ax,0.02,0.89,sprintf('Reliability: %s  |  Clear Peak: %s', ...
    verdict(result.criteria.reliable),verdict(result.criteria.clear)), ...
    'Units','normalized','Color',[0.14 0.18 0.23], ...
    'FontWeight','bold','FontSize',13.5,'Interpreter','none');

hold(ax,'off');
end

function vline(ax,x,style,color,width)
if x>0
    plot(ax,[x x],ylimSafe(ax),style,'Color',color, ...
        'LineWidth',width,'HandleVisibility','off');
end
end

function vals = ylimSafe(ax)
vals = ylim(ax);
if ~isfinite(vals(1)) || ~isfinite(vals(2)) || vals(1)==vals(2)
    vals = [0 1];
end
end

function str = verdict(flag)
if flag
    str = 'PASS';
else
    str = 'FAIL';
end
end
