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

poles_rVec       = [0.9   0.9 ];
poles_phVec      = [pi/3  pi/3];
poles_mult_fctor = 1;
nFreqs           = 1000;
symbolicCalc     = 0;
maxN_Factor      = 2;

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
maxGroupDelay     = ceil(max(groupDelay));
maxN              = ceil(maxN_Factor*maxGroupDelay);
freeCoeffs        = polynomCoeffs(2:end);

if symbolicCalc
    aVec = sym('a',size(freeCoeffs));
else
    aVec = freeCoeffs;
end

IIR_approx_polynom{1,1}  = 1;
yMEM                     = sym('y',size(freeCoeffs));
yMEM(:)                  = sym(0);
yMEM(1)                  = sym(1);
zVec                     = z.^(1:length(freeCoeffs));
for n=2:maxN
    newPolynom                    = simplify(1 - sum(aVec.*zVec.*yMEM));
    yMEM(2:end)                   = yMEM(1:end-1);
    yMEM(1)                       = newPolynom;
    IIR_approx_polynom{1,n}       = newPolynom;
    newCoeffs                     = coeffs(newPolynom,z);
    if symbolicCalc
        newCoeffsValues           = eval(subs(newCoeffs,aVec,freeCoeffs));
    else
        newCoeffsValues           = eval(newCoeffs);
    end
    
    newCoeffsValues(isnan(newCoeffsValues)) = 0;
    
    curResponse                   = freqz(newCoeffsValues,1,nFreqs);
    IIR_approx_response{1,n}      = curResponse;
    IIR_approx_response{1,n}      = reshape(curResponse/max(abs(curResponse)),[],1);
end
figure;
plot(fVec,db(abs(IIR_ideal)),fVec,db(abs(IIR_approx_response{maxGroupDelay})),'.-',fVec,db(abs(IIR_approx_response{maxN})),'-*');
legend(...
    { ...
    'Ideal IIR response'...
    ['Response after group-delay (=' num2str(maxGroupDelay) ') Iterations']...
    ['Response after ' num2str(maxN) ' Iterations']...
    });
poles_STR_CELL = cellfun(@(r,phi) genComplexDotPolarSTR(r,phi), num2cell(poles_rVec),num2cell(poles_phVec),'UniformOutput',false);
title(...
    ['IIR approximation response : poles at (' sprintf('%s ',poles_STR_CELL{:}) ')'] ...
    );
end