function [] = generateTSVfromPRT(prtName , prtFolder , TR , tsvName, tsvFolder)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[ cond_names , intervalsPRT ,~,~,~, blockDur, blockNum ] = readProtocol( fullfile(prtFolder,[prtName '.prt']) , TR );

trial_type = {};
onset = [];
duration = [];

for cc = 1:length(cond_names)
    trial_type = [trial_type ; repmat({cond_names(cc)},blockNum(cc),1)];
    onset = [onset ; intervalsPRT.(cond_names{cc})(:,1).*TR-TR];
    duration = [duration ; repmat(blockDur(cc).*TR,blockNum(cc),1)];
end

[onset,idx] = sort(onset);
trial_type = trial_type(idx);
duration = duration(idx);

T = table(onset,duration,trial_type);

writetable(T, fullfile(tsvFolder, [tsvName '.txt']), 'Delimiter','\t');

movefile(fullfile(tsvFolder, [tsvName '.txt']),...
    fullfile(tsvFolder, [tsvName '.tsv']));

end
