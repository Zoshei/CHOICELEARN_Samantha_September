function CL_RunExp
% this is a wrapper script allowing the experimenter to run multiple
% experiments directly in series without having to manually launch them

%% Get registration info ------------------------------------------------
WLOG.Subject = [];
WLOG.SesNr = [];
% Get subject info
while isempty(WLOG.Subject)
    INFO = inputdlg({'Subject Initials', ...
        'Gender (m/f/x)', 'Age', 'Left(L)/Right(R) handed'},...
        'Subject',1,{'XX','x','0','R'},'on');
    WLOG.Subject = INFO{1};
    WLOG.Gender = INFO{2};
    WLOG.Age = str2double(INFO{3});
    WLOG.Handedness = INFO{4};
end
WLOG.DateTimeStr = datestr(datetime('now'), 'yyyymmdd_HHMM');

%% Run the experiments --------------------------------------------------
% Run the experiment with a settings file
CL_run('settingsA',0,WLOG)

% =======================================
% do something in between (or not)

% =======================================

% Run the experiment with another settings file
CL_run('settingsB',0,WLOG)