clc, clearvars

% Enter your Photon name%
name = 'MAE221-Photon-Dudt';

% Enter the unique access token for your Photon%
atoken = 'c429c624606fbae0992aebef1aad0eb2f1fc1d4b';

% Enter the serial port for your Photon. If you have trouble finding the port or connecting to the serial, leave this blank.
port = 'COM3';

% Enter the input ports for your device.
presPin = 'A0';
tempPin = 'A1';

% Enter true if you are using a serial connection and false if you are using a cloud connection. If you having issues, just put false.
isUsingSerial = true;

volm = (150:-40:70)'; % mL
samples = 5;

g = Photon(name, atoken, port);

if isUsingSerial
    g.disconnect;
end

%%

% helpful var set
for i = 0:7
    msg = sprintf("D%0.0f = 'D%0.0f';", i,i);
    eval(msg);
end
for i = 0:7
    msg = sprintf("A%0.0f = 'A%0.0f';", i,i);
    eval(msg);
end

%%

presVolt = zeros(size(volm));
tempVolt = zeros(size(volm));

for i = 1:length(volm)
    fprintf('Move plunger to %3d mL\n',volm(i))
    pause(1)
    
    voltagesIn = zeros(5,2);
    for j = 1:samples
        voltagesIn(j,1) = g.analogRead(presPin);
        voltagesIn(j,2) = g.analogRead(tempPin);
    end
    presVolt(i) = mean(voltagesIn(:,1));
    tempVolt(i) = mean(voltagesIn(:,2));
    
end

[pres,temp,PVT] = calcPVT(volm,presVolt,tempVolt);

% uncertainty in P*V/T (psi*mL/K)
dvolm = 1;
dpres = 0.1*pres;  % 10% error 
dtemp = 1;  % +/- 1 C
err = PVT.*sqrt((dpres./pres).^2 + (dvolm./volm).^2 + (dtemp./temp).^2);

clear g

%%

lc = [0 0 1];  rc = [1 0 0];
figure
set(gcf,'color','w','defaultAxesColorOrder',[lc; rc])
hold on, xlabel('Volume (mL)')
yyaxis left
plot(volm,pres,'bo','MarkerFaceColor','b','MarkerSize',6)
ylabel('Pressure (psi)')
set(gca,'FontSize',16,'LineWidth',2)
yyaxis right
plot(volm,temp-273.15,'ro','MarkerFaceColor','r','MarkerSize',6)
ylabel('Temperature (C)')
set(gca,'FontSize',16,'LineWidth',2)

figure
set(gcf,'color','w')
hold on, xlabel('Volume (mL)')
errorbar(volm,PVT,err,err,'ko','MarkerFaceColor','k','MarkerSize',6,'LineWidth',2)
ylabel('PV/T (psi * mL / K)')
set(gca,'FontSize',16,'LineWidth',2)

%%

function [pres,temp,PVT] = calcPVT(volm,presVolt,tempVolt)

% parameters for the Photon
supplyVolt = 4.8;  % Photon supply voltage (V)

% parameters for the pressure sensor
presRange = 15;  % range of pressure sensor (psi)
presRef = 14.7;  % reference/atmospheric pressure (psi)

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

% pressure (psi)
pres = (presVolt - 0.1*supplyVolt) .* presRange./(0.8*supplyVolt) + presRef;
% temperature (K)
temp = 1./(A + B*log(thermResRatio) + C*log(thermResRatio).^2 + D*log(thermResRatio).^3);

% P*V/T (psi*mL/K)
PVT = pres.*volm./temp;

end

%% Documentation

%{
    ASDX RR X 015PD AA5 pressure sensor
    http://www.farnell.com/datasheets/1765461.pdf
    
    RL0503-5820-97-MS
    https://www.digikey.com/product-detail/en/amphenol-advanced-sensors/RL0503-5820-97-MS/KC003T-ND/136365
%}
