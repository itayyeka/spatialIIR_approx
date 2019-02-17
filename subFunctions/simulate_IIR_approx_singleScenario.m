function [simOutput] = simulate_IIR_approx_singleScenario(cfgStruct)
%% init
try
    syncSig_twoFreqEnable = cfgStruct.sim.syncSig_twoFreqEnable;
catch
    syncSig_twoFreqEnable = 1;
end

%%
%{
First, the temporal positions of each object will be calculated.
%}
objCfgVec               = cfgStruct.scenario.objCfgVec;
cfgSimDuration          = cfgStruct.sim.simDuration;
f_objCartesian          = @(t,f_getCartesian) f_getCartesian(t);
nSensors                = cfgStruct.physical.nSensors;

objectMinDistancesVec   = ...
    cellfun( ...
    @(objCfg) ...
    findObjectMinDistanceInSimulation(objCfg,cfgStruct),...
    objCfgVec ...
    );

minObjectDistance       = min(objectMinDistancesVec);

%%
%{
The minimal distance to the sensors will determine the "tau_feedback".
%}
propagationVelocity = cfgStruct.physical.propagationVelocity;
minDelay_continious = 0.95*minObjectDistance*min((1/propagationVelocity),(1/cfgStruct.physical.txPropagationVeclocity));    % this is the "tau_feedback"
tSample             = 1/cfgStruct.physical.fSample;
minDelay_samples    = floor(minDelay_continious/tSample);       % using floor to make sure the recursion is not compromised
minDelay            = minDelay_samples*tSample;                 % quantizing the min delay to avoid errors in the samples fetching
simNSegments        = ceil(cfgSimDuration/minDelay);
simDuration_Samples = simNSegments*minDelay_samples;
simDuration         = simDuration_Samples*tSample;
simTVec             = reshape((0:(simDuration_Samples-1))*tSample,[],1);

cfgStruct.sim.simTVec = simTVec;

%% calculate the distances of each object from each sensor in each moment.

objectSensor_crossDistances_CELL_MAT = calculateObjectSensorCrossDistances(cfgStruct);

if false
    %% DEBUG
    figure;plot(cell2mat(objectSensor_crossDistances_CELL_MAT));
end

%% calculate times for tx,rx & feedback
nChannels               = cfgStruct.physical.nCommunicationChannels;
nObjects                = numel(objCfgVec);
segmentSampleDuration   = minDelay_samples;
objId_CELL_MAT          = num2cell(repmat(reshape(1:nObjects,[],1),1,nSensors));
objCfg_CELL_MAT         = cellfun(@(objId) objCfgVec{objId}, objId_CELL_MAT, 'UniformOutput', false);
sensorId_CELL_MAT       = num2cell(repmat(reshape(1:nSensors,1,[]),nObjects,1));

objectSensor_crossDownlinkDelay_CELL_MAT = ...
    cellfun(@(distanceVec) distanceVec/cfgStruct.physical.propagationVelocity ...
    ,objectSensor_crossDistances_CELL_MAT ...
    ,'UniformOutput',false);

objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT = ...
    cellfun(@(downlinkDelayVec)  simTVec-downlinkDelayVec ...
    ,objectSensor_crossDownlinkDelay_CELL_MAT ...
    ,'UniformOutput',false);

if false
    %% DEBUG
    figure;plot(cell2mat(objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT));
end

objectSensor_crossUplinkDelay_CELL_MAT = ...
    cellfun(@(distanceVec) distanceVec/cfgStruct.physical.txPropagationVeclocity ...
    ,objectSensor_crossDistances_CELL_MAT ...
    ,'UniformOutput',false);

objectSensor_crossUplinkGenerationTimeVec_CELL_MAT = ...
    cellfun(@(uplinkDelayVec)  simTVec-uplinkDelayVec ...
    ,objectSensor_crossUplinkDelay_CELL_MAT ...
    ,'UniformOutput',false);

if false
    %% DEBUG
    figure;
    plotObjId       =1;
    plotSensorId    =1;
    
    plot([...
        simTVec(:)                                                                  ...
        objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT{plotObjId,plotSensorId}(:)     ...
        objectSensor_crossFeedbackGenerationTimeVec_CELL_MAT{plotObjId,plotSensorId}(:)     ...
        ]);
    
    isequal(...
        objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT{plotObjId,plotSensorId}(:),    ...
        objectSensor_crossFeedbackGenerationTimeVec_CELL_MAT{plotObjId,plotSensorId}(:)     ...
        )
end

%%
objectsRx               = zeros(simDuration_Samples,    nObjects,   nChannels   );
arrayInput              = zeros(simDuration_Samples,    nSensors,   nChannels   );
arrayResponse           = zeros(simDuration_Samples,    nSensors,   nChannels   );
arrayOutput             = zeros(simDuration_Samples,    1   );

assert(cfgStruct.physical.singleTransmitterFlag==1,'STILL NOT SUPPORTED');

historyStartSampleId    = 1;

for segmentId=1:simNSegments
    startSampleID               = (segmentId-1)*segmentSampleDuration+1;
    endSampleID                 = segmentId*segmentSampleDuration;
    segmentSampleIdVec          = startSampleID:endSampleID;
    segmentDiscreteTVec         = (segmentSampleIdVec-1)*tSample;
    historyEndSampleId          = startSampleID-1;
    historySampleIdVec          = historyStartSampleId:historyEndSampleId;
    historyDiscreteTVec         = (historySampleIdVec-1)*tSample;
    updatedHistorySampleIdVec   = historyStartSampleId:endSampleID;
    updatedHistoryDiscreteTVec  = (updatedHistorySampleIdVec-1)*tSample;
    
    cfgStruct.dynamics.segmentId           = segmentId;
    cfgStruct.dynamics.startSampleID       = startSampleID;
    cfgStruct.dynamics.endSampleID         = endSampleID;
    cfgStruct.dynamics.segmentDiscreteTVec = segmentDiscreteTVec;
    
    segment_objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT = ...
        cellfun(@(timeVec) timeVec(startSampleID:endSampleID), ...
        objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT, ...
        'UniformOutput',false);
    
    segment_objectSensor_crossUplinkGenerationTimeVec_CELL_MAT = ...
        cellfun(@(timeVec) timeVec(startSampleID:endSampleID), ...
        objectSensor_crossUplinkGenerationTimeVec_CELL_MAT, ...
        'UniformOutput',false);
    
    %% simulate the sythetic sync signal arriving to the objects
    
    if syncSig_twoFreqEnable
        segment_objectsSensorCrossRx_syncSig_CELL_MAT = ...
            cellfun(...
            @(txSensorId,uplinkGenerationTime) ...
            [...
            cfgStruct.physical.f_syncSig_singleFreq1(uplinkGenerationTime) ...
            cfgStruct.physical.f_syncSig_singleFreq2(uplinkGenerationTime) ...
            zeros(length(uplinkGenerationTime), nChannels-2) ...
            ], ...
            sensorId_CELL_MAT,...
            segment_objectSensor_crossUplinkGenerationTimeVec_CELL_MAT, ...
            'UniformOutput',false ...
            );
    else
        segment_objectsSensorCrossRx_syncSig_CELL_MAT = ...
            cellfun(...
            @(txSensorId,uplinkGenerationTime) ...
            [...
            cfgStruct.physical.f_syncSig(uplinkGenerationTime) ...
            zeros(length(uplinkGenerationTime), nChannels-1) ...
            ], ...
            sensorId_CELL_MAT,...
            segment_objectSensor_crossUplinkGenerationTimeVec_CELL_MAT, ...
            'UniformOutput',false ...
            );
    end
    
    segment_objectsRx_syncSig_CELL_objVEC = ...
        cellfun(...
        @(objId) ...
        sum(cat(3,segment_objectsSensorCrossRx_syncSig_CELL_MAT{:,objId}),3), ...
        num2cell(1:nObjects), ...
        'UniformOutput',false);
    
    segmentObjectsRx = ...
        reshape(...
        cell2mat(reshape(segment_objectsRx_syncSig_CELL_objVEC,[],1)),...
        size(objectsRx(segmentSampleIdVec,:,:)) ...
        );
    
    objectsRx(segmentSampleIdVec,:,:)   = segmentObjectsRx;
    
    if false
        %% DEBUG
        figure; plot(real(objectsRx(:,:,1)));
        close all;
    end
    
    %% simulate the sensors RX from the sync signal
    
    arrayInput_CELL_MAT_objectsTx_CELL_MAT = cellfun(...
        @(objId,downlinkGenerationTime) ...
        feval(objCfgVec{objId}.sourceSignal,downlinkGenerationTime), ...
        objId_CELL_MAT,...
        segment_objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT, ...
        'UniformOutput',false);
    
    if false
        %% DEBUG
        figure;
        plot(cell2mat(arrayInput_CELL_MAT_objectsTx_CELL_MAT));
        close all;
    end
    
    arrayInput_CELL_MAT_feedback_CELL_MAT = cellfun(...
        @(objId,downlinkGenerationTime) ...
        cfgStruct.physical.enableObjectsReflectors ...
        *...
        f_sampleSignal(...
        historyDiscreteTVec, ...signalTVec,...
        squeeze(objectsRx(historySampleIdVec,objId,:)), ...signalValues,...
        downlinkGenerationTime ...sampleTVec
        ), ...
        objId_CELL_MAT,...
        segment_objectSensor_crossDownlinkGenerationTimeVec_CELL_MAT, ...
        'UniformOutput',false);
    
    if false
        %% DEBUG
        figure;
        plot(real(cell2mat(arrayInput_CELL_MAT_feedback_CELL_MAT)));
        close all;
    end
    
    arrayInput_CELL_MAT = cellfun(...
        @(objectTxComponent,feedbackComponent) ...
        [objectTxComponent zeros(segmentSampleDuration,nChannels-1)] ...
        + ...
        feedbackComponent, ...
        arrayInput_CELL_MAT_objectsTx_CELL_MAT,...
        arrayInput_CELL_MAT_feedback_CELL_MAT, ...
        'UniformOutput',false);
    
    segment_arrayInput_CELL_sensorVEC = ...
        cellfun(...
        @(sensorId) ...
        sum(cat(3,arrayInput_CELL_MAT{:,sensorId}),3) ...
        ,num2cell(1:nSensors) ...
        ,'UniformOutput',false);
    
    segment_arrayInput = ...
        reshape(...
        cell2mat(...
        reshape(segment_arrayInput_CELL_sensorVEC,[],1)),...
        size(arrayInput(segmentSampleIdVec,:,:)) ...
        );
    
    if false
        %% DEBUG
        figure;
        plot(segment_arrayInput(:,:,1));
        close all;
    end
    
    arrayInput(segmentSampleIdVec,:,:) = segment_arrayInput;
    
    %% simulate array processor to generate the array response tx signal
    
    cfgStruct.IdealEstimation.firstObjectInitialDistance    = ...
        objectSensor_crossDistances_CELL_MAT{1,1}(1);
    [segment_arrayOutput,segment_arrayResponse]             = ...
        processor_goldenModel(segment_arrayInput,cfgStruct);
    
    arrayResponse(segmentSampleIdVec,:,:)   = segment_arrayResponse;
    arrayOutput(segmentSampleIdVec)         = segment_arrayOutput;
    
    %% update objectsRx with the new arrayResponse
    
    segment_objectsSensorCrossRx_arrayResponse_CELL_MAT = ...
        cellfun(...
        @(txSensorId,uplinkGenerationTime) ...
        f_sampleSignal(...
        updatedHistoryDiscreteTVec, ...signalTVec,...
        squeeze(arrayResponse(updatedHistorySampleIdVec,txSensorId,:)), ...signalValues,...
        uplinkGenerationTime ...sampleTVec
        ), ...
        sensorId_CELL_MAT,...
        segment_objectSensor_crossUplinkGenerationTimeVec_CELL_MAT, ...
        'UniformOutput',false ...
        );
    
    segment_objectsRx_arrayResponse_objVEC = ...
        cellfun(...
        @(objId) ...
        sum(cat(3,segment_objectsSensorCrossRx_arrayResponse_CELL_MAT{objId,:}),3), ...
        num2cell(1:nObjects), ...
        'UniformOutput',false);
    
    if false
        %% DEBUG
        figure; plot(real(objectsRx(:,:,1)));
        close all;
    end
    
    objectsRx(segmentSampleIdVec,:,:)   = ...
        objectsRx(segmentSampleIdVec,:,:) ...
        + ...
        reshape(...
        cell2mat(reshape(segment_objectsRx_arrayResponse_objVEC,[],1)),...
        size(objectsRx(segmentSampleIdVec,:,:)) ...
        );
    
    if false
        %% DEBUG
        figure; plot(real(objectsRx(:,:,1)));
        close all;
    end
end

simOutput.yOut  = arrayOutput;
simOutput.tVec  = simTVec; 
end