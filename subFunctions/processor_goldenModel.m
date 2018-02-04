function [yOut,arrayTx] = processor_goldenModel(arrayInput,cfgStruct)

[nominalInput, arrayInput_x, arrayInput_y] = extractArrayInputComponents(arrayInput,cfgStruct);

x0 = nominalInput;
y0 = nominalInput;
xn = arrayInput_x;
yn = arrayInput_y;

integratorInput_x = x0 + xn;
integratorInput_y = y0 + yn;

[xNew,xOld,yNew,yOld] = spatialIIRIntegrator_goldenModel(integratorInput_x, integratorInput_y, cfgStruct);

yOut = yNew - yOld;
xOut = xNew - xOld;

arrayTx = zeros(size(arrayInput));

stopFeedback = cfgStruct.dynamics.segmentId > cfgStruct.filter.nFilterRounds;

if cfgStruct.physical.singleTransmitterFlag
    arrayTx(:,1) = ...
        cfgStruct.dynamics.segmentModulatorX(:) .* xNew(:) ...
        + ...
        -1* stopFeedback * yOut(:) ...
        + ...
        cfgStruct.dynamics.segmentModulatorY(:) .* yNew(:) ...
        -1* stopFeedback * xOut(:) ...
        ;
end

yOut = yOut*stopFeedback;
end