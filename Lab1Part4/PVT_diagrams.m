% Enter your Photon name%
name = 'PHOTON_NAME';

% Enter the unique access token for your Photon%
atoken = 'ACCESS_TOKEN';

% Enter the serial port for your Photon. If you have trouble finding the port or connecting to the serial, leave this blank.
port = 'PORT';

% Enter the input ports for your device.
presPin = 'A0';
tempPin = 'A1';

% Enter true if you are using a serial connection and false if you are using a cloud connection. If you having issues, just put false.
isUsingSerial = true;

%%

g = Photon(name, atoken, port);

if isUsingSerial
    g.disconnect;
end

% helpful var set
for i = 0:7
    msg = sprintf("D%0.0f = 'D%0.0f';", i,i);
    eval(msg);
end
for i = 0:7
    msg = sprintf("A%0.0f = 'A%0.0f';", i,i);
    eval(msg);
end

%% Collect data from the Photon

% Enter the Volumes you are measuring
volumes = (150:-20:90)'+30; % mL
samples = 3;  % number of voltage samples to average over at each volume

presVolt = zeros(size(volumes));  % array to store Pressure voltages
tempVolt = zeros(size(volumes));  % array to store Temperature voltages

% loop through each Volume measurement
for i = 1:length(volumes)
    fprintf('Move plunger to %3d mL, then press Enter\n',volumes(i))
    pause()
    
    % read Voltage samples from Photon pins
    voltagesIn = zeros(samples,2);
    for j = 1:samples
        voltagesIn(j,1) = g.analogRead(presPin);
        voltagesIn(j,2) = g.analogRead(tempPin);
    end
    % average the Voltage readings over the number of samples
    presVolt(i) = mean(voltagesIn(:,1));
    tempVolt(i) = mean(voltagesIn(:,2));
    
end

clear g

%% Convert the Voltage data to Pressure and Temperature measurements

pres = calcPres(presVolt);  % calculate Pressure (psi)
temp = calcTemp(tempVolt);  % calculate Temperature (K)
PVT = pres.*volumes./temp;  % calculate P*V/T (psi*mL/K)

%% Calculate the uncertainty

% uncertainty in each measurement
d_volm = 2.5;       % +/- 2.5 mL
d_pres = 0.02*pres; % 2% error 
d_temp = 1;         % +/- 1 C

% uncertainty in the derived quantity
err = PVT.*sqrt((d_pres./pres).^2+(d_volm./volumes).^2+(d_temp./temp).^2);

one = ones(size(PVT));

%% Plot your measurements

figure
set(gcf,'color','w')

% plot Pressure vs Volume
subplot(1,3,1), hold on
xlabel('Volume (mL)'), ylabel('Pressure (psi)'), xlim([50, 150])
errorbar(volumes,pres,d_pres.*one,d_pres.*one,d_volm.*one,d_volm.*one,...
    'bo','MarkerFaceColor','b','MarkerSize',6,'LineWidth',2)
set(gca,'FontSize',16,'LineWidth',2), hold off

% plot Temperature vs Volume
subplot(1,3,2), hold on
xlabel('Volume (mL)'), ylabel('Temperature (C)'), xlim([50, 150])
errorbar(volumes,temp-273.15,d_temp.*one,d_temp.*one,d_volm.*one,d_volm.*one,...
    'ro','MarkerFaceColor','r','MarkerSize',6,'LineWidth',2)
set(gca,'FontSize',16,'LineWidth',2), hold off

% plot PV/T vs Volume
subplot(1,3,3), hold on
xlabel('Volume (mL)'), ylabel('PV/T (psi * mL / K)'), xlim([50, 150])
errorbar(volumes,PVT,err,err,d_volm.*one,d_volm.*one,...
    'ko','MarkerFaceColor','k','MarkerSize',6,'LineWidth',2)
set(gca,'FontSize',16,'LineWidth',2), hold off

%% Functions for converting Photon Voltage to Pressure & Temperature
% You may need to edit some of the values in these functions!

%{
Inputs:
    presVolt = pressure sensor voltage from Photon (V)
Outputs:
    pres = pressure measurement (psi)
%}
function pres = calcPres(presVolt)

supplyVolt = 4.8; % Photon supply voltage (V)
Pmin = -15;       % minimum pressure (psi)
Pmax = 15;        % maximum pressure (psi)
presRef = 14.7;   % reference/atmospheric pressure (psi)

% pressure (psi)
pres = (presVolt/supplyVolt - 0.1) .* (Pmax-Pmin)/0.8 + Pmin + presRef;

end

%{
Inputs:
    tempVolt = thermistor voltage from Photon (V)
Outputs:
    temp = temperature measurement (K)
%}
function temp = calcTemp(tempVolt)

supplyVolt = 4.8;           % Photon supply voltage (V)
tempRefVolt = supplyVolt/2; % op-amp reference voltage (V)
gainResist = 4.6e3;         % op-amp gain resistance (Ohms)

% thermistor temperature coefficients
A = 3.35e-3;
B = 2.56e-4;
C = 2.14e-6;
D =-7.25e-8;

% un-amplified voltage difference between thermistor and reference
thermVolt = -tempVolt./(1 + 1e5/gainResist);
% Rt/R25 (Rt = thermistor resistance, R25 = 10kOhm)
resRatio = (supplyVolt-thermVolt-tempRefVolt)./(thermVolt+tempRefVolt);
% temperature (K)
temp = 1./(A + B*log(resRatio) + C*log(resRatio).^2 + D*log(resRatio).^3);

end
