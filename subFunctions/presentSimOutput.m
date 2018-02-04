function [presentationOutput] = presentSimOutput(cfgStruct,simOutput)
presentationOutput = [];
figure; plot(simOutput.yOut(:));
end