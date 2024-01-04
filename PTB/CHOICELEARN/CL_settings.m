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
HARDWARE.MeasureFixEveryNthTrials = 20; % Only works WITH eyelink
% To be sure about eye-tracking accuracy we can use repeated calibration

%% BACKGROUND & FIXATION ================================================

% Background color
STIM.BackColor = [0.5 0.5 0.5]; % [R G B] range: 0-1

% Fixation size (in deg vis angle)
STIM.Fix.Size = .3;

% Fixation color
STIM.Fix.Color = [0 0 0]; % [R G B] range: 0-1

%% STIMULUS INFO ========================================================
% stimuli will be bitmap images 
STIM.bitmapdir = 'images';

% define response keys
STIM.Key1 = '1!';
STIM.Key2 = '0)';

% relevant ----
STIM.img(1).fn = '1.bmp';
STIM.img(1).correctresp = STIM.Key1; %STIM.Key1/STIM.Key2/undefined
STIM.img(1).points = 10;

STIM.img(2).fn = '2.bmp';
STIM.img(2).correctresp = STIM.Key1; %STIM.Key1/STIM.Key2/undefined
STIM.img(2).points = 0;

STIM.img(3).fn = '3.bmp';
STIM.img(3).correctresp = STIM.Key2; %STIM.Key1/STIM.Key2/undefined
STIM.img(3).points = 10;

STIM.img(4).fn = '4.bmp';
STIM.img(4).correctresp = STIM.Key2; %STIM.Key1/STIM.Key2/undefined
STIM.img(4).points = 0;

% cued distractor ----
STIM.img(5).fn = '5.bmp';
STIM.img(5).correctresp = 'undefined';
STIM.img(5).points = 10;

STIM.img(6).fn = '6.bmp';
STIM.img(6).correctresp = 'undefined';
STIM.img(6).points = 0;

STIM.img(7).fn = '7.bmp';
STIM.img(7).correctresp = 'undefined';
STIM.img(7).points = 10;

STIM.img(8).fn = '8.bmp';
STIM.img(8).correctresp = 'undefined';
STIM.img(8).points = 0;

% redundant ----
STIM.img(9).fn = '9.bmp';
STIM.img(9).correctresp = STIM.Key1; %STIM.Key1/STIM.Key2/undefined
STIM.img(9).points = 10;

STIM.img(10).fn = '10.bmp';
STIM.img(10).correctresp = STIM.Key1; %STIM.Key1/STIM.Key2/undefined
STIM.img(10).points = 0;

STIM.img(11).fn = '11.bmp';
STIM.img(11).correctresp = STIM.Key2; %STIM.Key1/STIM.Key2/undefined
STIM.img(11).points = 10;

STIM.img(12).fn = '12.bmp';
STIM.img(12).correctresp = STIM.Key2; %STIM.Key1/STIM.Key2/undefined
STIM.img(12).points = 0;

% uncued distractor ----
STIM.img(13).fn = '13.bmp';
STIM.img(13).correctresp = 'undefined';
STIM.img(13).points = 10;

STIM.img(14).fn = '14.bmp';
STIM.img(14).correctresp = 'undefined';
STIM.img(14).points = 0;

STIM.img(15).fn = '15.bmp';
STIM.img(15).correctresp = 'undefined';
STIM.img(15).points = 10;

STIM.img(16).fn = '16.bmp';
STIM.img(16).correctresp = 'undefined';
STIM.img(16).points = 0;


% etcetera 
% in Dev's experiment there were:
% --------------------------------
% Relevant    Cued    1     10p
%                     1      0p 
%                     2     10p 
%                     2      0p 
% C Distr     Cued    1/2   10p
%                     1/2    0p 
%                     1/2   10p 
%                     1/2    0p 
% Redundant   NoCue   1     10p
%                     1      0p 
%                     2     10p 
%                     2      0p 
% NC Distr    NoCue   1/2   10p
%                     1/2    0p 
%                     1/2   10p 
%                     1/2    0p 


%% CUE INFO =============================================================
% line pointing left or right
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
STIM.FixWindowRadius = 1.5; % dva
STIM.MaxDurFixCheck = 60;

% TRIALS ----------------
STIM.Trials.imgpos =  [...
    -5  5;...
    -5 -5;...
     5  5;...
     5 -5 ...
     ]; % [H V] dva relative to fix 
STIM.Trials.imgsz = [4 4]; % [H V] dva

% |-----------|
% | 1       3 |
% |    FIX    |
% | 2       4 |
% |-----------|

STIM.Trials.trial(1).images = [ 1, 5, 13, 9 ] ; % order matters!
STIM.Trials.trial(1).cue = 1;
STIM.Trials.trial(1).targ = 1; % the img index that is the target

STIM.Trials.trial(2).images = [ 10, 14, 6, 2 ] ; % order matters!
STIM.Trials.trial(2).cue = 2;
STIM.Trials.trial(2).targ = 4; % the img index that is the target

% -------
STIM.Trials.Blocked = true;
% if blocked
STIM.Trials.TrialsInBlocks = [... % each line defines a block
    1.*ones(1,10);...
    2.*ones(1,10);...
    ]; % 
STIM.Trials.RandomBlocks = true;
STIM.Trials.RandomTrials = true; % also applies to non-blocked
STIM.Trials.BlockRepeats = 5;
% if not blocked
STIM.Trials.TrialsInExp = [1,2];
STIM.Trials.TrialsRepeats = 5;

%% FEEDBACK =============================================================
% Feedback?
STIM.PerformanceFeedback = true;

% where are the sounds 
STIM.snddir = 'snd';

% Vertical location and size of center feedback text
STIM.Feedback.TextY = 0; %pix
STIM.Feedback.TextSize = 20; %pix
STIM.Feedback.TextCorrect = 'CORRECT response!';
STIM.Feedback.TextCorrectCol = [0 0 0];
STIM.Feedback.SoundCorrect = {'correct0.wav','correct.wav'}; %{low high}

STIM.Feedback.TextWrong = 'WRONG response!';
STIM.Feedback.TextWrongCol = [0 0 0];
STIM.Feedback.SoundWrong = 'wrong.wav';

STIM.Feedback.PerformanceLevel = true;