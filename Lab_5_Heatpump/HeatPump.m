% Enter your Photon name%
% clear all;
close all;
clc;

name = 'PHOTON_NAME';

% Enter the unique access token for your Photon%
atoken = 'ACCESS_TOKEN';

% Enter the serial port for your Photon. If you have trouble finding the port or connecting to the serial, leave this blank.
port = 'COM8';

% Enter the input ports for your device.
T1pin = 'A0';
T2pin = 'A1';
T3pin = 'A2';
T4pin = 'A7';

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

%% TEST LOOP Collect data from the Photon


tempVolt = zeros(1,4);  % array to store Temperature voltages

i = 1;
index = 1;

samples=3;

fig = figure;
while index == 1 
        
    % average the Voltage readings over the number of samples
    if i > 1000
        i = 1000;
        tempVolt = circshift(tempVolt,[1,-1]);
        temp = circshift(temp,[1,-1]);
        tempC = circshift(temp,[1,-1]);
        
        tempVolt(i,1) = g.analogRead(T1pin);
        tempVolt(i,2) = g.analogRead(T2pin);
        tempVolt(i,3) = g.analogRead(T3pin);
        tempVolt(i,4) = g.analogRead(T4pin);
        temp(i,1) = calcTemp(tempVolt(i,1));
        temp(i,2) = calcTemp(tempVolt(i,2));
        temp(i,3) = calcTemp(tempVolt(i,3));
        temp(i,4) = calcTemp(tempVolt(i,4));
        tempC(i,1) = temp(i,1)-273; %[C]
        tempC(i,2) = temp(i,2)-273; %[C]
        tempC(i,3) = temp(i,3)-273; %[C]
        tempC(i,4) = temp(i,4)-273; %[C]
    else
        tempVolt(i,1) = g.analogRead(T1pin);
        tempVolt(i,2) = g.analogRead(T2pin);
        tempVolt(i,3) = g.analogRead(T3pin);
        tempVolt(i,4) = g.analogRead(T4pin);
        temp(i,1) = calcTemp(tempVolt(i,1));
        temp(i,2) = calcTemp(tempVolt(i,2));
        temp(i,3) = calcTemp(tempVolt(i,3));
        temp(i,4) = calcTemp(tempVolt(i,4));
        tempC(i,1) = temp(i,1)-273; %[C]
        tempC(i,2) = temp(i,2)-273; %[C]
        tempC(i,3) = temp(i,3)-273; %[C]
        tempC(i,4) = temp(i,4)-273; %[C]
        i = i + 1;
    end
    
    index = ishandle(fig);
    plot(tempC(:,1),'r');
    hold on;
    plot(tempC(:,2),'g');
    plot(tempC(:,3),'b');
    plot(tempC(:,4),'k');
    ylabel('Temperature [C]')
    legend({'T1', 'T2', 'T3', 'T4'}, 'Orientation', 'horizontal')
    ylim([-40, 100])
    grid on
    pause(0.1)
end

P1 = input('Enter the pressure after the evaporator in psi: ');
P2 = input('Enter the pressure before the condenser in psi: ');
mdot = input('Enter the mass flow rate in kg/hr: ');
Power = input('Enter the electrical power in W: ');
P1 = P1.*0.00689476 + 0.101; % in MPa
P2 = P2.*0.00689476 + 0.101; % in MPa

fprintf('T1: %1.1f C\n', tempC(i-1,1));
fprintf('T2: %1.1f C\n', tempC(i-1,2));
fprintf('T3: %1.1f C\n', tempC(i-1,3));
fprintf('T4: %1.1f C\n', tempC(i-1,4));
fprintf('P1: %1.3f MPa\n', P1);
fprintf('P2: %1.3f MPa\n', P2);

clear g



%% Function for converting Photon Voltage to Temperature
%{
Inputs:
    tempVolt = thermistor voltage from Photon (V)
Outputs:
    temp = temperature measurement (K)
%}
function temp = calcTemp(tempVolt)

supplyVolt = 5; % Supply voltage (V)

% thermistor temperature coefficients
A = 3.35e-3;
B = 2.56e-4;
C = 2.38e-6;

D = 8.37e-8;

% Rt/R25 (Rt = thermistor resistance, R25 = 10kOhm)
resRatio = (tempVolt)./(supplyVolt-tempVolt);
% temperature (K)
temp = 1./(A + B*log(resRatio) + C*log(resRatio).^2 + D*log(resRatio).^3);

end
