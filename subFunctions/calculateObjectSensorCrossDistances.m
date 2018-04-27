function [objectSensorCrossDistances_CELL_MAT] = calculateObjectSensorCrossDistances(cfgStruct)
objCfgVec                               = cfgStruct.scenario.objCfgVec;
nObj                                    = numel(objCfgVec);
objectSensorCrossDistances_CELL_MAT     = cell(nObj,cfgStruct.physical.nSensors);

for sensorId = 1 : cfgStruct.physical.nSensors
    tmpCfgStruct                                = cfgStruct;
    tmpCfgStruct.funcCfgIn.exportOnlyRadius     = 1;
    tmpCfgStruct.funcCfgIn.referencePoint       = [cfgStruct.physical.sensorsPos_xVec(sensorId), 0, 0];
    
    objectsDistanceVec_CELL = cellfun(...
        @(objCfg) ...
        feval(get_objectSphericalPosition(objCfg,tmpCfgStruct),cfgStruct.sim.simTVec), ...
        objCfgVec, ...
        'UniformOutput', false);    
    
    objectSensorCrossDistances_CELL_MAT(:,sensorId) = reshape(objectsDistanceVec_CELL,[],1);
end

end