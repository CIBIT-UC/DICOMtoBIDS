% Create and edit a datasetConfigs file.
% CIBIT 2019

%% Create new or import dataset
disp('DatasetConfigs Script v0.1')
x = input('Create New file (N) or Edit existing (E) ? ', 's');

switch lower(x)
    case 'n' % new file
       fileDir = uigetdir(pwd,'Select Folder for file');
       fileName = input('New file name (with .mat): ', 's');
       
       % Make/load backup folder
       backupDir = fullfile(fileDir,'backupmats');
       if ~exist(backupDir,'dir')
           mkdir(backupDir);
       end
       
       % Initialize structure
       datasetConfigs = struct(); 
       
    case 'e' % existing file
       [fileName,fileDir] = uigetfile('*.mat','Select datasetConfigs file');
       backupDir = fullfile(fileDir,'backupmats');
        
       load(fullfile(fileDir,fileName));
       
    otherwise % user is dumb
        disp('Invalid option.')
        return
end

%% Overide previous section for quick adding of subs to existing file
% fileDir = 'C:\Users\alexandresayal\Documents\GitHub\DICOMtoBIDS\testdatasets';
% fileName = 'Configs-Test01.mat';
% backupDir = fullfile(fileDir,'backupmats');
% load(fullfile(fileDir,fileName));

%% Select subject-idx and remaining fields
subIdx = 2;

datasetConfigs(subIdx).name = 'VPIS02';
datasetConfigs(subIdx).age = 22;
datasetConfigs(subIdx).gender = 'F';
datasetConfigs(subIdx).laterality = 75;
datasetConfigs(subIdx).eyetracker = 0;

datasetConfigs(subIdx).sessions(1).volumes = [176 374 374 374 374 374 374];
datasetConfigs(subIdx).sessions(1).runtypes = {'anat','func','func','func','func','func','func'};
datasetConfigs(subIdx).sessions(1).runs = {'t1w','run1','run2','run3','run4','run5','run6'};
datasetConfigs(subIdx).sessions(1).tr = [2530 1000 1000 1000 1000 1000 1000] / 1000; % in seconds

% datasetConfigs(subIdx).sessions(2).volumes = [176 128 300 300];
% datasetConfigs(subIdx).sessions(2).runtypes = {'anat','func','func','func'};
% datasetConfigs(subIdx).sessions(2).runs = {'t1w','loc','run2','run1'};
% datasetConfigs(subIdx).sessions(2).tr = [2760 1000 1000 1000 1000 1000 1000];

%% Save and backup
save(fullfile(fileDir,fileName),'datasetConfigs')

save(fullfile(backupDir,[fileName(1:end-4) '-' datestr(now,'ddmmyyyy-HHMMSS') '.mat']),'datasetConfigs')
