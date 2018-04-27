function [sampledSignal] = f_sampleSignal(signalTVec,signalValues,sampleTVec)

assert(isempty(signalTVec) || all(sampleTVec<=max(signalTVec(:))),'ERROR');

modifiedSampleTVec                                          = sampleTVec;
modifiedSampleTVec(modifiedSampleTVec<min(signalTVec))      = min(signalTVec);
modifiedSampleTVec(modifiedSampleTVec>max(signalTVec))      = max(signalTVec);

try
    sampledSignal                       = interp1(signalTVec(:),signalValues,modifiedSampleTVec(:),'spline');
    sampledSignal(isnan(sampledSignal)) = 0;
catch
    sampledSignal = zeros(size(sampleTVec,1),size(signalValues,length(size(signalValues))));
end

if false
    figure;
    plot(signalTVec,real(signalValues(:,1)),'-*');
    hold on;
    stem(sampleTVec,real(sampledSignal(:,1)));
    close all;
end
end