function [objSphericalPos] = get_objectSphericalPosition(objCfg,cfgStruct,tVec)
try
    %% sample position mode
    tVec;
    assert(false,'STILL NOT WRITTEN');
catch
    %% function output mode
    try
        funcCfgIn = cfgStruct.funcCfgIn;
    catch
        funcCfgIn = [];
    end
    
    objSphericalPos = @(t) convCartesianToSpherical(objCfg.cartesianPosition(t),funcCfgIn);
end
end