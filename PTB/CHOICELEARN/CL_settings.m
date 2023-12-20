%% Hardware variables =====================================================
% Some definitions to specify hardware specifics
HARDWARE.Location = 'NIN_PsychoPhys';

% This switch allows expansion to multiple locations
switch HARDWARE.Location
    case 'NIN_PsychoPhys'
        % Participant distance from screen (mm)
        HARDWARE.DistFromScreen = 570;
        % Gamma correction
        HARDWARE.DoGammaCorrection = false;
        HARDWARE.GammaCorrection = 1;
end
% Execute eyelink specific code
HARDWARE.EyelinkConnected = true; % boolean
HARDWARE.MeasureFixEveryNthTrials = 20; % Only works WITH eyelink
% To be sure about eye-tracking accuracy we can use repeated calibration

%% BACKGROUND & FIXATION ==================================================

% Background color
STIM.BackColor = [0.5 0.5 0.5]; % [R G B] range: 0-1

% Fixation size (in deg vis angle)
STIM.Fix.Size = .3;

% Fixation color
STIM.Fix.Color = [0 0 0]; % [R G B] range: 0-1

%% STIMULUS INFO ==========================================================
% stimuli will be bitmap images 
STIM.bitmapdir = 'images';

STIM.nPicsInMemory = 50; % we'll dynamically load images, keeping only this 
% many in memory at the same time so that things run smoothly.
if Stm.nPicsInMemory > (Stm.pics_end - Stm.pics_start)+1
    Stm.nPicsInMemory = (Stm.pics_end - Stm.pics_start)+1;
end

STIM.img(1).fn = '1.bmp';
STIM.img(1).pos = [-5 5]; % [H V] dva relative to fix
STIM.img(1).sz = [4 4]; % [H V] dva
STIM.img(1).correctresp = 'left'; %left/right/undefined

STIM.img(2).fn = '2.bmp';
STIM.img(2).pos = [5 5]; % [H V] dva relative to fix
STIM.img(2).sz = [4 4]; % [H V] dva
STIM.img(2).correctresp = 'undefined';

STIM.img(3).fn = '3.bmp';
STIM.img(3).pos = [-5 -5]; % [H V] dva relative to fix
STIM.img(3).sz = [4 4]; % [H V] dva
STIM.img(3).correctresp = 'right';

STIM.img(4).fn = '4.bmp';
STIM.img(4).pos = [5 -5]; % [H V] dva relative to fix
STIM.img(4).sz = [4 4]; % [H V] dva
STIM.img(4).correctresp = 'undefined';

% etcetera


%% CUE INFO ===============================================================
% triangle pointing left or right
STIM.cue(1).type = 'line';
STIM.cue(1).dir = 'left';
STIM.cue(1).color = [1 0 0]; % RGB
STIM.cue(1).sz = [0.5 0.05]; % [H V] dva
STIM.cue(1).pos = [-0.75 0]; % [H V] dva relative to fix

STIM.cue(2).type = 'line';
STIM.cue(2).dir = 'right';
STIM.cue(2).color = [1 0 0]; % RGB
STIM.cue(2).sz = [0.5 0.05]; % [H V] dva
STIM.cue(2).pos = [0.75 0]; % [H V] dva relative to fix

%% EXPERIMENT STRUCTURE ===================================================
% in each trial there should alway be:
% cue side: 1 image with response association, one without
% cue side: 1 image with response association, one without

% Timing of trial FIX-STIM-FEEDBACK (in ms)
% 0 in STIM phase is not read, instead 'until response'
STIM.Timing = [500 0 1000];
STIM.RequireFixToStart= false; % this can be useful to ensure fixation, but
% make sure the Eyelink works well enough to not make this frustrating

STIM.Trials.trial(1).images = [1,2,3,4]; % indexes to STIM.img()
STIM.Trials.trial(1).cue = 1;

STIM.Trials.trial(2).images = [1,2,3,4]; % indexes to STIM.img()
STIM.Trials.trial(2).cue = 2;

% etc

STIM.Trials.Blocked = true;
% if blocked
STIM.Trials.TrialsInBlocks = [...
    1,1,1,1,1,1,1,1,1,1;...
    2,2,2,2,2,2,2,2,2,2;...
    ]; % 
STIM.Trials.RandomBlocks = true;
STIM.Trials.RandomTrials = true; % also applies to non-blocked
STIM.Trials.BlockRepeats = 5;
% if not blocked
STIM.Trials.TrialsInExp = [...
    1,2,1,2];
STIM.Trials.TrialsRepeats = 5;


%% FEEDBACK ===============================================================
% Feedback?
STIM.PerformanceFeedback = true;

% Vertical location and size of center feedback text
STIM.Feedback.TextY = 0; %pix
STIM.Feedback.TextSize = 20; %pix
STIM.Feedback.TextCorrect = 'That is the CORRECT response!';
STIM.Feedback.TextCorrectCol = [0 0 1];
STIM.Feedback.TextWrong = 'That is the WRONG response!';
STIM.Feedback.TextWrongCol = [1 0 0];

