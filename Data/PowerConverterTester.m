clearvars;clc;

% Input Voltages
voltageInputArray = [11,12:2:26];
currentOutputArray = [0:2:8];
powerOutputArray = 5.* currentOutputArray;

% Power Supply Setup (N6700/N6791a/????)
powerSupplyIP = 4; PSU = connectPowerSupply(powerSupplyIP); fprintf(PSU, '*RST');
inputSlot = 1; loadSlot = 2;

% Oscilloscope Setup (TDS7104)
scopeIP = 5; scope = connectPowerSupply(scopeIP); fprintf(scope, '*RST');
fprintf(scope, 'ACQuire:MODe SAMple');
fprintf(scope, 'CH1:COUP DC');
scopeVScale = 3; % max output volts/4
fprintf(scope, 'CH1:SCALE %i',scopeVScale);
fprintf(scope, 'HORizontal:RECOrdlength 250000'); % 250,000 Pts
fprintf(scope, 'HORizontal:SCAle 1.000E-3'); % 1ms scale

fprintf(scope, 'DATa:DESTINATION REF1;ENCdg ASCIi');
fprintf(scope, 'DATa:SOUrce CH1;START 1;STOP 250000;FRAMESTART 1;FRAMESTOP 250000');
fprintf(scope, 'ACQuire:STOPAfter SEQuence');
fprintf(scope, 'TRIGGER:A:MODE NORM;TYPE EDGE;LEVEL 3.0000');
fprintf(scope, 'TRIGGER:A:EDGE:SOURCE CH1;COUPLING DC;SLOPE RISE');
fprintf(scope, 'TRIGGER:A:HOLDOFF:BY AUTO;TIME 250.0000E-9');

serialObj = initINA("COM4");

efficiency = zeros(length(voltageInputArray),length(currentOutputArray));
inputCurrent = zeros(length(voltageInputArray),length(currentOutputArray));
inputVoltage = zeros(length(voltageInputArray),length(currentOutputArray));
outputCurrent = zeros(length(voltageInputArray),length(currentOutputArray));
outputVoltage = zeros(length(voltageInputArray),length(currentOutputArray));
trace = zeros(length(voltageInputArray),length(currentOutputArray),250000);
dataINA = cell(length(voltageInputArray),length(currentOutputArray));

fprintf(PSU, sprintf('FUNC POW,(@%i)', loadSlot));

for vin = 1:length(voltageInputArray)

    fprintf(PSU, sprintf('VOLT %i,(@%i)', voltageInputArray(vin), inputSlot));
    % fprintf(PSU, sprintf('VOLT:PROT:LEV %i,(@%i))', voltageInputArray(vin)+2, inputSlot));
    fprintf(PSU, sprintf('CURR 5,(@%i)', inputSlot));
    fprintf(PSU, sprintf('CURR:PROT:STAT ON,(@%i)', inputSlot));
    fprintf(PSU, '*WAI');

    for pout = 1:length(powerOutputArray)
        % Set Load
        
        % if powerOutputArray(pout) % don't enable load if testing qui case
        fprintf(PSU, sprintf('POW %i,(@%i)', powerOutputArray(pout), loadSlot));
            
        % end
        fprintf(PSU, '*WAI');

        % Start O-scope Recording
        fprintf(scope, 'ACQuire:STATE 1'); % Set scope to single acq
        pause(1);

        % Set Power Supply
        fprintf(PSU, sprintf('OUTP ON,(@%i)', inputSlot));
        pause(0.1);
        fprintf(PSU, sprintf('OUTP ON,(@%i)', loadSlot));
        fprintf(PSU, '*WAI');
        pause(5); % Wait 5 seconds for steady state

        % Stop O-scope Recording
        fprintf(scope, 'CURVe?');
        trace(vin,pout,:) = str2double(strsplit(fgetl(scope),','))./(100/scopeVScale*4);

        % Read Voltages/Currents from Power Supply
        fprintf(PSU, '*WAI;MEAS:VOLT:MAX? (@%i)', inputSlot);
        inputVoltage(vin, pout) = str2double(strsplit(fgetl(PSU),','));

        fprintf(PSU, '*WAI;MEAS:CURR:MAX? (@%i)', inputSlot);
        inputCurrent(vin, pout) = str2double(strsplit(fgetl(PSU),','));

        fprintf(PSU, '*WAI;MEAS:VOLT:MAX? (@%i)', loadSlot);
        outputVoltage(vin, pout) = str2double(strsplit(fgetl(PSU),','));

        fprintf(PSU, '*WAI;MEAS:CURR:MAX? (@%i)', loadSlot);
        outputCurrent(vin, pout) = str2double(strsplit(fgetl(PSU),','));

        efficiency(vin, pout) = (outputCurrent(vin, pout)*outputVoltage(vin, pout))/(inputCurrent(vin, pout)*inputVoltage(vin, pout));

        % Read Voltages/Currents from INA219s
        dataINA(vin, pout) = {readINA(serialObj)}; % INA data is [voltage, current, power]

        % Turn Off Power Supply
        fprintf(PSU, 'OUTP OFF,(@%i)', inputSlot);
        fprintf(PSU, '*WAI');
        pause(1); % Wait for output caps to drain
        fprintf(PSU, 'OUTP OFF,(@%i)', loadSlot);
        fprintf(PSU, '*WAI');
        pause(5);

    end
end

% Efficiency plot
fig = figure; hold on; plot(currentOutputArray,efficiency.*100); grid on; fig.CurrentAxes.LineStyleOrder = ["-square" "--square" "-.square"];
xlabel('Output Current (A)'); ylabel('Efficiency (%)'); title('Efficiency vs Output Current')
legend(horzcat(num2str(voltageInputArray'),repmat(['V'],length(voltageInputArray),1)),'Location','best')
hold off;

% Actual Voltage Plot
fig = figure; hold on; plot(currentOutputArray,mean(trace(:,:,end-50000:end),3)); grid on; fig.CurrentAxes.LineStyleOrder = ["-square" "--square" "-.square"];
xlabel('Output Current (A)'); ylabel('Output Voltage (V)'); title('Real Output Voltage vs Output Current')
legend(horzcat(num2str(voltageInputArray'),repmat(['V'],length(voltageInputArray),1)),'Location','best')
hold off;

% Max Transient Voltage Plot
maxVoltage = max(trace,[],3);
fig = figure; hold on; plot(currentOutputArray,maxVoltage); grid on; fig.CurrentAxes.LineStyleOrder = ["-square" "--square" "-.square"];
xlabel('Output Current (A)'); ylabel('Max Transient Voltage (V)'); title('Maximum Transient Voltage vs Output Current')
legend(horzcat(num2str(voltageInputArray'),repmat(['V'],length(voltageInputArray),1)),'Location','best')
hold off;

% ppVoltage plot
ppV = max(trace(:,:,end-50000:end),[],3) - min(trace(:,:,end-50000:end),[],3);
figure; hold on; plot(currentOutputArray,ppV); grid on; fig.CurrentAxes.LineStyleOrder = ["-square" "--square" "-.square"];
xlabel('Output Current (A)'); ylabel('Peak-to-Peak Voltage (V)'); title('Peak-to-Peak Voltage vs Output Current')
legend(horzcat(num2str(voltageInputArray'),repmat(['V'],length(voltageInputArray),1)),'Location','best')
hold off;

function [serialObj] = initINA(comPort)

serialObj = serialport(comPort,115200);
configureTerminator(serialObj,"CR/LF");
pause(0.25);
flush(serialObj);
pause(0.25);

end

function [outputArray] = readINA(serialObj)

writeline(serialObj,"read");
pause(0.25);
outputArray(1,:) = str2num(readline(serialObj)) .* [1 1e-3 1e-3];
outputArray(2,:) = str2num(readline(serialObj)) .* [1 1e-3 1e-3];

end