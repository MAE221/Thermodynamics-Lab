% Enter your Photon name%
% clear all;
close all;
clc;
calibration = input('Is this the calibration measurement? Type 1 for yes and 0 for no: ');

name = 'PHOTON_NAME';

% Enter the unique access token for your Photon%
atoken = 'ACCESS_TOKEN';

% Enter the serial port for your Photon. If you have trouble finding the port or connecting to the serial, leave this blank.
port = 'COM5';

% Enter the input ports for your device.
tempPin = 'A1';

% Enter true if you are using a serial connection and false if you are using a cloud connection. If you having issues, just put false.
isUsingSerial = true;

g = Photon(name, atoken, port);

if isUsingSerial
    g.disconnect;
end
%%

% helpful var set
for i = 0:7
    msg = sprintf("A%0.0f = 'A%0.0f';", i,i);
    eval(msg);
end

%% LOOP Collect data from the Photon

% Enter the Volumes you are measuring
volumes = 342; % units in [mL]
samples = 3;  % number of voltage samples to average over at each volume

tempVolt = zeros(size(volumes));  % array to store Temperature voltages

i = 1;
index = 1;
% loop through each Volume measurement
fig = figure;
while index == 1 
    
    % read Voltage samples from Photon pins
        voltagesIn = zeros(samples,1);
        for j = 1:samples
            voltagesIn(j,1) = g.analogRead(tempPin);
        end
        
    % average the Voltage readings over the number of samples
    if i > 1000
        i = 1000;
        tempVolt = circshift(tempVolt,[1,-1]);
        temp = circshift(temp,[1,-1]);
        tempC = circshift(temp,[1,-1]);
        
        tempVolt(i) = mean(voltagesIn(:,1));
        temp(i) = calcTemp(tempVolt(i));
        tempC(i) = temp(i)-273; %[C]
    else
        tempVolt(i) = mean(voltagesIn(:,1));
        temp(i) = calcTemp(tempVolt(i));
        tempC(i) = temp(i)-273; %[C]
        i = i + 1;
    end
    
    index = ishandle(fig);
    plot(tempC,'k');
    ylabel('Temperature [C]')
    ylim([20 30])
    grid on
    pause(0.1)
end

clear g

%% Calibration of the heat Capacity/Calculating heat of combustion
% Use this section to determine the heat capacity of the bomb calorimeter
if calibration == 1
    q_benzoic = 6318; %cal/g
    q_wire = 2.3; %cal/cm
    m_F = input('Input the mass of the benzoic acid in grams: '); % mass of fuel in grams
    lwire = input('Input the length of the burned wire in centimeters: '); % burned length of the wire
    DeltaT = max(temp) - mean(temp(1:10)); %total temperature change

    C = (q_benzoic.*m_F + lwire.*q_wire)./DeltaT % heat capacity of the bomb calorimeter [cal/K]
elseif calibration == 0
    %Use C from the calibration section
    q_wire = 2.3; %cal/cm
    m_F = input('Input the mass of the fuel in grams: '); % mass of fuel in grams
    lwire = input('Input the length of the burned wire in centimeters: '); % burned length of the wire
    DeltaT = max(temp) - mean(temp(1:10)); %total temperature change
    
    q = (DeltaT.*C - lwire.*q_wire)./m_F % heat of combustion of the fuel in [cal/g]  
else
    disp('Please change the value of "calibration" to either 0 or 1')
end
%% Calculate the uncertainty in the heat capacity
if calibration == 1
%     uncertainty in each measurement
    d_temp = sqrt(0.5);         % comes from DeltaT = Tf - Ti where Tf and Ti have an error of +/-0.5C
    d_lwire = 0.05;         %error of from the ruler in cm
    d_mF = 5e-4;    %uncertainty of the mass measurement from the device in grams
    d_C = sqrt(((q_benzoic/DeltaT).*d_mF).^2 + ((q_wire/DeltaT).*d_lwire).^2 + (((q_benzoic.*m_F + lwire.*q_wire)/(DeltaT.^2)).*d_temp).^2); % calculating error
end
%% Calculate the uncertainty in the heat of combustion
if calibration == 0
    uncertainty in each measurement
    d_temp = sqrt(0.5);         % comes from DeltaT = Tf - Ti where Tf and Ti have an error of +/-0.5C
    d_lwire = 0.05;         %error of from the ruler in cm
    d_mF = 5e-4;    %uncertainty of the mass measurement from the device in grams

 %   d_C ; % from calibration uncertainty

    err = sqrt(((C/m_F).*d_temp).^2 + ((DeltaT/m_F).*d_C).^2 + ((q_wire/m_F).*d_lwire).^2 + (((lwire.*q_wire - DeltaT.*C)/(m_F.^2)).*d_mF).^2); % calculating error in heat of combustion
end
%% Functions for converting Photon Voltage to Pressure & Temperature
% You may need to edit some of the values in these functions!
%{
Inputs:
    tempVolt = thermistor voltage from Photon (V)
Outputs:
    temp = temperature measurement (K)
%}
function temp = calcTemp(tempVolt)

supplyVolt = 4.81;           % Photon supply voltage (V)
tempRefVolt = supplyVolt/2; % op-amp reference voltage (V)
thermVolt = tempVolt;


% thermistor temperature coefficients
A = 3.35e-3;
B = 2.56e-4;
C = 2.38e-6;
D = 8.37e-8;

% Rt/R25 (Rt = thermistor resistance, R25 = 10kOhm)
resRatio = (supplyVolt-thermVolt)./(thermVolt);
% temperature (K)
temp = 1./(A + B*log(resRatio) + C*log(resRatio).^2 + D*log(resRatio).^3);

end