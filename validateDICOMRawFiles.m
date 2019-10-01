function [ success , nRuns , seriesNumbers ] = validateDICOMRawFiles( dataPath , datasetConfigs , subIdx , sesIdx , newRawDataFolder )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

success = false;
% DCMinfo = struct();
% idx_info = 1;

% -------------------------------------------------------------------------
% Find DICOM files in dataPath
% -------------------------------------------------------------------------

D = dir(fullfile(dataPath,'*.ima'));

% Check if the total number of files is incorrect
if (length(D) < sum(datasetConfigs(subIdx).sessions(sesIdx).volumes)) && (length(D) > 5)
    disp('[createFolderStructure] Fewer files than expected...');
% Maybe the files are *.dcm!
elseif (length(D) < sum(datasetConfigs(subIdx).sessions(sesIdx).volumes)) && (length(D) < 5)
    D = dir(fullfile(dataPath,'*.dcm'));
end

% Extract all file names
files = extractfield(D,'name')';
nFiles = length(files);

% -------------------------------------------------------------------------
% Check if names on files match 
% -------------------------------------------------------------------------

% Retrieve first DICOM file
firstDCMfile = dicominfo(fullfile(D(1).folder,D(1).name));

% Check if the patient given name exists. If it does, the DICOM files were
% not anonimized.
if isfield(firstDCMfile.PatientName,'GivenName')
    % Compare the name given in datasetConfigs with the GivenName+Surname
    % in the DICOM file.
    if ~strcmpi(datasetConfigs(subIdx).name,...
            [firstDCMfile.PatientName.GivenName firstDCMfile.PatientName.FamilyName])
        
        disp('[createFolderStructure] Check if files correspond to subject!')
        fprintf('Name on DCM files: %s %s\n',...
            firstDCMfile.PatientName.GivenName,firstDCMfile.PatientName.FamilyName);
        fprintf('Name provided: %s\n',datasetConfigs(subIdx).name);
        
        x = input('[createFolderStructure] Do you wish to proceed anyway (Y/N)?','s');
        switch lower(x)
            case 'y'
                disp('[createFolderStructure] Proceeding...');
            otherwise
                return
        end
    end
else % the GivenName field does not exist
    % When using an anonimization standard, the name in datasetConfigs
    % should match the PatientName.FamilyName field in the DICOM file
    if ~strcmpi(datasetConfigs(subIdx).name,firstDCMfile.PatientName.FamilyName)
        disp('[createFolderStructure] Check if files correspond to subject!')
        fprintf('Name on DCM files: %s \n',firstDCMfile.PatientName.FamilyName);
        fprintf('Name provided: %s\n',datasetConfigs(subIdx).name);
        
        x = input('[createFolderStructure] Do you wish to proceed anyway (Y/N)?','s');
        switch lower(x)
            case 'y'
                disp('[createFolderStructure] Proceeding...');
            otherwise
                return
        end
    end   
end

% -------------------------------------------------------------------------
% Extract series
% -------------------------------------------------------------------------

series = zeros(nFiles,1);

% Iterate on the files and search for the series number
% The filenames are formated as <subjectID>.<MR>.<series>.(...)
seriesSplitIdx = 3;
for ii = 1:nFiles
    auxnamesplit = strsplit(files{ii},'.');
    series(ii) = str2double(auxnamesplit{seriesSplitIdx});
    if isnan(series(ii)) % or maybe the filenames are formatted as <subjectID>.<MR>.<ICNAS_CRANIO>.<series>.(...)
        seriesSplitIdx = 4;
        series(ii) = str2double(auxnamesplit{seriesSplitIdx});
    end
end

% Find the unique series numbers
[seriesNumbers , seriesIdx] = unique(series);

% Confirm the series numbers with the information in the first DICOM file
% of each series/run
READ_HEADERS = false;

for ii = 1:length(seriesNumbers)
    file_idx = seriesIdx(ii);
    dcmInfo = dicominfo(fullfile(D(file_idx).folder,D(file_idx).name));
    if dcmInfo.SeriesNumber ~= seriesNumbers(ii)
        fprintf('[createFolderStructure] Series numbers do not match between filename and DICOM header: M1=%i M2=%i \n',...
            seriesNumbers(ii),dcmInfo.SeriesNumber);
        
        x = input('[createFolderStructure] Do you wish to read all DICOM headers (a Parallel pool will run this) (Y/N)?','s');
        switch lower(x)
            case 'y'
                READ_HEADERS = true;
                break
            otherwise
                return
        end
    end      
end

% If the user chooses to read all DICOM headers, this block will run
if READ_HEADERS
    series = zeros(nFiles,1);
    parfor ii = 1:nFiles 
        dcmInfo = dicominfo(fullfile(D(ii).folder,D(ii).name));
        series(ii) = dcmInfo.SeriesNumber;
    end
    
    % Find the unique series numbers
    seriesNumbers = unique(series);
end

% Retrieve number of files per series
seriesVolumes = hist(series,length(1:seriesNumbers(end)));
seriesVolumes = seriesVolumes(seriesVolumes~=0);

% -------------------------------------------------------------------------
% Check for incomplete runs or extra runs
% -------------------------------------------------------------------------

nRuns = length(datasetConfigs(subIdx).sessions(sesIdx).runs);

% Number of series larger than expected number of runs
if length(seriesNumbers) > nRuns
    
    % Find series with strange number of volumes
    ignoreS = seriesNumbers(ismember(seriesVolumes,datasetConfigs.volumes) == 0);
    
    % More than one anatomical
    % This is assessed using the number of volumes of the first run
    % (anatomical).
    if sum(seriesVolumes == datasetConfigs.volumes(1)) > 1
        
        boolInput = false;
        disp(['[createFolderStructure] More than one run of anatomical data detected: ' num2str(seriesNumbers(seriesVolumes == datasetConfigs.volumes(1))')])
        while ~boolInput
            x = input('Please input the ones to ignore [<series numbers>]: ','s');
            
            if ~ismember(str2num(x),seriesNumbers(seriesVolumes == datasetConfigs.volumes(1)))
                disp('!---> ERROR: Incorrect series number.');
            else
                ignoreS = [ str2num(x) ignoreS ];
                boolInput = true;
            end
        end
        
    end
        
    disp(['[createFolderStructure] Ignoring files with series number of ' num2str(ignoreS')]);
    files(ismember(series,ignoreS)) = [];
    idx_to_delete = ismember(seriesNumbers,ignoreS);
    seriesNumbers(idx_to_delete) = [];
    seriesVolumes(idx_to_delete) = [];
    
    % Still more series than expected
    if length(seriesNumbers) > nRuns
        ignoreS = [];
        boolInput = false;
        disp(['[createFolderStructure] ' num2str(length(seriesNumbers) - nRuns) ' extra series remain.']);
        while ~boolInput
            disp(['[createFolderStructure] Current series: ' mat2str(seriesNumbers) '.'])
            x = input('Please input the ones to ignore [<series numbers>]: ','s');
            
            if length(str2num(x)) > length(seriesNumbers) - nRuns
                disp(['!---> ERROR: Too many series to delete. Choose only ' length(seriesNumbers) - nRuns ]);
            elseif ~ismember(str2num(x),seriesNumbers)
                disp('!---> ERROR: Incorrect series number.');
            else
                ignoreS = [ str2num(x) ignoreS ];
                boolInput = true;
            end
        end
        disp(['[createFolderStructure] Ignoring files with series number of ' num2str(ignoreS)]);
        files(ismember(series,ignoreS)) = [];
        idx_to_delete = ismember(seriesNumbers,ignoreS);
        seriesNumbers(idx_to_delete) = [];
        seriesVolumes(idx_to_delete) = [];
    end

% Number of series smaller than expected number of runs 
elseif length(seriesNumbers) < nRuns
    disp('[createFolderStructure] !---> ERROR: Unsufficient data.')
    boolInput = false;
    while ~boolInput
        x = input('[createFolderStructure] Do you wish to proceed anyway (Y/N)?','s');
        switch lower(x)
            case 'y'
                nRuns = length(seriesNumbers);
                boolInput = true;
            otherwise
                return
        end
    end
end

% -------------------------------------------------------------------------
% Check for incorrect number of volumes in all runs
% -------------------------------------------------------------------------

if any(datasetConfigs(subIdx).sessions(sesIdx).volumes ~= seriesVolumes)
    disp('[createFolderStructure] Run volumes do not match the expected:');
    disp(['Expected:  ' num2str(datasetConfigs(subIdx).sessions(sesIdx).volumes)])
    disp(['Input:     ' num2str(seriesVolumes)]);
    
    boolInput = false;
    while ~boolInput
        x = input('[createFolderStructure] Do you wish to proceed anyway (Y/N)?','s');
        switch lower(x)
            case 'y'
                boolInput = true;
            otherwise
                return
        end
    end
end

% -------------------------------------------------------------------------
% Iterate on the runs
% -------------------------------------------------------------------------
parfor rr = 1:nRuns
    
    % Copy DICOM files of the series/run
    fprintf('Copying %s files...\n',datasetConfigs(subIdx).sessions(sesIdx).runs{rr});
    search_name = '';
    if seriesSplitIdx == 3
        search_name = [auxnamesplit{1} '.' auxnamesplit{2} '.' num2str(seriesNumbers(rr),'%.4i') '*'];
    elseif seriesSplitIdx == 4
        search_name = [auxnamesplit{1} '.' auxnamesplit{2} '.' auxnamesplit{3} '.' num2str(seriesNumbers(rr),'%.4i') '*'];
    end

    copyfile( fullfile(dataPath,search_name) , newRawDataFolder );
    
    % Extract important header information
    auxdir = dir(fullfile(newRawDataFolder,search_name));
    
%     if strcmp(datasetConfigs(subIdx).sessions(sesIdx).runtypes{rr},'func')
%         dcmHeader = dicominfo(fullfile(auxdir(1).folder,auxdir(1).name));
%         DCMinfo(idx_info).sliceTimes = dcmHeader.Private_0019_1029;
%         DCMinfo(idx_info).sliceNumber = length(DCMinfo(idx_info).sliceTimes);
%         [~,DCMinfo(idx_info).sliceVector] = sort(DCMinfo(idx_info).sliceTimes);
%         DCMinfo(idx_info).TR = dcmHeader.RepetitionTime / 1000;
%         DCMinfo(idx_info).TA = DCMinfo(idx_info).TR-(DCMinfo(idx_info).TR/DCMinfo(idx_info).sliceNumber);
%         DCMinfo(idx_info).RefSlice = DCMinfo(idx_info).sliceVector(1);
%         DCMinfo(idx_info).EchoTime = dcmHeader.EchoTime / 1000;
%         
%         idx_info = idx_info + 1;
%     end
    
    % Renonimize (necessary due to inconsistent series info on the header)
    disp('Re-anonimizing...')
    values = struct();
    values.StudyInstanceUID = dicomuid;
    values.SeriesInstanceUID = dicomuid;
    values.PatientName = datasetConfigs(subIdx).name;
    
    for p = 1:numel(auxdir)
       	dicomanon(fullfile(auxdir(p).folder,auxdir(p).name), ...
                  fullfile(newRawDataFolder, sprintf('%s-%04d-%s-%04d.dcm', datasetConfigs(subIdx).name, seriesNumbers(rr), datasetConfigs(subIdx).sessions(sesIdx).runs{rr}, p)) , ...
                  'update', values, ...
                  'WritePrivate',true);
        
        delete(fullfile(auxdir(p).folder,auxdir(p).name));
    end
      
end

% save(fullfile(subFolder,'DCMinfo.mat'),'DCMinfo');

success = true;
% disp('[createFolderStructure] Folder structure creation completed.')

end
