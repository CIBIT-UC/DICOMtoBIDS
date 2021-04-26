prtFolder = 'temp-prt';

tsvFolder = 'temp-tsv';

bidsFolder = '/media/alexandresayal/DATA4TB/BIDS-VP-ADAPTCHECK';

subjectList = dir(fullfile(bidsFolder,'sub-*'));

nSubjects = length(subjectList);

taskList = {'task-loc_run-01','task-b0_run-01','task-main_run-01','task-main_run-02','task-main_run-03','task-main_run-04'};

prtList = {'Localiser','RunB0','RunB1','RunB2','RunB3','RunB4'};

TR = 1.5; % in seconds

nRuns = length(prtList);

%% Convert

for rr = 1:nRuns
    
    [ cond_names , intervalsPRT ,~,~,~, blockDur, blockNum ] = readProtocol( fullfile(prtFolder,[prtList{rr} '.prt']) , TR );
    
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
    
    export_file = fullfile(tsvFolder,...
        sprintf('task-%s_events.txt',prtList{rr}));
    
    writetable(T,export_file,'Delimiter','\t');
    movefile(export_file,[export_file(1:end-4) '.tsv']);
    
end

%% Copy to BIDS
% Iterate

for ss = 1:nSubjects
    
    
    for rr = 1:nRuns
        
        subfuncFolder = fullfile(bidsFolder,sprintf('sub-%02i',ss),'ses-01','func');
        
        tsvBIDSName = sprintf('sub-%02i_ses-01_%s_events.tsv',ss,taskList{rr});
        
        % Check if exists to replace
        if exist(fullfile(subfuncFolder,tsvBIDSName),'file')
            
            copyfile(fullfile(tsvFolder,['task-' prtList{rr} '_events.tsv']),...
                     fullfile(subfuncFolder,tsvBIDSName) )
            
        else
            warning('%s does not exist. Expected?',tsvBIDSName)
        end
        
    end
    
    fprintf('sub-%02i done! \n',ss)
       
end
