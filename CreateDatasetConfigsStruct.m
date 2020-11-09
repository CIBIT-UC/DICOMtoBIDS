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
subIdx = 1;

datasetConfigs(subIdx).name = 'P01';
datasetConfigs(subIdx).age = -99;
datasetConfigs(subIdx).gender = 'X';
datasetConfigs(subIdx).laterality = -99;
datasetConfigs(subIdx).eyetracker = 1;

datasetConfigs(subIdx).sessions(1).volumes = [192 51 51 1 10 1 480 51 51 1 10 1 570 51 51 1 10 1 570 51 51 1 10 1 570 51 51 1 10 1 570];
datasetConfigs(subIdx).sessions(1).runtypes = {'anat','fmap-mg','fmap-ph','fmap-pa-sbref','fmap-pa','sbref','func','fmap-mg','fmap-ph','fmap-pa-sbref','fmap-pa','sbref','func','fmap-mg','fmap-ph','fmap-pa-sbref','fmap-pa','sbref','func','fmap-mg','fmap-ph','fmap-pa-sbref','fmap-pa','sbref','func','fmap-mg','fmap-ph','fmap-pa-sbref','fmap-pa','sbref','func'}; %anat,func,fmap-mg,fmap-ph,fmap-pa,dti,dti-b0
datasetConfigs(subIdx).sessions(1).runs = {'t1w','rest','run1','run2','run3','run4'};
datasetConfigs(subIdx).sessions(1).tr = [2530 1000 1000 1000 1000 1000] / 1000; % in seconds

% datasetConfigs(subIdx).sessions(2).volumes = [176 128 300 300];
% datasetConfigs(subIdx).sessions(2).runtypes = {'anat','func','func','func'};
% datasetConfigs(subIdx).sessions(2).runs = {'t1w','loc','run2','run1'};
% datasetConfigs(subIdx).sessions(2).tr = [2760 1000 1000 1000 1000 1000 1000];

%% Save and backup
save(fullfile(fileDir,fileName),'datasetConfigs')

save(fullfile(backupDir,[fileName(1:end-4) '-' datestr(now,'ddmmyyyy-HHMMSS') '.mat']),'datasetConfigs')
