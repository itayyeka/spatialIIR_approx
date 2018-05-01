function [sensorCoefVec,hVec_norm_ORIG,bfNormValues,resultBfNormValues] = generate_nerrowband_robust_bf(externalCfg)
%% config
try
    externalCfg;
catch
    clearvars;
    clc;
end
nThetaValues            = 100;
bf_cosPolynomCoefVec    = [0.103 0.484 0.413]; % second order super cardioid
nSensors                = 5;
propagationSpeed        = 343;
fSignal                 = 2e3;
ULA_direction           = pi;
minNoisePhase           = 0;
maxNoisePhase           = pi/1000;
nNoisePhase             = 12;
enablePlot              = 1;
ignoreFirstCoef         = 0;

externallyConfigurableParamNames        = {...
    'nThetaValues',...
    'bf_cosPolynomCoefVec',...
    'nSensors',...
    'propagationSpeed',...
    'ULA_direction',...
    'minNoisePhase',...
    'nNoisePhase',...
    'enablePlot',...
    'ignoreFirstCoef',...
    'distanceBetweenSensors',...
    'fSignal'...
    };
for configPrmId=1:numel(externallyConfigurableParamNames)
    try
        eval([externallyConfigurableParamNames{configPrmId} ' = externalCfg.' externallyConfigurableParamNames{configPrmId} ';']);
    catch
    end
end
internalPlotOvrd = 0;
try
    enablePlot;
catch
    try
        enablePlot  = externalCfg.enablePlot;
    catch
        enablePlot  = 1;
    end
end
enablePlot = enablePlot || internalPlotOvrd;
%% aux
lambda                  = propagationSpeed/fSignal;

try
    dSensors            = distanceBetweenSensors;
catch
    dSensors            = lambda/100;
end

omegaVal                = 2*pi*fSignal;
%% simulate
if true
    %% aux
    syms                theta;
    bfOrder             = length(bf_cosPolynomCoefVec)-1;
    %% basic bf
    bf_sym              = bf_cosPolynomCoefVec*cos(theta).^reshape(0:bfOrder,[],1);
    try
        thetaValuesVec  = externalCfg.azimuthVec;
    catch
        thetaValuesVec  = linspace(0, 2*pi, nThetaValues);
    end
    bfValues            = eval(subs(bf_sym,theta,thetaValuesVec));
    bfNormValues        = reshape(bfValues/max(abs(bfValues)),[],1);
    %% approxBf
    if true
        nRows = 0;
        for n=0:bfOrder
            for k=0:n
                nRows = nRows + 1;
            end
        end
        %% alphaVec, betaMat
        syms        omega;
        alphaVec    = [];
        betaMat     = sym('beta',[nRows,nSensors]);
        rowId       = 0;
        colId       = 0;
        phi_m       = ULA_direction; % ULA - first sensor is the left-most sensor
        for n=0:bfOrder
            for k=0:n
                rowId               = rowId + 1;
                alphaVec(rowId,1)   = 0;
                if n==k
                    alphaVec(rowId,1) = bf_cosPolynomCoefVec(n+1);
                end
                for m=1:nSensors
                    r_m = (m-1)*dSensors; % ULA
                    
                    cosValue = cos(phi_m);
                    sinValue = sin(phi_m);
                    
                    if phi_m == pi
                        cosValue = -1;
                        sinValue = 0;
                    end
                    
                    betaMat(rowId,m) =                          ...
                        (cosValue^k)                          ...
                        *                                       ...
                        (sinValue^(n-k))                      ...
                        *                                       ...
                        nchoosek(n,k)                           ...
                        *                                       ...
                        ((-1i*omega*r_m/propagationSpeed)^n)    ...
                        /factorial(n);
                end
            end
        end
        
        betaMatValues = eval(subs(betaMat,omega,omegaVal));
        
        %% hVec
        hVec            = pinv(betaMatValues)*alphaVec;
        hVec_norm       = hVec/norm(hVec);
        hVec_norm_ORIG  = hVec_norm;
        if ignoreFirstCoef
            hVec_norm   = hVec_norm/hVec_norm(1); % making sure that the first element is 1
        end
        hVec_norm       = reshape(hVec_norm,[],1);
        
        %% steerVec
        phi_m       = ULA_direction; % ULA - first sensor is the left-most sensor
        
        for m = 1:nSensors
            r_m             = (m-1)*dSensors; % ULA
            tau_m           = cos(theta-phi_m)*(r_m/propagationSpeed);
            steerVec(m,1)   = exp(-1i*tau_m*omega);
        end
        
        %% sensorCoefVec
        sensorCoefVec           = zeros(size(hVec_norm));
        sensorCoefVec(1)        = 1-hVec_norm(1);
        sensorCoefVec(2:end)    = -hVec_norm(2:end);
        
        %% resultBf
        resultBf            = transpose(hVec)*steerVec;
        resultBfValues      = eval(subs(resultBf,{omega, theta}, {omegaVal,thetaValuesVec}));
        resultBfNormValues  = reshape(resultBfValues/max(abs(resultBfValues)),[],1);
        
        %% noisedBf
        if enablePlot
            syms                phErr;
            phaseNoiseVec       = linspace(minNoisePhase,maxNoisePhase,nNoisePhase);
            noisedBfValuesCELL  = cell(1,nNoisePhase);
            resultBf_final      = 1-transpose(sensorCoefVec)*steerVec*exp(1i*phErr);
            %{
        The result feedback iir denominator is
        1 + betaVec*steerVec*exp(1i*phErr)
        
        We can make sure the the free coef is 1 by removing the first coef
        from the hVec.
            %}
            
            for noiseId = 1:nNoisePhase
                parfor_omega_CELL{noiseId}      = omega;
                parfor_theta_CELL{noiseId}      = theta;
                parfor_phErr_CELL{noiseId}      = phErr;
                parfor_resultBf_CELL{noiseId}   = resultBf_final;
            end
            
            parfor noiseId = 1:nNoisePhase
                parfor_omega    = parfor_omega_CELL{noiseId};
                parfor_theta    = parfor_theta_CELL{noiseId};
                parfor_phErr    = parfor_phErr_CELL{noiseId};
                parfor_resultBf = parfor_resultBf_CELL{noiseId};
                
                parfor_noisedBf                 = parfor_resultBf;
                noisedBfValues                  = ...
                    subs( ...
                    parfor_noisedBf, ...
                    {parfor_omega,  parfor_theta,       parfor_phErr            }, ...
                    {omegaVal,      thetaValuesVec,     phaseNoiseVec(noiseId)  } ...
                    );
                noisedBfValuesCELL{noiseId}    = reshape(noisedBfValues,[],1);
            end
            
            evaluated_noisedBfValuesCELL                = cellfun(@(CELL) eval(CELL)            , noisedBfValuesCELL            , 'UniformOutput', false);
            evaluated_normalized_noisedBfValuesCELL     = cellfun(@(CELL) CELL/max(abs(CELL))   , evaluated_noisedBfValuesCELL  , 'UniformOutput', false);
            noisedBfValuesMat                           = cell2mat(evaluated_normalized_noisedBfValuesCELL);
        end
    end
end

%% plot
if enablePlot
    close all;
    figure;
    plot(thetaValuesVec,db([bfNormValues noisedBfValuesMat]));
end
end