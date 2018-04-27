function [yOut,arrayFeedback] = processor_goldenModel(arrayInput,cfgStruct)

try 
    cfgStruct.sim.goldenModelMode;
catch
    cfgStruct.sim.goldenModelMode = 'basic';
end

if strcmpi(cfgStruct.sim.goldenModelMode,'basic')
    [yOut,arrayFeedback] = processor_goldenModel_basic(arrayInput,cfgStruct);
end

end