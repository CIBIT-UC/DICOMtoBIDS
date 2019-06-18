function [] = generateTSVfromPRT(prtName , prtFolder , TR , tsvName, tsvFolder)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[ cond_names , intervalsPRT ,~,~,~, blockDur, blockNum ] = readProtocol( fullfile(prtFolder,[prtName '.prt']) , TR );

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

writetable(T,fullfile(tsvFolder, [tsvName '.txt']),'Delimiter','\t');

movefile(fullfile(tsvFolder, [tsvName '.txt']),...
    fullfile(tsvFolder, [tsvName '.tsv']));

end
