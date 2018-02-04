function [simOutput] = simulate_IIR_approx_singleScenario(cfgStruct)
%% init

%%
%{
First, the temporal positions of each object will be calculated.
%}
cfgSimDuration          = cfgStruct.sim.simDuration;
f_objCartesian          = @(t,f_getCartesian) f_getCartesian(t);
f_objCylindricalRadious = @(objCylindrical) objCylindrical(:,1);

f_getObjectRadious = ...
    @(objCfg,t) ...
    f_objCylindricalRadious( ...        3. fetch only the radious from the cylindrical
    convCartesianToCylindrical( ...     2. convert cartesian to cylindrical
    f_objCartesian( ...                 1. request catersian of an object in t      
    t,objCfg.cartesianPosition ...  
    ) ...
    ) ...
    );

minObjectDistance = ...
    min(...                             5. fetch the globally minimal object distance.
    cellfun( ...                        4. collect all minimal distances
    @(objCfg) ...
    f_getObjectRadious( ...             3. fminbnd returns the minimizero fo the function, now we fetch its value
    objCfg,...
    fminbnd(...                     
    @(t) ...                            2. combined steps 1-3 to a single function of objectDistance(t,objCfg)
    f_getObjectRadious( ...             1. fetch only the radious from the cylindrical
    objCfg,t ...    
    ), ...
    0,cfgSimDuration ...
    ) ...                               fminbnd                             
    ),...                               
    cfgStruct.scenario.objCfgVec ...    the cell array of objects
    ) ...
    );

%%
%{
The minimal distance to the sensors will determine the "tau_feedback".
%}
propagationVelocity = cfgStruct.physical.propagationVelocity;
minDelay_continious = minObjectDistance/propagationVelocity;    % this is the "tau_feedback"
tSample             = 1/cfgStruct.physical.fSample;
minDelay_samples    = ceil(minDelay_continious/tSample);
minDelay            = minDelay_samples*tSample;                 %quantizing the min delay to avoid errors in the samples fetching
simNSegments        = ceil(cfgSimDuration/minDelay);
simDuration_Samples = simNSegments*minDelay_samples;
simDuration         = simDuration_Samples*tSample;

%%
%{
A delayed (by "tau_feedback") version of the objects positions will be
converted to delays.
These delays will serve as an offset from the current time when
fetching samples from the object's transmitters to the sensors inputs.
%}
f_getObjectDelay = @(objCfg,t) f_getObjectRadious(objCfg,t)/propagationVelocity;
discreteTVec = tSample*(0:(simDuration_Samples-1));

objSeperatedDelays_CELL = ...
    cellfun(...
    @(objCfg,t) ...
    f_getObjectDelay(...
    objCfg,...
    discreteTVec ... t
    ), ...
    cfgStruct.scenario.objCfgVec,...
    'UniformOutput',false ...
    );

%%
%{
The simulation will be segmented according to the minimal "tau_feedback"
so that each segment can be calculated indepedently due to the fact
that each sample in the segment depends only on "tau_feedback" delayed
signals.
%}

%%
%{
An initial non-feedback signals will be assigned to the sensors inputs
according to the object positions.
%}

%%
%{
In each segment, both the sensor inputs and eahc object's feedback
signal will be calculated and summed.
%}

end