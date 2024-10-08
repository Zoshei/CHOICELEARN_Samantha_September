%% Hardware variables ===================================================
% Some definitions to specify hardware specifics
HARDWARE.Location = 'NIN_PsychoPhys';

% This switch allows expansion to multiple locations
% -- check these parameters carefully --
switch HARDWARE.Location
    case 'NIN_PsychoPhys'
        % Participant distance from screen (mm)
        HARDWARE.DistFromScreen = 570;
        % Gamma correction
        HARDWARE.DoGammaCorrection = false;
        HARDWARE.GammaCorrection = 1;
end

% Execute eyelink specific code
HARDWARE.EyelinkConnected = false; % boolean
HARDWARE.EyelinkCalibrate = true; % boolean
HARDWARE.MeasureFixEveryNthTrials = 20; % Only works WITH eyelink
% To be sure about eye-tracking accuracy we can use repeated calibration

HARDWARE.LogLabel = 'LatentLearnRedundant'; % change this!
% will be used to generate subfolders for dfferent log types

%% USING A WRAPPER RUN-FILE =============================================
WRAPPER.GetSubjectFromWrapper = true;
% when set to true, get the subject info from the wrapper script as WLOG

%% BACKGROUND & FIXATION ================================================
% Background color
STIM.BackColor = [0.5 0.5 0.5]; % [R G B] range: 0-1

% Fixation size (in deg vis angle)
STIM.Fix.Size = .3;

% Fixation color
STIM.Fix.Color = [0 0 0]; % [R G B] range: 0-1

% Instruction text
STIM.WelcomeText = ['Choose the 1 or 0 key for the cued image\n\n'...
                    '>> Press any key to start <<'];

%% IMAGE-SERIES INFO ====================================================
% put these in a separate file to avoid inconsistencies between 
% CLL_run and CLL_run_red
CLL_morphseries; % run this file

%% STIMULUS INFO ========================================================
% NB! For positions, note that shifting rightwards and downwards are 
% are positive and we define relative to the center of the screen.
% [0 0] is center
% [-5 -5] is left of and above the center
% [ 5  5] is right of and below the center

% stimuli will be bitmap images 
STIM.imagedir = 'images';

% define response keys
STIM.Key1 = '1!';
STIM.Key2 = '0)';

% image size
STIM.imgsz = [3 3];

%% STIMULUS TRIAL TYPES =================================================
%NB this section can be replaced by:
% config_red_xxx; for preconfigured settings

% image positions in polar coordinates
STIM.Template.imgpos.r = 0;
STIM.Template.imgpos.angle = 0; % 1 positions on a circle
% start at 3 o'clock go ccw

STIM.TrialType(1).morphseries_idx = 1;
STIM.TrialType(1).morphposition = 1;
STIM.TrialType(1).imgtype = 'relevant'; % only here for logging purposes
STIM.TrialType(1).correctresponse = 1;
% make sure this is correct

STIM.TrialType(2).morphseries_idx = 1;
STIM.TrialType(2).morphposition = 10;
STIM.TrialType(2).imgtype = 'relevant'; % 
STIM.TrialType(2).correctresponse = 1;

STIM.TrialType(3).morphseries_idx = 2;
STIM.TrialType(3).morphposition = 1;
STIM.TrialType(3).imgtype = 'redundant'; % 
STIM.TrialType(3).correctresponse = 1;

STIM.TrialType(4).morphseries_idx = 2;
STIM.TrialType(4).morphposition = 10;
STIM.TrialType(4).imgtype = 'redundant'; % 
STIM.TrialType(4).correctresponse = 1;

STIM.Trials.TrialsInExp = 1:4; % trial types

%% EXPERIMENT STRUCTURE =================================================
% in each trial there should alway be:
% cue side: 1 image with response association, one without  
% uncued side: 1 image with same response association, one without 
% all should have same reward

% Timing of trial (in ms)
STIM.Times.Fix = 500;
STIM.Times.Stim = [0 Inf]; % ms after fix [start stop]
STIM.Times.Feedback = 1000;
STIM.Times.ITI = 500; % ms after response or stim stop
% if stop is Inf, it's until response

STIM.RequireFixToStart = false; % this can be useful to ensure fixation, but
% make sure the Eyelink works well enough to not make this frustrating
STIM.Fix.WindowRadius = 1.5; % dva
STIM.MaxDurFixCheck = 60;
STIM.RequireContFix = false;

% TRIALS ----------------
STIM.Trials.RandomTrials = true; % also applies to non-blocked
STIM.Trials.InterMixed = true; % mix morphseries
STIM.Trials.norep = true; % if true no repeating of same trials (when mixed)
STIM.Trials.PerformanceThreshold = [5 5]; 
% [x y] x out of the last y trials for this trialtype have to be correct 
% to go to the next step 
STIM.Trials.MaxNumTrials = 1000; 
% the exp will run untill all series have transfered performance to the 
% other end of the morph series or for this number of trials 

%% FEEDBACK =============================================================
% Feedback?
STIM.PerformanceFeedback = false;
STIM.UseSoundFeedback = false;

% where are the sounds 
STIM.snddir = 'snd';

% Vertical location and size of center feedback text
STIM.Feedback.TextY = 0; %pix
STIM.Feedback.TextSize = 20; %pix
STIM.Feedback.NeutralCol = [0 0 0];

STIM.Feedback.TextCorrect = 'CORRECT';
STIM.Feedback.TextCorrectCol = [0 0.2 0];
STIM.Feedback.SoundCorrect = {'correct0.wav','correct.wav'}; %{low high}

STIM.Feedback.TextWrong = 'WRONG';
STIM.Feedback.TextWrongCol = [0.2 0 0];
STIM.Feedback.SoundWrong = 'wrong.wav';

%% Saving the data ======================================================
% here you can remove the actual images from the log to save space
STIM.RemoveImagesFromLog = true;