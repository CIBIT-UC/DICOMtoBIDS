% Script to transform DICOM files into .nii and .json files in BIDS standard
% directories

% https://github.com/xiangruili/dicm2nii
% http://bids.neuroimaging.io/

% Pipeline
% 1) Receive folder with dicom files and info about the order of the
% series/runs
% 2) Convert all files to .nii.gz and .json, anonimizing if necessary
% 3) [Optional] Read PRTs and convert them to .tsv
% 4) Organize into folders according to BIDS standard

clear,clc

%% Add dicm2nii to path
dicm2nii_folder = 'C:\Users\alexandresayal\Documents\GitHub\dicm2nii';
addpath(dicm2nii_folder);

%% Load configuration file
load('inhibition-test01\Configs-InhibitionTest01.mat')

%% Create main BIDS directory
bidsFolder = 'inhibition-test01\BIDS';
if ~exist(bidsFolder,'dir')
    mkdir(bidsFolder);
    mkdir(bidsFolder,'temp');
end

%% Inputs

% -- Subject and session
subIdx = 1;
sesIdx = 1;
subName = sprintf('sub-%02i',subIdx);
sesName = sprintf('ses-%02i',sesIdx);

% -- Indicate folder with raw data from subject
rawDataFolder = 'F:\RAW_DATA_VP_INHIBITION\VPI_S01';
prtFolder = 'F:\RAW_DATA_VP_INHIBITION\PRTs_CrossInhibition';

% -- Retrieve unique run types
runTypesUnique = unique(datasetConfigs(subIdx).sessions(sesIdx).runtypes);

%% Validate input folder DICOM files and reanonimize
newRawDataFolder = 'F:\RAW_DATA_VP_INHIBITION_ANON\VPIS01';
[ success , nRuns , seriesNumbers ] = validateDICOMRawFiles( rawDataFolder , datasetConfigs , subIdx , sesIdx , newRawDataFolder );

%% Create subject folder
subFolder = fullfile(bidsFolder,subName,sesName);
if ~exist(subFolder,'dir')
    for ii = 1:length(runTypesUnique)
        mkdir(fullfile(subFolder,runTypesUnique{ii}));
    end
else
    disp('Folder already exists.')
end

%% Perform DCM to NII transformation
tempFolder = fullfile(bidsFolder,'temp');
dicm2nii(newRawDataFolder, tempFolder, 1);

tempFolderNii = dir(fullfile(tempFolder,'*.nii.gz'));
tempFolderJson = dir(fullfile(tempFolder,'*.json'));

%% Iterate on the runs, rename, move to BIDS
for rr = 1:nRuns
    runType = datasetConfigs(subIdx).sessions(sesIdx).runtypes{rr};
    runName = datasetConfigs(subIdx).sessions(sesIdx).runs{rr};
    
    switch runType
        case 'anat'
            movefile(fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name),...
                     fullfile(subFolder,'anat',sprintf('%s_%s_T1w.json',subName,sesName)))
                 
            movefile(fullfile(tempFolderNii(rr).folder,tempFolderNii(rr).name),...
                     fullfile(subFolder,'anat',sprintf('%s_%s_T1w.nii.gz',subName,sesName)))
        case 'func'
            movefile(fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name),...
                     fullfile(subFolder,'func',sprintf('%s_%s_task-%s_run-%02i_bold.json',subName,sesName,runName,1)))
                 
            movefile(fullfile(tempFolderNii(rr).folder,tempFolderNii(rr).name),...
                     fullfile(subFolder,'func',sprintf('%s_%s_task-%s_run-%02i_bold.nii.gz',subName,sesName,runName,1)))
            
        otherwise
            
    end
    
    % TODO INCOMPORATE TSV HERE
    
end

%% Create TSV from PRT
TR = 1.5; %in seconds
for rr = 1:nRuns-1
    [ cond_names , intervalsPRT ,~,~,~, blockDur, blockNum ] = readProtocol( prtFolder , prtPrefix{rr} , TR );
    
    Condition = {};
    Onset = [];
    Duration = [];
    for cc = 1:length(cond_names)
        Condition = [Condition ; repmat({cond_names(cc)},blockNum(cc),1)];
        Onset = [Onset ; intervalsPRT.(cond_names{cc})(:,1).*TR-TR];
        Duration = [Duration ; repmat(blockDur(cc).*TR,blockNum(cc),1)];
    end
    [Onset,idx] = sort(Onset);
    Condition = Condition(idx);
    Duration = Duration(idx);
    
    T = table(Condition,Onset,Duration);
    export_file = fullfile(subject_folder,sessionID_s,'func',...
        sprintf('%s_%s_task-%s_run-%02i_events.txt',subjectID_s,...
        sessionID_s,runs2{rr+1}(1:end-1),str2double(runs2{rr+1}(end))));
    writetable(T,export_file,'Delimiter','\t');
    movefile(export_file,[export_file(1:end-4) '.tsv']);
    
end





