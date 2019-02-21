function [] = twoFreq_proofOfConcept(cfgIn)
clear all;
close all;
clc;
goldenCfgEnable = 0;
%% configure
if goldenCfgEnable
    simDuration_iterations      = 200;%sec
    nSensors                    = 5;
    r                           = 0.9;
    targetRange_samples         = 100;
    propagationVelocity         = 343;
    sigFreq                     = 10;%Hz
    dF                          = 0.001;%Hz
    thetaS                      = pi/2;
    historyIterNum              = 3;
    rangeError                  = 0*targetRange_samples;
    stftDuration_iterPrecent    = 30; % precent of iteration
else
    simDuration_iterations      = 94;%sec
    nSensors                    = 3;
    r                           = 0.9;
    targetRange_samples         = 256;
    propagationVelocity         = 3e8;
    sigFreq                     = 10e9;%Hz
    dF                          = 1e3;%Hz
    thetaS                      = pi/2;
    historyIterNum              = 3;
    rangeError                  = 0*targetRange_samples;
    stftDuration_iterPrecent    = 50; % precent of iteration
end
%% auxiliary
c               = propagationVelocity;
lambda          = c/sigFreq;
D               = lambda/2;
f_exp           = @(f,t) exp(-1i*2*pi*f*t);
f_sig1          = @(t) f_exp(sigFreq,t).*heaviside(t);
f2              = sigFreq + dF;
f_sig2          = @(t) f_exp(f2,t).*heaviside(t);
N               = nSensors;
f_dTOA          = @(theta) reshape(((N-1):-1:0)*D*cos(theta)/c,[],1);
f_steering      = @(theta,f) reshape(exp(1i*2*pi*f*f_dTOA(theta)),[],1);
f_hCB           = @(thetaS,range,f,f_align) ...
    reshape( ...
    (r/N) ...
    * ...
    conj(f_steering(thetaS,f)) ...
    * ...
    exp(-1i*2*pi*f_align*2*(range+rangeError)/c) ...
    ,[],1);
fSample                 = 5*f2;
tSample                 = 1/fSample;
tPd                     = targetRange_samples*tSample;
targetRange             = c*tPd;
nSamplesIter            = floor((2*tPd-N*D/c)/tSample);
stftDuration_samples    = round(stftDuration_iterPrecent*nSamplesIter/100);
firstIterStftTVec       = tSample*(0:(stftDuration_samples-1));
stftRef1                = f_exp(-sigFreq,firstIterStftTVec);
stftRef2                = f_exp(-f2,firstIterStftTVec);
f_theoryBp              = @(x) sqrt((1-r)^2*(1-cos(N*x))./(N^2*(1-cos(x))+r^2*(1-cos(N*x))+N*r*(-1+cos(x)+cos(N*x)-cos((N-1)*x))));

targetAngleVec          = linspace(0, pi, 37);
nTheta                  = length(targetAngleVec);
simDuration_samples     = simDuration_iterations*nSamplesIter;
h1Mat_ideal             = zeros(simDuration_samples,nTheta);
h1Mat                   = zeros(simDuration_samples,nTheta);
h2Mat                   = zeros(simDuration_samples,nTheta);
twoFreqBf               = zeros(simDuration_iterations,nTheta);

hCB             = f_hCB(thetaS,targetRange,sigFreq,-dF);
hCB_ideal       = f_hCB(thetaS,targetRange,sigFreq,sigFreq);
hCBT            = transpose(hCB);
hCBT_ideal      = transpose(hCB_ideal);
hCBT2           = [zeros(1, N-1) 1];
sampleIdVec     = 1 : nSamplesIter;
targetAngleId   = 0;



%% simulate
for targetAngle = targetAngleVec
    targetAngleId   = targetAngleId + 1;
    dTOAVec         = f_dTOA(targetAngle);
    h1              = [];
    h1_ideal        = [];
    h2              = [];
    
    for IterId = 1 : simDuration_iterations
        iterSampleIdVec             = (IterId-1)*nSamplesIter + sampleIdVec;
        iterTVec                    = (iterSampleIdVec-1)*tSample;
        historyStartIterId          = IterId-(1+historyIterNum);
        historyEndIterId            = IterId-1;
        historySampleIdVec          = ((1+historyStartIterId*nSamplesIter) : historyEndIterId*nSamplesIter);
        historyTVec                 = (historySampleIdVec-1)*tSample;
        feedbackGenerationTime      = iterTVec - 2*tPd;
        feedbackGenerationTimeMat   = repmat(feedbackGenerationTime(:),1,N)-repmat(reshape(dTOAVec,1,[]),nSamplesIter,1);
        
        curIterInput_sig                = f_sig1(feedbackGenerationTimeMat);
        curIterInput_sig2               = f_sig2(feedbackGenerationTimeMat);
        curIterInput_feedback_ideal     = f_resample(historyTVec(:),h1_ideal(:),feedbackGenerationTimeMat);
        curIterInput_feedback           = f_resample(historyTVec(:),h1(:),feedbackGenerationTimeMat);
        curIterInput_feedback2          = f_resample(historyTVec(:),h2(:),feedbackGenerationTimeMat);
        
        if false
            %% DEBUG
            figure;
            subplot(3,1,1);
            plot(iterTVec,real(curIterInput_sig),'-*');
            subplot(3,1,2);
            plot(iterTVec,real(curIterInput_feedback),'-o');
            subplot(3,1,3);
            plot(iterTVec,real(curIterInput_feedback+curIterInput_sig),'-.');
            try
                xlim([feedbackGenerationTimeMat(1,1) feedbackGenerationTimeMat(100,1)]);
            catch
            end
            close all;
        end
        
        iterH1_ideal = reshape( ...
            ( ...
            curIterInput_sig ...
            + ...
            curIterInput_feedback_ideal ...
            ) ...
            * ...
            hCBT_ideal(:) ...
            ,[],1);
        
        h1_ideal = ...
            [...
            h1_ideal(:) ...
            ; ...
            iterH1_ideal(:) ...
            ];
        
        iterH1 = reshape( ...
            ( ...
            curIterInput_sig ...
            + ...
            curIterInput_feedback ...
            ) ...
            * ...
            hCBT(:) ...
            ,[],1);
        
        h1 = ...
            [...
            h1(:) ...
            ; ...
            iterH1(:) ...
            ];
        
        iterH2 = reshape( ...
            ( ...
            curIterInput_sig2 ...
            + ...
            curIterInput_feedback2 ...
            ) ...
            * ...
            hCBT2(:) ...
            ,[],1);
        
        h2 = ...
            [...
            h2(:) ...
            ; ...
            iterH2(:) ...
            ];
        
        if false
            %% DEBUG
            figure; plot(real(h1));
            close all;
        end
        
        stftInput_iterH1 = iterH1(end-stftDuration_samples+1:end);
        stftInput_iterH2 = iterH2(end-stftDuration_samples+1:end);
        iterH1Stft       = reshape(stftRef1,1,[])*stftInput_iterH1(:);
        iterH2Stft       = reshape(stftRef2,1,[])*stftInput_iterH2(:);
    
        twoFreqBf(IterId,targetAngleId)     = 1/((1/iterH1Stft) - (1/iterH2Stft));
    end   
    
    h1Mat_ideal(:,targetAngleId)    = h1_ideal(:);
    h1Mat(:,targetAngleId)          = h1(:);
    h2Mat(:,targetAngleId)          = h2(:);
end

bp              = h1Mat_ideal(end,:);
bp              = bp/max(abs(bp));
dbAbBp          = db(abs(bp));

twoFreqBf(isnan(twoFreqBf)) = 0;

bp_twoFreq      = twoFreqBf(end,:);
% bp_twoFreq      = sum(twoFreqBf);
bp_twoFreq      = bp_twoFreq/max(abs(bp_twoFreq));
dbAbsBp_twoFreq = db(abs(bp_twoFreq));
if true
    %%DEBUG
    theoryAngleVec              = linspace(0,pi,1000);
    theoryDuVec                 = pi*(cos(theoryAngleVec)-cos(thetaS));
    theoryBp                    = f_theoryBp(theoryDuVec);
    theoryBp(isnan(theoryBp))   = 1;
    theoryBp_norm               = theoryBp/max(theoryBp);
    dbAbstheoryBp_norm          = db(abs(theoryBp_norm));
    figure;
    subplot(2,1,1);
    plot(targetAngleVec,dbAbBp(:));
    hold on;
    plot(theoryAngleVec,dbAbstheoryBp_norm(:),'--');
    subplot(2,1,2);
    plot(targetAngleVec,dbAbsBp_twoFreq);
    
    figure;plot(db(abs(h1Mat_ideal)));
    figure;plot(db(abs(twoFreqBf)));
    close all;
end
end

function [yResample] = f_resample(x,y,xResample)
if length(x)>length(y)
    ySliced     = y;
    xSliced     = x(end-length(y)+1:end);
else
    ySliced     = y(end-length(x)+1:end);
    xSliced     = x;
end

yResample                   = zeros(size(xResample));
if ~isempty(xSliced)
    valIdSampleId               = logical(double(xResample>=min(xSliced)) .* double(xResample<=max(xSliced)));
    yResample(valIdSampleId)    = interp1(xSliced(:),ySliced(:),xResample(valIdSampleId),'spline');
    if false
        %% DEBUG
        figure;
        plot(xSliced,real(ySliced),'-*');
        hold on;
        plot(xResample,real(yResample));
        N    = size(xResample,2);
        legendStr   = cellfun(@(sensorId) ['sensor #' num2str(sensorId)], num2cell(0:(N-1)), 'UniformOutput', false);
        legend(['original' ; legendStr(:)]);
        try
            xlim([xResample(1) xResample(100)]);
        catch
        end
        close all;
    end
end
end