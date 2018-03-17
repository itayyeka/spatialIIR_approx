function [presentationOutput] = presentSimOutput(cfgStruct,simOutput)
presentationOutput = [];
figure; plot(abs(simOutput.yOut(:)));
end