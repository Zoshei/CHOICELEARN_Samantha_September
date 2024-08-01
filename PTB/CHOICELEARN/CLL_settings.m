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
STIM.morphs(18).class = {'0094', '0955'}; % Snake – Jackfruit 
STIM.morphs(19).class = {'0086', '0579'}; % Bird 2 – Piano
STIM.morphs(20).class = {'0040', '0417'}; % Chameleon – Air balloon
STIM.morphs(21).class = {'0992', '0555'}; % Mushroom – Fire brigade
STIM.morphs(22).class = {'0108', '0504'}; % Anemone – Mug
STIM.morphs(23).class = {'0187', '0967'}; % Brown dog – Coffee 
STIM.morphs(24).class = {'0112', '0900'}; % Shell - Water tower

STIM.morphimgs = 0:10;

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
% image positions in polar coordinates
STIM.Template.imgpos.r = 5;
STIM.Template.imgpos.angle = 0:60:359; % 6 positions on a circle
% start at 3 o'clock go ccw

STIM.TrialType(1).relevant_idx = 1; % morphseries index
STIM.TrialType(1).redundant_idx = 2; % morphseries index
STIM.TrialType(1).correctresponse = 1;
STIM.TrialType(1).relevant_pos = 2; % position index
STIM.TrialType(1).redundant_pos = 5; % position index
STIM.TrialType(1).distractor_pos = [1,3,4,6];

STIM.TrialType(2).relevant_idx = 3; % morphseries index
STIM.TrialType(2).redundant_idx = 4; % morphseries index
STIM.TrialType(2).correctresponse = 2;
STIM.TrialType(2).relevant_pos = 2; % position index
STIM.TrialType(2).redundant_pos = 5; % position index
STIM.TrialType(2).distractor_pos = [1,3,4,6];

STIM.TrialType(3).relevant_idx = 5; % morphseries index
STIM.TrialType(3).redundant_idx = 6; % morphseries index
STIM.TrialType(3).correctresponse = 1;
STIM.TrialType(3).relevant_pos = 3; % position index
STIM.TrialType(3).redundant_pos = 6; % position index
STIM.TrialType(3).distractor_pos = [1,2,4,5];

STIM.TrialType(4).relevant_idx = 7; % morphseries index
STIM.TrialType(4).redundant_idx = 8; % morphseries index
STIM.TrialType(4).correctresponse = 2;
STIM.TrialType(4).relevant_pos = 3; % position index
STIM.TrialType(4).redundant_pos = 6; % position index
STIM.TrialType(4).distractor_pos = [1,2,4,5];

STIM.Template.distractor_idx = 9:24;


% %% CUE INFO =============================================================
% % line pointing left or right
STIM.cue.color = [1 0 0]; % RGB
STIM.cue.sz = [0.05 0.5]; % [width length] dva
STIM.cue.pos = 0.5; % dva from center of fixation point

%% EXPERIMENT STRUCTURE =================================================
% in each trial there should alway be:
% cue side: 1 image with response association, one without  
% uncued side: 1 image with same response association, one without 
% all should have same reward

% Timing of trial (in ms)
STIM.Times.Fix = 500;
STIM.Times.Cue = [0 Inf]; % ms after fix [start stop] 
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
STIM.Trials.TrialsInExp = 1:4; % trial types
STIM.Trials.PerformanceThreshold = [100 100]; 
% [x y] x out of the last y trials for this trialtype have to be correct 
% to go to the next step 
STIM.Trials.MaxNumTrials = 20; 
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