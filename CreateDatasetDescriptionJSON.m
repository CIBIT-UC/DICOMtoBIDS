jsontoolboxpath = 'C:\Users\alexandresayal\Documents\GitHub\jsonlab';
addpath(jsontoolboxpath)

SDATA = struct();

SDATA.Name = 'VP-Inhibition-BIDS';
SDATA.BIDSVersion = '1.2.0';
SDATA.Licence = '';
SDATA.Authors = {'Alexandre Sayal','Teresa Sousa','Joao Duarte','Gabriel Costa','Miguel Castelo-Branco'};
SDATA.Acknowledgments = '';
SDATA.HowToAcknowledge = '';
SDATA.Funding = '';
SDATA.ReferencesAndLinks = {''};
SDATA.DatasetDOI = '';

% jsonStr = jsonencode(S);

% fid = fopen('dataset_description.json', 'w');
% if fid == -1, error('Cannot create JSON file'); end
% fwrite(fid, jsonStr, 'char');
% fclose(fid);

savejson('', SDATA, 'dataset_description.json')

