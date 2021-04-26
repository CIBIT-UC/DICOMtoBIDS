%% this is an example with a short calibration recording

% the same data is converted multiple times to demonstrate the directory layout and the participants

cfg = [];

cfg.InstitutionName             = 'CIBIT';
cfg.InstitutionalDepartmentName = 'CIBIT';
cfg.InstitutionAddress          = '';

% required for dataset_description.json
cfg.dataset_description.Name        = 'VP-MB';
cfg.dataset_description.BIDSVersion = '1.4.1';

% optional for dataset_description.json
cfg.dataset_description.License             = 'n/a';
cfg.dataset_description.Authors             = 'n/a';
cfg.dataset_description.Acknowledgements    = 'n/a';
cfg.dataset_description.Funding             = 'n/a';
cfg.dataset_description.ReferencesAndLinks  = 'n/a';
cfg.dataset_description.DatasetDOI          = 'n/a';

cfg.method    = 'convert'; % the eyelink-specific format is not supported, convert it to plain TSV
cfg.dataset   = '/media/alexandresayal/DATA_1TB/RAW_DATA_VP_MBEPI_Codev0.5/VPMBAUS01_EYETRACKER/TS001435.asc';
cfg.bidsroot  = './bids';  % write to the working directory
cfg.datatype  = 'eyetracker';
cfg.task      = 'loc';

% this is general metadata that ends up in the _eyetracker.json file
cfg.TaskDescription       = 'Eyetracker data for localizer run';
cfg.Manufacturer          = 'SR Research';
cfg.ManufacturerModelName = 'Eyelink 1000';

% convert the data from the first (and only one) subject
cfg.sub = '01';
cfg.participants.age = 99;
cfg.participants.sex = 'P';
data2bids(cfg);
