clc;
clear;
%close all;

%\\\\\\\\\\\\\\\\\\\\\\\ Virtual Dyno V1 //////////////////////////
%                     Pedro Paganini De Mio

% inputs

motor_model = 'TorqueBoards 6355 190 Kv';
Kv = 190; %[rpm/V]
current = 2 * 60; %[A]
Kt = 9.55 / Kv; % [N*m/A]
pole_pairs = 7;
phase_resistance = 0.0177; %[ ohms]

erpm_meassured = [ 18220 42830 ]; % [erpm]
rpm_meassured = erpm_meassured / pole_pairs; % [rpm]
current_meassured = [ 0.29 0.48 ]; % [A]


voltage = 84; % [V] 
peak_rpm = voltage * Kv; % [rpm]
peak_torque = current * Kt; % [N*m]
peak_dutycycle = 0.95; % [%]

Km = Kt/sqrt(1.5*phase_resistance);


rpm_vector = linspace( 0 , peak_rpm , peak_rpm / 10 ); % [rpm]
torque_vector = linspace( 0 , peak_torque , peak_torque * 100)'; % [N*m]
core_loses_cte = polyfit( rpm_meassured , current_meassured , 1 ); % [N*m N*m/rpm]

core_loss_torque_vector = core_loses_cte(2) + core_loses_cte(1) * rpm_vector; % [N*m]
core_loss_power_vector = core_loss_torque_vector .* rpm_vector / (60 * 2 * pi );

core_loss_power_matrix = zeros(length(torque_vector),length(rpm_vector));

for i = 1:length(torque_vector)
    core_loss_power_matrix(i,:) = core_loss_power_vector;
end

total_torque_matrix = zeros(length(torque_vector),length(rpm_vector));

for i = 1:length(torque_vector)
    for k = 1:length(rpm_vector)
        total_torque_matrix(i,k) = torque_vector(i) + core_loss_torque_vector(k);
    end
end

motor_current_matrix = total_torque_matrix ./ Kt;

output_power_matrix = torque_vector * rpm_vector * 2 * pi / 60;

copper_loss_power_matrix = zeros(length(torque_vector),length(rpm_vector));

for i = 1:length(torque_vector)
    for k = 1:length(rpm_vector)
        copper_loss_power_matrix(i,k) = 1.5 * phase_resistance * (motor_current_matrix(i,k))^2;
    end
end

total_loss_power_matrix = core_loss_power_matrix + copper_loss_power_matrix;

total_power_matrix = total_loss_power_matrix + output_power_matrix;

motor_efficiency_matrix = 100 * output_power_matrix ./ total_power_matrix;

required_voltage_matrix = zeros(length(torque_vector),length(rpm_vector));

for i = 1:length(torque_vector)
    for k = 1:length(rpm_vector)
        required_voltage_matrix(i,k) = (rpm_vector(k) / Kv + phase_resistance * motor_current_matrix(i,k))/peak_dutycycle;
    end
end



%??????????????????????????????????????????????????????????????????



figure(1)
set(gcf,'color','white')
set(gcf, 'Position', get(0, 'Screensize'));
[C,h] = contourf(rpm_vector,torque_vector,motor_efficiency_matrix, [ 0 50 55 60 65 70 75 80 82 84 86 88 90 92 94 95 96 98 100 ]);
colormap jet
clabel(C,h)
h.LevelList=round(h.LevelList,0);
clabel(C,h,'LabelSpacing',300)
c = colorbar;
c.Label.String = 'Efficiency [%]';
set(c,'FontSize',14);

ax = gca;
xticks(0:1000:max(rpm_vector(:)));
ax.FontSize = 12; 
yticks(0:0.5:max(torque_vector(:)));
ay.FontSize = 12; 

title(['Efficiency Map - ' motor_model],'FontSize',18)
xlabel('Speed [rpm]','FontSize',14)
ylabel('Torque [N m]','FontSize',14)
hold on

caxis([0 100])

voltages = [ 22 , 37 , 44 , 52 , 60 , 67 , 74 ];
[C2,h2] = contour(rpm_vector,torque_vector,required_voltage_matrix,voltages,'-');
h2.LevelList=round(h2.LevelList,0);
clabel(C2,h2,'LabelSpacing',1000,'FontSize',26,'Color','w')
h2.LineWidth = 1.5;
h2.LineColor = 'w';
drawnow
labels = h2.TextPrims;
for k = 1 : numel(labels)
    LabelValue = str2num(labels(k).String);
    h2.TextPrims(k).String = [num2str(LabelValue) ' [v]'];
    labels(k).Font.Size = 14; 
end

hold on

currents = current * [ 0.25 , 0.5 , 0.75 , 1 ];
[C3,h3] = contour(rpm_vector,torque_vector,motor_current_matrix,currents,'--');
h3.LevelList=round(h3.LevelList,0);
clabel(C3,h3,'LabelSpacing',300,'FontSize',26,'Color','w')
h3.LineWidth = 1.5;
h3.LineColor = 'w';
drawnow
labels2 = h3.TextPrims;
for k = 1 : numel(labels2)
    LabelValue = str2num(labels2(k).String);
    h3.TextPrims(k).String = [num2str(LabelValue) ' [A]'];
    labels2(k).Font.Size = 14; 
end
%caxis([0 100])

%///////////////////////////////////////////////////////////

figure(2)
set(gcf,'color','white')
set(gcf, 'Position', get(0, 'Screensize'));
[C3,h3] = contourf(rpm_vector,torque_vector,total_loss_power_matrix);
colormap jet
clabel(C3,h3)
h3.LevelList=round(h3.LevelList,0);
clabel(C3,h3,'LabelSpacing',300)
c = colorbar;
c.Label.String = 'Losses [W]';
set(c,'FontSize',14);

ax = gca;
xticks(0:1000:max(rpm_vector(:)));
ax.FontSize = 12; 
yticks(0:0.5:max(torque_vector(:)));
ay.FontSize = 12; 

title(['Total Losses - ' motor_model],'FontSize',18)
xlabel('Speed [rpm]','FontSize',14)
ylabel('Torque [N m]','FontSize',14)
hold on

voltages = [ 22 , 37 , 44 , 52 , 60 , 67 , 74 ];
[C4,h4] = contour(rpm_vector,torque_vector,required_voltage_matrix,voltages,'-');
h4.LevelList=round(h4.LevelList,0);
clabel(C4,h4,'LabelSpacing',1000,'FontSize',26,'Color','w')
h4.LineWidth = 1.5;
h4.LineColor = 'w';
drawnow
labels4 = h4.TextPrims;
for k = 1 : numel(labels4)
    LabelValue = str2num(labels4(k).String);
    h4.TextPrims(k).String = [num2str(LabelValue) ' [v]'];
    labels4(k).Font.Size = 14; 
end

hold on

currents = current * [ 0.25 , 0.5 , 0.75 , 1 ];
[C5,h5] = contour(rpm_vector,torque_vector,motor_current_matrix,currents,'--');
h5.LevelList=round(h5.LevelList,0);
clabel(C3,h5,'LabelSpacing',300,'FontSize',26,'Color','w')
h5.LineWidth = 1.5;
h5.LineColor = 'w';
drawnow
labels5 = h5.TextPrims;
for k = 1 : numel(labels5)
    LabelValue = str2num(labels5(k).String);
    h5.TextPrims(k).String = [num2str(LabelValue) ' [A]'];
    labels5(k).Font.Size = 14; 
end


%///////////////////////////////////////////////////////////

figure(3)
set(gcf,'color','white')
set(gcf, 'Position', get(0, 'Screensize'));
[C,h] = contourf(rpm_vector,torque_vector,copper_loss_power_matrix);
colormap jet
clabel(C,h)
h.LevelList=round(h.LevelList,0);
clabel(C,h,'LabelSpacing',300)
c = colorbar;
c.Label.String = 'Copper Losses [W]';
set(c,'FontSize',14);

ax = gca;
xticks(0:1000:max(rpm_vector(:)));
ax.FontSize = 12; 
yticks(0:0.5:max(torque_vector(:)));
ay.FontSize = 12; 

title(['Copper Losses - ' motor_model],'FontSize',18)
xlabel('Speed [rpm]','FontSize',14)
ylabel('Torque [N m]','FontSize',14)
hold on

voltages = [ 22 , 37 , 44 , 52 , 60 , 67 , 74 ];
[C2,h2] = contour(rpm_vector,torque_vector,required_voltage_matrix,voltages,'-');
h2.LevelList=round(h2.LevelList,0);
clabel(C2,h2,'LabelSpacing',1000,'FontSize',26,'Color','w')
h2.LineWidth = 1.5;
h2.LineColor = 'w';
drawnow
labels = h2.TextPrims;
for k = 1 : numel(labels)
    LabelValue = str2num(labels(k).String);
    h2.TextPrims(k).String = [num2str(LabelValue) ' [v]'];
    labels(k).Font.Size = 14; 
end

hold on

currents = current * [ 0.25 , 0.5 , 0.75 , 1 ];
[C3,h3] = contour(rpm_vector,torque_vector,motor_current_matrix,currents,'--');
h3.LevelList=round(h3.LevelList,0);
clabel(C3,h3,'LabelSpacing',300,'FontSize',26,'Color','w')
h3.LineWidth = 1.5;
h3.LineColor = 'w';
drawnow
labels2 = h3.TextPrims;
for k = 1 : numel(labels2)
    LabelValue = str2num(labels2(k).String);
    h3.TextPrims(k).String = [num2str(LabelValue) ' [A]'];
    labels2(k).Font.Size = 14; 
end


%///////////////////////////////////////////////////////////

figure(4)
set(gcf,'color','white')
set(gcf, 'Position', get(0, 'Screensize'));
[C,h] = contourf(rpm_vector,torque_vector,core_loss_power_matrix);
colormap jet
clabel(C,h)
h.LevelList=round(h.LevelList,0);
clabel(C,h,'LabelSpacing',300)
c = colorbar;
c.Label.String = 'Core Losses [W]';
set(c,'FontSize',14);

ax = gca;
xticks(0:1000:max(rpm_vector(:)));
ax.FontSize = 12; 
yticks(0:0.5:max(torque_vector(:)));
ay.FontSize = 12; 

title(['Core Losses - ' motor_model],'FontSize',18)
xlabel('Speed [rpm]','FontSize',14)
ylabel('Torque [N m]','FontSize',14)
hold on

voltages = [ 22 , 37 , 44 , 52 , 60 , 67 , 74 ];
[C2,h2] = contour(rpm_vector,torque_vector,required_voltage_matrix,voltages,'-');
h2.LevelList=round(h2.LevelList,0);
clabel(C2,h2,'LabelSpacing',1000,'FontSize',26,'Color','w')
h2.LineWidth = 1.5;
h2.LineColor = 'w';
drawnow
labels = h2.TextPrims;
for k = 1 : numel(labels)
    LabelValue = str2num(labels(k).String);
    h2.TextPrims(k).String = [num2str(LabelValue) ' [v]'];
    labels(k).Font.Size = 14; 
end

hold on

currents = current * [ 0.25 , 0.5 , 0.75 , 1 ];
[C3,h3] = contour(rpm_vector,torque_vector,motor_current_matrix,currents,'--');
h3.LevelList=round(h3.LevelList,0);
clabel(C3,h3,'LabelSpacing',300,'FontSize',26,'Color','w')
h3.LineWidth = 1.5;
h3.LineColor = 'w';
drawnow
labels3 = h3.TextPrims;
for k = 1 : numel(labels3)
    LabelValue = str2num(labels3(k).String);
    h3.TextPrims(k).String = [num2str(LabelValue) ' [A]'];
    labels3(k).Font.Size = 14; 
end
caxis([0 max(core_loss_power_matrix(:))])

%??????????????????????????????????????????????????????????????????



figure(5)
set(gcf,'color','white')
set(gcf, 'Position', get(0, 'Screensize'));
[C,h] = contourf(rpm_vector,torque_vector,output_power_matrix,20);
colormap jet
clabel(C,h)
h.LevelList=round(h.LevelList,0);
clabel(C,h,'LabelSpacing',300)
c = colorbar;
c.Label.String = 'Output Power [W]';
set(c,'FontSize',14);

ax = gca;
xticks(0:1000:max(rpm_vector(:)));
ax.FontSize = 12; 
yticks(0:0.5:max(torque_vector(:)));
ay.FontSize = 12; 

title(['Output Power - ' motor_model],'FontSize',18)
xlabel('Speed [rpm]','FontSize',14)
ylabel('Torque [N m]','FontSize',14)
hold on

voltages = [ 22 , 37 , 44 , 52 , 60 , 67 , 74 ];
[C7,h7] = contour(rpm_vector,torque_vector,required_voltage_matrix,voltages,'-');
h7.LevelList=round(h7.LevelList,0);
clabel(C7,h7,'LabelSpacing',1000,'FontSize',26,'Color','w')
h7.LineWidth = 1.5;
h7.LineColor = 'w';
drawnow
labels = h7.TextPrims;
for k = 1 : numel(labels)
    LabelValue = str2num(labels(k).String);
    h7.TextPrims(k).String = [num2str(LabelValue) ' [v]'];
    labels(k).Font.Size = 14; 
end

hold on

currents = current * [ 0.25 , 0.5 , 0.75 , 1 ];
[C3,h3] = contour(rpm_vector,torque_vector,motor_current_matrix,currents,'--');
h3.LevelList=round(h3.LevelList,0);
clabel(C3,h3,'LabelSpacing',300,'FontSize',26,'Color','w')
h3.LineWidth = 1.5;
h3.LineColor = 'w';
drawnow
labels2 = h3.TextPrims;
for k = 1 : numel(labels2)
    LabelValue = str2num(labels2(k).String);
    h3.TextPrims(k).String = [num2str(LabelValue) ' [A]'];
    labels2(k).Font.Size = 14; 
end

