% Script to transform DICOM files into .nii and .json files in BIDS standard
% directories
%
% Requirements:
% https://github.com/xiangruili/dicm2nii
% https://github.com/fangq/jsonlab
% https://github.com/neuroelf/neuroelf-matlab
%
% Docs:
% http://bids.neuroimaging.io/
% https://bids-specification.readthedocs.io

% Pipeline
% 1) Receive folder with dicom files and info about the order of the
% series/runs
% 2) Convert all files to .nii.gz and .json, anonimizing if necessary
% 3) [Optional] Read PRTs and convert them to .tsv
% 4) Organize into folders according to BIDS standard
%
% CIBIT 2019
%
% TODO
% - fieldmap, dti, PA sequences compatibility
%

clear,clc

%% Add toolboxes to path
dicm2niiFolder = '/home/alexandresayal/Documents/MATLAB/dicm2nii';
addpath(dicm2niiFolder);

jsontoolboxFolder = '/home/alexandresayal/Documents/MATLAB/jsonlab';
addpath(jsontoolboxFolder)

spmFolder = '/home/alexandresayal/Documents/MATLAB/spm12';
addpath(spmFolder)

%% Load configuration file
%load('Configs-VP-Inhibition.mat')
load('Configs-EDPilots.mat')

%% Create main BIDS directory
bidsFolder = '/media/alexandresayal/DATA4TB/BIDS-EDPILOTS';
if ~exist(bidsFolder,'dir')
    mkdir(bidsFolder);
    mkdir(bidsFolder,'derivatives');
    mkdir(bidsFolder,'sourcedata');
end

%% Inputs

% -- Subject and session
subIdx = 1;
sesIdx = 1;

% -- Indicate folder with raw data from subject
rawDataFolder = '/home/alexandresayal/Desktop/ED_PILOT01';
prtFolder = '/home/alexandresayal/Desktop/edpilots-prt';

% -- Folder for reanonimzed DICOM files after validation
newRawDataFolder = '/home/alexandresayal/Desktop/ED_PILOT01_ANON';

%% Stuff
subName = sprintf('sub-%02i',subIdx);
sesName = sprintf('ses-%02i',sesIdx);

% -- Retrieve unique run types (anat, func, ...)
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
tempFolder = fullfile(subFolder,'temp');

dicm2nii(newRawDataFolder, tempFolder, 1);

tempFolderNii = dir(fullfile(tempFolder,'*.nii.gz')); % Not a particularly ideal implementation, but for now it will do. Reminder to always check if the order of the runs is okay in the DIR struct.
tempFolderJson = dir(fullfile(tempFolder,'*.json'));

% movefile(fullfile(tempFolder,'dcmHeaders.mat'), fullfile(subFolder,'dcmHeaders.mat'))

%% Iterate on the runs, rename, move to BIDS
funcRunsIdx = 1; % counter for the functional runs of a task

for rr = 1:nRuns
    runType = datasetConfigs(subIdx).sessions(sesIdx).runtypes{rr};
    runName = datasetConfigs(subIdx).sessions(sesIdx).runs{rr};
    
    % CUSTOM - OVERRIDE runName
    newrunName = 'main';
    
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
            jsonData.TaskName = newrunName;
            savejson('',jsonData,fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name));
            
            movefile(fullfile(tempFolderJson(rr).folder,tempFolderJson(rr).name),...
                     fullfile(subFolder,'func',sprintf('%s_%s_task-%s_run-%02i_bold.json',subName,sesName,newrunName,funcRunsIdx)))
                 
            movefile(fullfile(tempFolderNii(rr).folder,tempFolderNii(rr).name),...
                     fullfile(subFolder,'func',sprintf('%s_%s_task-%s_run-%02i_bold.nii.gz',subName,sesName,newrunName,funcRunsIdx)))
                             
            generateTSVfromPRT(runName , prtFolder , ...
                datasetConfigs(subIdx).sessions(sesIdx).tr(rr) , ...
                sprintf('%s_%s_task-%s_run-%02i_events',subName,sesName,newrunName,funcRunsIdx),...
                fullfile(subFolder,'func'));
            
            funcRunsIdx = funcRunsIdx + 1;
            
        case 'sbref'
            
        case 'fmap-mg'
            
        case 'fmap-ph'
            
        case 'fmap-pa'
            
        case 'dti'
            
        case 'dti-b0'
            
        otherwise
            disp('meh')
    end
    
end

rmdir(tempFolder,'s')

%%
disp('Done!')

