function [minDistance] = findObjectMinDistanceInSimulation(objCfg,cfgStruct)
cfgStruct.funcCfgIn.exportOnlyRadius    = 1;
objectSpericalPositionFunc              = get_objectSphericalPosition(objCfg,cfgStruct);
[~,minDistance]                         = fminbnd(objectSpericalPositionFunc,0,cfgStruct.sim.simDuration);
end