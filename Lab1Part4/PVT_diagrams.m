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



%% Calculate the uncertainty



%% Plot your measurements

% Figure showing Pressure vs Volume

% Figure showing Temperature vs Volume

% Figure showing PV/T vs Volume

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
thermVolt = tempVolt./(1 + 1e5/gainResist);
% Rt/R25 (Rt = thermistor resistance, R25 = 10kOhm)
resRatio = (supplyVolt-thermVolt-tempRefVolt)./(thermVolt+tempRefVolt);
% temperature (K)
temp = 1./(A + B*log(resRatio) + C*log(resRatio).^2 + D*log(resRatio).^3);

end
