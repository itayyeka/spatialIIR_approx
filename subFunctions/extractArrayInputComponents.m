function [nominalInput, arrayInput_x, arrayInput_y] = extractArrayInputComponents(arrayInput,cfgStruct)
nominalInput = filter(cfgStruct.filter.lpfCoeffs,1,arrayInput);
demodulatorX = repmat(cfgStruct.dynamics.segmentModulatorX(:),1,cfgStruct.physical.nSensors);
arrayInput_x = filter(cfgStruct.filter.lpfCoeffs,1,demodulatorX.*arrayInput);
demodulatorY = repmat(cfgStruct.dynamics.segmentModulatorX(:),1,cfgStruct.physical.nSensors);
arrayInput_y = filter(cfgStruct.filter.lpfCoeffs,1,demodulatorY.*arrayInput);
end