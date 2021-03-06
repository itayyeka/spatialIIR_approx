function [pointers_CELL] = genSensorPointers(objCartesianPos,cfgStruct)
pointers_CELL = ...
    cellfun( ...
    @(x) ...
    objCartesianPos ...
    - ...
    repmat([x 0 0],size(objCartesianPos,1),1) ...
    ,...
    num2cell(cfgStruct.physical.sensorsPos_xVec(:)), ...
    'UniformOutput',false ...
    );
end