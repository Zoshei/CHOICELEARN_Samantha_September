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

HARDWARE.LogLabel = 'ExpType'; 
% will be used to generate subfolders for dfferent log types

%% USING A WRAPPER RUN-FILE =============================================
WRAPPER.GetSubjectFromWrapper = true;
% when set to true, get the subject nfor from the wrapper script as WLOG

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

%% STIMULUS INFO ========================================================
% NB! For positions, note that shifting rightwards and downwards are 
% are positive and we define relative to the center of the screen.
% [0 0] is center
% [-5 -5] is left of and above the center
% [ 5  5] is right of and below the center

% stimuli will be bitmap images 
STIM.bitmapdir = 'images';

% define response keys
STIM.Key1 = '1!';
STIM.Key2 = '0)';

% image size
STIM.imgsz = [3 3];

% read in folders and pick first picture
% Define paths to subfolders
relevant_dir = fullfile(STIM.bitmapdir, 'relevant');
redundant_dir = fullfile(STIM.bitmapdir, 'redundant');
distractor_dir = STIM.bitmapdir; % Assuming distractors are in the main directory

% Load relevant images in blocks
relevant_files = dir(fullfile(relevant_dir, '*.bmp'));
relevant_blocks = reshape({relevant_files.name}, 5, [])';

% Load redundant images in blocks
redundant_files = dir(fullfile(redundant_dir, '*.bmp'));
redundant_blocks = reshape({redundant_files.name}, 5, [])';

% Initialize STIM.img
STIM.img = struct();

% Organize relevant images into blocks
for block_num = 1:size(relevant_blocks, 1)
    for img_num = 1:size(relevant_blocks, 2)
        idx = (block_num - 1) * size(relevant_blocks, 2) + img_num;
        STIM.img(idx).fn = fullfile('relevant', relevant_blocks{block_num, img_num});
        STIM.img(idx).type = 'relevant';
        STIM.img(idx).block = block_num;
        STIM.img(idx).correctresp = 1; % define correct response as needed
    end
end

% Organize redundant images into blocks
for block_num = 1:size(redundant_blocks, 1)
    for img_num = 1:size(redundant_blocks, 2)
        idx = length(relevant_files) + (block_num - 1) * size(redundant_blocks, 2) + img_num;
        STIM.img(idx).fn = fullfile('redundant', redundant_blocks{block_num, img_num});
        STIM.img(idx).type = 'redundant';
        STIM.img(idx).block = block_num;
        STIM.img(idx).correctresp = 1; % define correct response as needed
    
        % Add debug statement to verify correct response setting
        disp(['Setting correctresp for redundant image: ', STIM.img(idx).fn, ' Block: ', num2str(block_num), ' CorrectResp: ', num2str(STIM.img(idx).correctresp)]);
    end
end

% Load distractor images
distractor_files = dir(fullfile(distractor_dir, '*.bmp'));

% Exclude files that are in Relevant or Redundant folders
distractor_files = distractor_files(~ismember({distractor_files.name}, {relevant_files.name, redundant_files.name}));
for i = 1:length(distractor_files)
    STIM.img(i + length(relevant_files) + length(redundant_files)).fn = distractor_files(i).name;
    STIM.img(i + length(relevant_files) + length(redundant_files)).type = 'distractor';
    STIM.img(i + length(relevant_files) + length(redundant_files)).correctresp = 'undefined';
%     STIM.img(i + length(relevant_files) + length(redundant_files)).points = 0;
end


%% CUE INFO =============================================================
% line pointing left or right
STIM.cue(1).type = 'line';
STIM.cue(1).dir = [-1 0]; % directional vector (x,y] 'left';
STIM.cue(1).color = [1 0 0]; % RGB
STIM.cue(1).sz = [0.05 0.5]; % [width length] dva
STIM.cue(1).pos = [-0.75 0]; % [H V] dva relative to fix

STIM.cue(2).type = 'line';
STIM.cue(2).dir = [1 0]; % directional vector (x,y] 'left';
STIM.cue(2).color = [1 0 0]; % RGB
STIM.cue(2).sz = [0.05 0.5]; % [width length] dva
STIM.cue(2).pos = [0.75 0]; % [H V] dva relative to fix

%% EXPERIMENT STRUCTURE =================================================
% in each trial there should alway be:
% cue side: 1 image with response association, one without  
% uncued side: 1 image with same response association, one without 
% all should have same reward

% Timing of trial (in ms)
STIM.Times.Fix = 500;
STIM.Times.Cue = [0 Inf]; % ms after fix [start stop] 
STIM.Times.Stim = [0 Inf]; % ms after fix [start stop]
STIM.Times.Feedback = 2000;
STIM.Times.ITI = 500; % ms after response or stim stop
% if stop is Inf, it's until response

STIM.RequireFixToStart = false; % this can be useful to ensure fixation, but
% make sure the Eyelink works well enough to not make this frustrating
STIM.Fix.WindowRadius = 1.5; % dva
STIM.MaxDurFixCheck = 60;
STIM.RequireContFix = false;

% TRIALS ----------------
% can be any number of images as long there's a position defined for all of
% them
STIM.Trials.trial(1).images = [ ...
    1,...
    5,...
    13,...
    9 ...
    ] ; 
STIM.Trials.trial(1).imgpos = [...
    -5  5;...
    -5 -5;...
     5  5;...
     5 -5 ...
     ]; % [H V] dva relative to fix  

STIM.Trials.trial(1).cue = 1; % leave empty for no cue
STIM.Trials.trial(1).targ = 1; % the img index that is the target
%--
STIM.Trials.trial(2)=STIM.Trials.trial(1);
STIM.Trials.trial(2).images = [ ...
    10,...
    14,...
    6,...
    2....
    ] ; 
STIM.Trials.trial(2).imgpos = [...
    -5  5;...
    -5 -5;...
     5  5;...
     5 -5 ...
     ]; % [H V] dva relative to fix  
STIM.Trials.trial(2).cue = 2; % leave empty for no cue
STIM.Trials.trial(2).targ = 4; % the img index that is the target

% -------
STIM.Trials.Blocked = true;
% if blocked
STIM.Trials.TrialsInBlocks = [... % each line defines a block
    1.*ones(1,10);...
    %2.*ones(1,10);...
    ]; % 
STIM.Trials.RandomBlocks = true;
STIM.Trials.RandomTrials = true; % also applies to non-blocked
STIM.Trials.BlockRepeats = 5;
% if not blocked
STIM.Trials.TrialsInExp = [1 2];
STIM.Trials.TrialsRepeats = 5;

%% FEEDBACK =============================================================
% Feedback?
STIM.PerformanceFeedback = true;
STIM.UseSoundFeedback = true;

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

% give performance feedback occasionally
STIM.Feedback.PerfShow = true;
STIM.Feedback.PerfOverLastNTrials = 5;
STIM.Feedback.PerfShowEveryNTrials = 5;
STIM.Feedback.PerfLevels = {...
    50, 'Apprentice';...
    70, 'Warrior';...
    90, 'Champion';...
    100, 'Wizard'};