function [lpf] = genLPF(cfgStruct)
N   = 100;        % FIR filter order
Fp  = cfgStruct.physical.maxInputFreq+cfgStruct.physical.sourceSignalsBandWidth;
Fs  = cfgStruct.physical.fSample;
Rp  = 0.00057565; % Corresponds to 0.01 dB peak-to-peak ripple
Rst = 1e-4;       % Corresponds to 80 dB stopband attenuation

eqnum = firceqrip(N,Fp/(Fs/2),[Rp Rst],'passedge'); % eqnum = vec of coeffs
lpf   = eqnum;

if false
    %% DEBUG
    fvtool(eqnum,'Fs',Fs,'Color','White') % Visualize filter
end
end