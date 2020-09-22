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

% Enter the Volumes you are measuring at as an array
volumes = (150:-40:70)'; % mL
samples = 5;  % number of voltage samples to average over at each volume

presVolt = zeros(size(volumes));  % array to store Pressure voltages
tempVolt = zeros(size(volumes));  % array to store Temperature voltages

% loop through each Volume measurement
for i = 1:length(volumes)
    fprintf('Move plunger to %3d mL\n',volumes(i))
    pause(2)
    
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
d_volm = 1;         % +/- 1 mL
d_pres = 0.1*pres;  % 10% error 
d_temp = 1;         % +/- 1 C
err = PVT.*sqrt((d_pres./pres).^2+(d_volm./volumes).^2+(d_temp./temp).^2);

%% Plot your measurements

% Figure showing Pressure vs Volume
% Figure showing Temperature vs Volume
lc = [0 0 1];  rc = [1 0 0];
figure
set(gcf,'color','w','defaultAxesColorOrder',[lc; rc])
hold on, xlabel('Volume (mL)')
yyaxis left
plot(volumes,pres,'bo','MarkerFaceColor','b','MarkerSize',6)
ylabel('Pressure (psi)')
set(gca,'FontSize',16,'LineWidth',2)
yyaxis right
plot(volumes,temp-273.15,'ro','MarkerFaceColor','r','MarkerSize',6)
ylabel('Temperature (C)')
set(gca,'FontSize',16,'LineWidth',2)

% Figure showing PV/T vs Volume
figure
set(gcf,'color','w')
hold on, xlabel('Volume (mL)')
errorbar(volumes,PVT,err,err,'ko','MarkerFaceColor','k','MarkerSize',6,'LineWidth',2)
ylabel('PV/T (psi * mL / K)')
set(gca,'FontSize',16,'LineWidth',2)

%% Functions for converting Photon Voltage to Pressure & Temperature
% You may need to edit some of the values in these functions!

%{
Inputs:
    presVolt = pressure sensor voltage from Photon (V)
Outputs:
    pres = pressure measurement (psi)
%}
function pres = calcPres(presVolt)

% parameters for the Photon
supplyVolt = 4.8;  % Photon supply voltage (V)

% parameters for the pressure sensor
presRange = 15;  % range of pressure sensor (psi)
presRef = 14.7;  % reference/atmospheric pressure (psi)

% pressure (psi)
pres = (presVolt - 0.1*supplyVolt) .* presRange./(0.8*supplyVolt) + presRef;

end

%{
Inputs:
    tempVolt = thermistor voltage from Photon (V)
Outputs:
    temp = temperature measurement (K)
%}
function temp = calcTemp(tempVolt)

% parameters for the Photon
supplyVolt = 4.8;  % Photon supply voltage (V)

% parameters for the operational amplifier
tempRefVolt = supplyVolt/2;  % op-amp reference voltage (V)
gainResist = 4.6e3;          % op-amp gain resistance (Ohms)

% parameters for the thermistor
A = 3.35e-3;
B = 2.56e-4;
C = 2.14e-6;
D =-7.25e-8;

thermVolt = tempVolt./(1 + 1e5/gainResist);
thermResRatio = supplyVolt./(thermVolt + tempRefVolt) - 1;

% temperature (K)
temp = 1./(A + B*log(thermResRatio) + C*log(thermResRatio).^2 + D*log(thermResRatio).^3);

end
