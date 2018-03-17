function [] = iirSim()
close all;
clearvars;
clc;

simLength                       = 40;
filtLength                      = 2;
tau                             = 10;

bf_yIn  = sym(zeros(simLength,filtLength*2));
bf_yOut = sym(zeros(simLength,filtLength*2));
rx_yOut = sym(zeros(simLength,filtLength*2));
rx_yRef = sym(zeros(simLength,filtLength));

nRounds     = ceil(simLength/(tau-filtLength));
roundlength = floor(simLength/nRounds);
simLength   = nRounds*roundlength;

truncatedIIRLength = (nRounds+2)*filtLength;
yVec               = sym('y',[simLength truncatedIIRLength]);

bf_yOut_single  = sym(zeros(1,filtLength*2));
rx_yOut_single  = sym(zeros(1,filtLength*2));
rx_yRef_single  = sym(zeros(1,filtLength));

for roundId = 1:nRounds
    
    roundClkVec     = (roundId-1)*roundlength+(1:roundlength);
    bf_yOut_CELL    = cell(roundlength,1);
    bf_yOut_CELL(:) = {bf_yOut_single};
    rx_yOut_CELL     = cell(roundlength,1);
    rx_yOut_CELL(:)  = {rx_yOut_single};
    rx_yRef_CELL     = cell(roundlength,1);
    rx_yRef_CELL(:)  = {rx_yRef_single};
    
    for roundClkId=1:roundlength
        
        simClkId = roundClkVec(roundClkId);
        
        try
            rx_yOut_CELL{roundClkId} = bf_yOut(simClkId-tau+filtLength,:);
            null;
        catch
        end
        
        try
            rx_yRef_CELL{roundClkId} = rx_yOut(simClkId-tau,1:filtLength) + yVec(simClkId-tau,1:filtLength);
            null;
        catch
        end        
        
        bf_yOut_CELL{roundClkId} = ...
            subs(rx_yOut_CELL{roundClkId},yVec(:,1:end-filtLength),yVec(:,(filtLength+1):end)) ...
            + ...
            yVec(simClkId,1:(2*filtLength));
        
    end
    
    bf_yOut(roundClkVec,:) = bf_yOut_CELL(:);
    rx_yOut(roundClkVec,:) = rx_yOut_CELL(:);
    rx_yRef(roundClkVec,:) = rx_yRef_CELL(:);
    
end

[rx_yOut rx_yRef]
end