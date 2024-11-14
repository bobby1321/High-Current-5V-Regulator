serialportlist("all")
serialportlist("available")
serialObj = serialport("COM6",115200);
configureTerminator(serialObj,"CR/LF");
pause(0.25)
flush(serialObj);
pause(0.25)
writeline(serialObj,"read")
pause(0.25);
array1 = str2num(readline(serialObj)) .* [1 1e-3 1e-3];
array2 = str2num(readline(serialObj)) .* [1 1e-3 1e-3];