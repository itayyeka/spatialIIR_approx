function [simOutput] = simulate_IIR_approx_singleScenario(cfgStruct)
%% init

%%
%{
First, the temporal positions of each object will be calculated.
%}
cfgSimDuration        = cfgStruct.sim.simDuration;
f_objCartesian        = @(t,f_getCartesian) f_getCartesian(t);
f_objRadious          = @(objCylindrical) objCylindrical(1);
fminbnd_fetchMinValue = @(fminbndRes) fminbndRes(2);

minObjectDistance = ...
    min(...                             7. fetch the globally minimal object distance.
    cellfun( ...                        6. collect all minimal distances
    @(objCfg) ...
    f_objRadious( ...                   5. fminbnd returns the minimizero fo the function, now we fetch its value
    convCartesianToCylindrical( ... 
    f_objCartesian( ...             
    fminbnd(...                     
    @(t) ...                            4. combined steps 1-3 to a single function of objectDistance(t,objCfg)
    f_objRadious( ...                   3. fetch only the radious from the cylindrical
    convCartesianToCylindrical( ...     2. convert cartesian to cylindrical
    f_objCartesian( ...                 1. request catersian of an object in t      
    t,objCfg.cartesianPosition ...  
    ) ...
    ) ...
    ), ...
    0,cfgSimDuration ...
    ) ...                               this concludes the fminbnd which calc the t of the min distance (this is also th t for "f_objCartesian(t,f_getCartesian)"
    ,objCfg.cartesianPosition ...       this is also th f_getCartesian for "f_objCartesian(t,f_getCartesian)"
    ) ...                               f_objCartesian
    ) ...                               convCartesianToCylindrical
    ),...                               f_objRadious
    cfgStruct.scenario.objCfgVec ...    the cell array of objects
    ) ...
    );

propagationVelocity = cfgStruct.physical.propagationVelocity;
minDelay            = minObjectDistance/propagationVelocity; % this is the "tau_feedback"
simNSegments        = ceil(cfgSimDuration/minDelay);
simDuration         = simNSegments*minDelay;
%%
%{
The minimal distance to the sensors will determine the "tau_feedback".
%}

%%
%{
A delayed (by "tau_feedback") version of the objects positions will be
converted to delays.
These delays will serve as an offset from the current time when
fetching samples from the object's transmitters to the sensors inputs.
%}

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