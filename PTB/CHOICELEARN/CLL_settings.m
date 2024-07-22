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

HARDWARE.LogLabel = 'LatentLearn'; % change this!
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
STIM.morphs(1).class =  {'0008', '0966'}; % Hen - Wineglass
STIM.morphs(2).class =  {'0074', '0985'}; % Spider - Daisy
STIM.morphs(3).class =  {'0096', '0637'}; % Toucan - Mailbox
STIM.morphs(4).class =  {'0104', '0604'}; % Kangaroo - Hourglass
STIM.morphs(5).class =  {'0113', '0407'}; % Snail - Ambulance
STIM.morphs(6).class =  {'0143', '0437'}; % Bird - Lighthouse
STIM.morphs(7).class =  {'0162', '0510'}; % Beagle - Container ship
STIM.morphs(8).class =  {'0281', '0817'}; % Cat - Car
STIM.morphs(9).class =  {'0294', '0577'}; % Bear - Gong
STIM.morphs(10).class = {'0309', '0448'}; % Bee - Birdhouse
STIM.morphs(11).class = {'0323', '0938'}; % Butterfly - Cauliflower
STIM.morphs(12).class = {'0363', '0821'}; % Armadillo - Bridge
STIM.morphs(13).class = {'0153', '0484'}; % White dog - Sailboat
STIM.morphs(14).class = {'0076', '0666'}; % Tarantula - Mortar and pestle
STIM.morphs(15).class = {'0001', '0470'}; % Goldfish - Candle
STIM.morphs(16).class = {'0024', '0493'}; % Owl - Closet
STIM.morphs(17).class = {'0039', '0852'}; % Iguana - Tennis ball
STIM.morphs(18).class = {'0064', '0955'}; % Snake – Jackfruit 
STIM.morphs(19).class = {'0086', '0579'}; % Bird 2 – Piano
STIM.morphs(20).class = {'0040', '0417'}; % Chameleon – Air balloon
STIM.morphs(21).class = {'0992', '0555'}; % Mushroom – Fire brigade
STIM.morphs(22).class = {'0108', '0504'}; % Anemone – Mug
STIM.morphs(23).class = {'0187', '0967'}; % Brown dog – Coffee 
STIM.morphs(24).class = {'0112', '0900'}; % Shell - Water tower

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


%% STIMULUS TRIAL TYPES =================================================
% image positions in polar coordinates
STIM.Template.imgpos.r = 5;
STIM.Template.imgpos.angle = 0:60:359; % 6 positions on a circle

STIM.TrialType(1).relevant_idx = 1; % morphseries index
STIM.TrialType(1).redundant_idx = 2; % morphseries index
STIM.TrialType(1).distractor_idx = [3,4,5,6]; % morphseries index
STIM.TrialType(1).correctresponse = 1;
STIM.TrialType(1).relevant_pos = 2; % position index
STIM.TrialType(1).redundant_pos = 5; % position index


%% relevant ----
STIM.img(1).fn = '1.bmp';
STIM.img(1).correctresp = 1; %1/2/undefined
STIM.img(1).points = 10;

STIM.img(2).fn = '2.bmp';
STIM.img(2).correctresp = 1; 
STIM.img(2).points = 0;

STIM.img(3).fn = '3.bmp';
STIM.img(3).correctresp = 2; 
STIM.img(3).points = 10;

STIM.img(4).fn = '4.bmp';
STIM.img(4).correctresp = 2; 
STIM.img(4).points = 0;

%% cued distractor ----
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

%% redundant ----
STIM.img(9).fn = '9.bmp';
STIM.img(9).correctresp = 1; 
STIM.img(9).points = 10;

STIM.img(10).fn = '10.bmp';
STIM.img(10).correctresp = 1; 
STIM.img(10).points = 0;

STIM.img(11).fn = '11.bmp';
STIM.img(11).correctresp = 2; 
STIM.img(11).points = 10;

STIM.img(12).fn = '12.bmp';
STIM.img(12).correctresp = 2; 
STIM.img(12).points = 0;

%% uncued distractor ----
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
    100, 'Wizzard'};