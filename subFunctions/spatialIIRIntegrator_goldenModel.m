function [xNew,xOld,yNew,yOld] = spatialIIRIntegrator_goldenModel(integratorInput_x, integratorInput_y, cfgStruct)

if cfgStruct.physical.singleTransmitterFlag
    % in single transmitter scenario, the outout is a single column vector
    coefMat = repmat(reshape(cfgStruct.filter.sensorWeights,1,[]),size(integratorInput_x,1),1);
    xNew    = integratorInput_x(:,1);
    yNew    = xNew+sum(integratorInput_y(:,2:end).*coefMat,2);
    yOld    = integratorInput_y(:,2);
    xOld    = integratorInput_x(:,2);
end

end