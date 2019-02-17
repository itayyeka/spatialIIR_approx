function [yOut,arrayFeedback] = processor_goldenModel(arrayInput,cfgStruct)

try 
    cfgStruct.sim.goldenModelMode;
catch
    cfgStruct.sim.goldenModelMode = 'CB';
end

if strcmpi(cfgStruct.sim.goldenModelMode,'basic')
    [yOut,arrayFeedback] = processor_goldenModel_basic(arrayInput,cfgStruct);
end

if strcmpi(cfgStruct.sim.goldenModelMode,'CB')
    [yOut,arrayFeedback] = processor_goldenModel_CB(arrayInput,cfgStruct);
end
end