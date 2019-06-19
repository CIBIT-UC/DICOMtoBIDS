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

%% Add dicm2nii and json to path
dicm2niiFolder = 'C:\Users\alexandresayal\Documents\GitHub\dicm2nii';
addpath(dicm2niiFolder);

jsontoolboxFolder = 'C:\Users\alexandresayal\Documents\GitHub\jsonlab';
addpath(jsontoolboxFolder)

%% Load configuration file
load('inhibition-test01\Configs-InhibitionTest02.mat')

%% Create main BIDS directory
bidsFolder = 'C:\Users\alexandresayal\Documents\GitHub\DICOMtoBIDS\inhibition-test01\BIDS';
if ~exist(bidsFolder,'dir')
    mkdir(bidsFolder);
    mkdir(bidsFolder,'temp');
end

%% Inputs

% -- Subject and session
subIdx = 1;
sesIdx = 1;

% -- Indicate folder with raw data from subject
rawDataFolder = 'F:\RAW_DATA_VP_INHIBITION\VPI_S02';
prtFolder = 'F:\RAW_DATA_VP_INHIBITION\PRTs_CrossInhibition';

% -- Folder for reanonimzed DICOM files after validation
newRawDataFolder = 'F:\RAW_DATA_VP_INHIBITION_ANON\VPIS02';

%% Stuff
subName = sprintf('sub-%02i',subIdx);
sesName = sprintf('ses-%02i',sesIdx);

% -- Retrieve unique run types
runTypesUnique = unique(datasetConfigs(subIdx).sessions(sesIdx).runtypes);

%% Validate input folder DICOM files and reanonimize
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

% movefile(fullfile(tempFolder,'dcmHeaders.mat'), fullfile(subFolder,'dcmHeaders.mat'))

%% Iterate on the runs, rename, move to BIDS
for rr = 1:nRuns
    runType = datasetConfigs(subIdx).sessions(sesIdx).runtypes{rr};
    runName = datasetConfigs(subIdx).sessions(sesIdx).runs{rr};
    
    switch runType
        case 'anat'
            movefile(fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name),...
                     fullfile(subFolder,'anat',sprintf('%s_%s_T1w.json',subName,sesName)))
            
            % Deface image with SPM
            niiFile = gunzip(fullfile(tempFolderNii(rr).folder,tempFolderNii(rr).name));
            niiFile_deface = spm_deface(niiFile);
            niiFile_deface_gz = gzip(niiFile_deface);
            
            movefile(niiFile_deface_gz{1},...
                     fullfile(subFolder,'anat',sprintf('%s_%s_T1w.nii.gz',subName,sesName)))
        case 'func'
            
            % Add info to JSON
            jsonData = loadjson(fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name));
            jsonData.TaskName = runName;
            savejson('',jsonData,fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name));
            
            movefile(fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name),...
                     fullfile(subFolder,'func',sprintf('%s_%s_task-%s_run-%02i_bold.json',subName,sesName,runName,1)))
                 
            movefile(fullfile(tempFolderNii(rr).folder,tempFolderNii(rr).name),...
                     fullfile(subFolder,'func',sprintf('%s_%s_task-%s_run-%02i_bold.nii.gz',subName,sesName,runName,1)))
                             
            generateTSVfromPRT(runName , prtFolder , ...
                datasetConfigs(subIdx).sessions(sesIdx).tr(rr) , ...
                sprintf('%s_%s_task-%s_run-%02i_events',subName,sesName,runName,1),...
                fullfile(subFolder,'func'));
            
        otherwise
            disp('meh')
    end
    
end

%%
disp('Done!')

