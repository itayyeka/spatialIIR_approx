function [sampledSignal] = sampleSignal(signalTVec,signalValues,sampleTVec)

sampledSignal = interp1(signalTVec(:),signalValues,sampleTVec(:));

sampledSignal(isnan(sampledSignal)) = 0;

end