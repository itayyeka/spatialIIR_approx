function [sampledSignal] = f_sampleSignal(signalTVec,signalValues,sampleTVec)

assert(isempty(signalTVec) || all(sampleTVec<=max(signalTVec(:))),'ERROR');

try
    sampledSignal                       = interp1(signalTVec(:),signalValues,sampleTVec(:));
    sampledSignal(isnan(sampledSignal)) = 0;
catch
    sampledSignal = zeros(size(sampleTVec,1),size(signalValues,length(size(signalValues))));
end

if false
    figure;
    plot(signalTVec,signalValues,'-*');
    hold on;
    stem(sampleTVec,sampledSignal);
    close all;
end
end