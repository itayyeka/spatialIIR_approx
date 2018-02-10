function [] = IIR_approx_proof_of_concept()
close all;
clc;
[funcPath,~,~] = fileparts(mfilename('fullpath'));
try
    spatialIIR_approx_subFunctions_Indicator;
catch
    addpath(genpath(fullfile(funcPath,'subFunctions')));
    spatialIIR_approx_subFunctions_Indicator;
end

poles_rVec                  = [0.9    0.9    ];%  0.9   0.9];
poles_phVec                 = [3*pi/8 3*pi/8];%  pi/4  pi/4];
poles_mult_fctor            = 2;
nFreqs                      = 1000;
symbolicCalc                = 1;
maxN_Factor                 = 1;
idealApprox                 = 0;
useHistoryDelay             = 1;
useMultipleHistoryDelay     = 0;
delayOffset                 = 0;

poles_mult_fctor = ceil(poles_mult_fctor);
poles_rVec       = repmat(poles_rVec,1,poles_mult_fctor);
poles_phVec      = repmat(poles_phVec,1,poles_mult_fctor);
poles_values     = poles_rVec.*exp(1i.*poles_phVec);

syms z;

polynomTerms  = z - poles_values;
polynom       = prod(polynomTerms);
polynomCoeffs = fliplr(eval(coeffs(polynom,z)));

[IIR_ideal,fVec]  = freqz(1,polynomCoeffs,nFreqs);
IIR_ideal         = IIR_ideal/max(abs(IIR_ideal));
[groupDelay,~]    = grpdelay(1,polynomCoeffs,nFreqs);
maxGroupDelay     = ceil(max(abs(groupDelay)));
maxN              = ceil(maxN_Factor*maxGroupDelay);
freeCoeffs        = polynomCoeffs(2:end);

if symbolicCalc
    aVec = sym('a',size(freeCoeffs));
else
    aVec = freeCoeffs;
end

IIR_approx_polynom{1,1}  = 1;
nCoeffs                  = length(freeCoeffs);
yMEM                     = sym('y',size(freeCoeffs));
yMEM(:)                  = sym(0);
yMEM(1)                  = sym(1);
zVec                     = z.^(1:nCoeffs);
for n=2:maxN
    
    disp(['Currently processing iteration #' num2str(n) '/' num2str(maxN)])
    
    newPolynom                    = simplifyFraction(simplify(1 - sum(aVec.*zVec.*yMEM)),'Expand',true);
    yMEM(2:end)                   = yMEM(1:end-1);
    yMEM(1)                       = newPolynom;
    IIR_approx_polynom{1,n}       = newPolynom;
    newCoeffs                     = coeffs(newPolynom,z);
    if symbolicCalc
        newCoeffsValues           = eval(subs(newCoeffs,aVec,freeCoeffs));
    else
        newCoeffsValues           = eval(newCoeffs);
    end
    
    disp(['There are ' num2str(sum(isnan(newCoeffsValues))) ' nans.']);
    newCoeffsValues(isnan(newCoeffsValues)) = 0;  
    
    curResponse                   = freqz(newCoeffsValues,1,nFreqs);
    IIR_approx_response{1,n}      = reshape(curResponse/max(abs(curResponse)),[],1);
    
    if ~idealApprox && n>=nCoeffs && mod(n,nCoeffs)==0
        if useHistoryDelay
            delayVec = z.^(useMultipleHistoryDelay*(delayOffset+(0:(nCoeffs-1))));
            yMEM     = simplifyFraction(yMEM(1).*reshape(delayVec,size(yMEM)),'Expand',true);
        else
            yMEM(2:end) = 0;
        end
    end
end
figure;
plot(fVec,db(abs(IIR_ideal)),fVec,db(abs(IIR_approx_response{min(maxGroupDelay,maxN)})),'.-',fVec,db(abs(IIR_approx_response{maxN})),'-*');
legend(...
    { ...
    'Ideal IIR response'...
    ['Response after group-delay (=' num2str(min(maxGroupDelay,maxN)) ') Iterations']...
    ['Response after ' num2str(maxN) ' Iterations']...
    });
poles_STR_CELL = cellfun(@(r,phi) genComplexDotPolarSTR(r,phi), num2cell(poles_rVec),num2cell(poles_phVec),'UniformOutput',false);
title(...
    ['IIR approximation response : poles at (' sprintf('%s ',poles_STR_CELL{:}) ')'] ...
    );
end