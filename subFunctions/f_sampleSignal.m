function [sampledSignal] = f_sampleSignal(signalTVec,signalValues,sampleTVec)

assert(isempty(signalTVec) || all(sampleTVec<=max(signalTVec(:))),'ERROR');

modifiedSampleTVec                                          = sampleTVec;
modifiedSampleTVec(modifiedSampleTVec<min(signalTVec))      = min(signalTVec);
modifiedSampleTVec(modifiedSampleTVec>max(signalTVec))      = max(signalTVec);

sampleInterval      = max(modifiedSampleTVec) - min(modifiedSampleTVec);
intervalSlack       = 0.01;
signalInterval_min  = min(modifiedSampleTVec) - intervalSlack*sampleInterval;
signalInterval_max  = max(modifiedSampleTVec) + intervalSlack*sampleInterval;

try
    sliceMask               = logical(double(signalTVec>=signalInterval_min).*double(signalTVec<=signalInterval_max));
    signalValues_sliced     = signalValues(sliceMask,:,:);
    signalTVec_sliced       = signalTVec(sliceMask);
catch
    signalValues_sliced     = signalValues;
    signalTVec_sliced       = signalTVec;
end

try
    sampledSignal                       = interp1(signalTVec_sliced(:),signalValues_sliced,modifiedSampleTVec(:),'spline');
    sampledSignal(isnan(sampledSignal)) = 0;
catch
    sampledSignal                       = zeros(size(sampleTVec,1),size(signalValues,length(size(signalValues))));
end

if true
    figure;
    plot(signalTVec,real(signalValues(:,1)),'-*');
    hold on;
    stem(sampleTVec,real(sampledSignal(:,1)));
    close all;
end
end