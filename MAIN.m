

% https://github.com/xiangruili/dicm2nii
% http://bids.neuroimaging.io/

% Pipeline
% 1) Receive folder with dicom files and info about the order of the
% series/runs
% 2) Convert all files to .nii.gz and .json, anonimizing if necessary
% 3) [Optional] Read PRTs and convert them to .tsv
% 4) Organize into folders according to BIDS standard


%% Add dicm2nii to path
dicm2nii_folder = 'C:\Users\alexandresayal\Documents\MATLAB\dicm2nii';
addpath(dicm2nii_folder);

%% Inputs

% -- Load configuration file
load('Configs_VP_Hysteresis_PAPER_TAL.mat')

% -- Subject
subjectName = 'InesBernardino';
subjectIndex = find(not(cellfun('isempty', strfind(datasetConfigs.subjects, subjectName))));

% -- Indicate folder with raw data from subject
raw_folder = 'F:\RAW_DATA_VP_HYSTERESIS\InesBernardino\INESB';
prt_folder = 'F:\RAW_DATA_VP_HYSTERESIS\PRTs_BIDS';

% -- Retrieve run sequence, volumes and prt's
runs = datasetConfigs.runs{subjectIndex};
volumes = datasetConfigs.volumes{subjectIndex};
prtPrefix = datasetConfigs.prtPrefix{subjectIndex};
nRuns = length(runs);

% -- [CUSTOM] Manually change the name of the runs
runs2 = {'anatomical','loc1','control4','control3','control2','control1',...
    'hyst4','hyst3','hyst2','hyst1'};

% -- Define usefull stuff
subjectID = subjectIndex;
subjectID_s = sprintf('sub-%02i',subjectID);
sessionID = 1;
sessionID_s = sprintf('ses-%02i',sessionID);

%% Create main BIDS directory
BIDS_folder = 'E:\DATA_Hysteresis_BIDS';
if exist(BIDS_folder,'dir') ~= 7
    mkdir(BIDS_folder);
    mkdir(BIDS_folder,'temp');
end

%% Create subject folder
subject_folder = fullfile(BIDS_folder,subjectID_s);
if exist(subject_folder,'dir') ~= 7
    mkdir(fullfile(subject_folder,sessionID_s,'anat'));
    mkdir(fullfile(subject_folder,sessionID_s,'func'));
else
    disp('Folder already exists.')
end

%% Perform DCM to NII transformation
temp_folder = fullfile(BIDS_folder,'temp');
dicm2nii(raw_folder, temp_folder, 1);

%% Iterate on the runs, rename, move to BIDS
for rr = 1:nRuns
    
    if rr == 1 % anatomical
        movefile(fullfile(temp_folder,'MPRAGE_p2_1mm_iso.json'),...
            fullfile(subject_folder,sessionID_s,'anat',sprintf('%s_%s_T1w.json',subjectID_s,sessionID_s)))
        movefile(fullfile(temp_folder,'MPRAGE_p2_1mm_iso.nii.gz'),...
            fullfile(subject_folder,sessionID_s,'anat',sprintf('%s_%s_T1w.nii.gz',subjectID_s,sessionID_s)))
    elseif rr == 2 % localizer
        movefile(fullfile(temp_folder,'localizer_128.json'),...
            fullfile(subject_folder,sessionID_s,'func',sprintf('%s_%s_task-loc_run-%02i_bold.json',subjectID_s,sessionID_s,1)))
        movefile(fullfile(temp_folder,'localizer_128.nii.gz'),...
            fullfile(subject_folder,sessionID_s,'func',sprintf('%s_%s_task-loc_run-%02i_bold.nii.gz',subjectID_s,sessionID_s,1)))
    else % functional
        movefile(fullfile(temp_folder,[runs{rr} '.json']),...
            fullfile(subject_folder,sessionID_s,'func',sprintf('%s_%s_task-%s_run-%02i_bold.json',subjectID_s,sessionID_s,runs2{rr}(1:end-1),str2double(runs2{rr}(end)))))
        movefile(fullfile(temp_folder,[runs{rr} '.nii.gz']),...
            fullfile(subject_folder,sessionID_s,'func',sprintf('%s_%s_task-%s_run-%02i_bold.nii.gz',subjectID_s,sessionID_s,runs2{rr}(1:end-1),str2double(runs2{rr}(end)))))
    end
end

%% Create TSV from PRT
TR = 1.5; %in seconds
for rr = 1:nRuns-1
    [ cond_names , intervalsPRT ,~,~,~, blockDur, blockNum ] = readProtocol( prt_folder , prtPrefix{rr} , TR );
    
    Condition = {};
    Onset = [];
    Duration = [];
    for cc = 1:length(cond_names)
        Condition = [Condition ; repmat({cond_names(cc)},blockNum(cc),1)];
        Onset = [Onset ; intervalsPRT.(cond_names{cc})(:,1).*TR];
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





