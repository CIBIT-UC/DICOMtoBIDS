clear,clc

addpath('/home/alexandresayal/Documents/MATLAB/jsonlab/')

%% Settings
subID = '01';

bidsFolder = '/home/alexandresayal/Desktop/BIDS-VPMB/';
rawPhysioFolder = '/media/alexandresayal/DATA_1TB/RAW_DATA_VP_MBEPI_Codev0.5/VPMBAUS01_LOGS';


%% Fetch runs and acquisition times

D1 = dir(fullfile(bidsFolder,['sub-' subID],'func','*_bold.json'));

J = struct();

for ii = 1:length(D1)
    
   aux = loadjson( fullfile(D1(ii).folder,D1(ii).name) );

   J(ii).runName = D1(ii).name(1:end-10);
   J(ii).time = aux.AcquisitionTime;
    
end

[~,index] = sortrows({J.time}.'); J = J(index); clear index; % sort by time

%% Fetch physiofiles

D2 = dir( fullfile(rawPhysioFolder,'*.log') );

% sort list anyway
[~,index] = sortrows({D2.name}.'); D2 = D2(index); clear index;

%% Copy files to BIDS directory

% check number of runs match

% copy

% convert (but how?)


