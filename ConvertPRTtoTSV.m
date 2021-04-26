%% Create TSV from PRT

%% Input the prt file
[prt_file,prt_path] = uigetfile('*.prt');
if isequal(prt_file,0)
    disp('User selected Cancel');
else
    disp(['User selected ', fullfile(prt_path,prt_file)]);
end

%% Provide useful data
TR = 0.5; %in seconds
prt_name = 'AA';
subjectID_s = 'sub-01';

%% Start

[ cond_names , intervalsPRT ,~,~,~, blockDur, blockNum ] = readProtocol( fullfile(prt_path,[prt_file(1:end-4) '.prt']) , TR );

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
export_file = fullfile(prt_path,...
    sprintf('%s_task-%s_run-%02i_events.txt',subjectID_s,prt_name,1));

writetable(T,export_file,'Delimiter','\t');
movefile(export_file,[export_file(1:end-4) '.tsv']);

