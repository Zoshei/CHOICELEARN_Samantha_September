function CL_run_iconlearn(SettingsFile,Debug,WLOG)

%% PTB3 script for ======================================================
% CHOICE_LEARNING experiment
% Questions: c.klink@nin.knaw.nl

% Response: choose one of two keys (learn cue-response)

% In short:
% - A fixation dot is presented
% - A number of stimuli are presented with an attention cue
% - In the reponse phase, subjects say A or B
% - Feedback can be provided on whether this was correct
% - Blockwise chunking of stimulus sets is possible
%==========================================================================
dbstop if error
clc; QuitScript = false;

if nargin < 3
    WLOG = [];
    if nargin < 2
        Debug = false;
        if nargin < 1
            SettingsFile = 'CL_settings_iconlearn';
        end
    end
end
warning off; %#ok<*WNOFF>
DebugRect = [0 0 1024 768];

%% Read in variables ----------------------------------------------------
% First get the settings
[RunPath,~,~] = fileparts(mfilename('fullpath'));
run(fullfile(RunPath,SettingsFile));

%% Create data folder if it doesn't exist yet and go there --------------
DataFolder = 'CL_data';
StartFolder = pwd;
[~,~] = mkdir(fullfile(StartFolder,DataFolder));

%% Run the experiment ---------------------------------------------------
% try
%% Initialize & Calculate Stimuli -----------------------------------
if Debug
    LOG.Subject = 'TEST';
    LOG.Gender = 'x';
    LOG.Age = 0;
    LOG.Handedness = 'R';
    LOG.DateTimeStr = datestr(datetime('now'), 'yyyyMMdd_HHmm'); %#ok<*DATST>
else
    % Get registration info
    LOG.Subject = [];
    % Get subject info
    if WRAPPER.GetSubjectFromWrapper && ~isempty(WLOG)
        LOG.Subject = WLOG.Subject;
        LOG.Gender =WLOG.Gender;
        LOG.Age = WLOG.Age;
        LOG.Handedness = WLOG.Handedness;
        % Get timestring id
        LOG.DateTimeStr = WLOG.DateTimeStr;
    else
        while isempty(LOG.Subject)
            INFO = inputdlg({'Subject Initials', ...
                'Gender (m/f/x)', 'Age', 'Left(L)/Right(R) handed'},...
                'Subject',1,{'XX','x','0','R'},'on');
            LOG.Subject = INFO{1};
            LOG.Gender = INFO{2};
            LOG.Age = str2double(INFO{3});
            LOG.Handedness = INFO{4};
            % Get timestring id
            LOG.DateTimeStr = datestr(datetime('now'), 'yyyymmdd_HHMM');
        end
    end

end

if HARDWARE.EyelinkConnected %#ok<*USENS>
    % Try to initialize EYELINK (if fails exit)
    fprintf('Initializing EYELINK...')
    if EyelinkInit() ~= 1 % PTB-3 function
        fprintf('FAILED\n');
        return;
    else
        fprintf('OK\n');
    end
end

% Reduce PTB3 verbosity
oldLevel = Screen('Preference', 'Verbosity', 0); %#ok<*NASGU>
Screen('Preference', 'VisualDebuglevel', 0);
Screen('Preference','SkipSyncTests',1);

%Do some basic initializing
AssertOpenGL;
KbName('UnifyKeyNames');
%HideCursor;

%Define response keys
Key1 = KbName(STIM.Key1); %#ok<*NODEF>
Key2 = KbName(STIM.Key2);
KeyFix = KbName('space');

if ~IsLinux
    KeyBreak = KbName('Escape');
else
    KeyBreak = KbName('ESCAPE');
end
%ListenChar(2);

% Open a double-buffered window on screen
if Debug
    % for CK desktop linux; take one screen only
    WindowRect = DebugRect; %debug
else
    WindowRect = []; %fullscreen
end

ScrNrs = Screen('screens');
HARDWARE.ScrNr = max(ScrNrs);

% Get some basic color intensities
HARDWARE.white = WhiteIndex(HARDWARE.ScrNr);
HARDWARE.black = BlackIndex(HARDWARE.ScrNr);
HARDWARE.grey = (HARDWARE.white+HARDWARE.black)/2;

[HARDWARE.window, HARDWARE.windowRect] = ...
    Screen('OpenWindow',HARDWARE.ScrNr,...
    STIM.BackColor*HARDWARE.white,WindowRect,[],2);

if HARDWARE.EyelinkConnected
    [HARDWARE.windowEL, HARDWARE.windowRect] = ...
        Screen('OpenWindow',HARDWARE.ScrNr,...
        STIM.BackColor*HARDWARE.white,WindowRect,[],2);
end

HARDWARE.Center = ...
    [HARDWARE.windowRect(3)/2 HARDWARE.windowRect(4)/2];

% Define blend function for anti-aliassing
[sourceFactorOld, destinationFactorOld, colorMaskOld] = ...
    Screen('BlendFunction', HARDWARE.window, ...
    GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Initialize text options
Screen('Textfont',HARDWARE.window,'Arial');
Screen('TextSize',HARDWARE.window,16);
Screen('TextStyle',HARDWARE.window,0);

% Maximum useable priorityLevel on this system:
priorityLevel = MaxPriority(HARDWARE.window);
Priority(priorityLevel);

% Get the refreshrate
HARDWARE.FrameDur = Screen('GetFlipInterval',HARDWARE.window);

% Get the screen size in pixels
[HARDWARE.PixWidth, HARDWARE.PixHeight] = ...
    Screen('WindowSize',HARDWARE.ScrNr);
% Get the screen size in mm
[HARDWARE.MmWidth, HARDWARE.MmHeight] = ...
    Screen('DisplaySize',HARDWARE.ScrNr);


% Define conversion factors
HARDWARE.Mm2Pix=HARDWARE.PixWidth/HARDWARE.MmWidth;
HARDWARE.Deg2Pix=(tand(1)*HARDWARE.DistFromScreen)*...
    HARDWARE.PixWidth/HARDWARE.MmWidth;

% Gamma Correction to allow intensity in fractions
if HARDWARE.DoGammaCorrection
    [OLD_Gamtable, dacbits, reallutsize] = ...
        Screen('ReadNormalizedGammaTable', HARDWARE.ScrNr);
    GamCor = (0:1/255:1).^HARDWARE.GammaCorrection;
    Gamtable = [GamCor;GamCor;GamCor]';
    Screen('LoadNormalizedGammaTable',HARDWARE.ScrNr, Gamtable);
end

% Determine color of on screen text and feedback
% depends on background color --> Black or white
if max(STIM.BackColor) > .5
    STIM.TextIntensity = HARDWARE.black;
else
    STIM.TextIntensity = HARDWARE.white;
end


%% Prepare stimuli --------------------------------------------------
% Generate a trial list ---
LOG.TrialList = [];
% nextpics=0;
if STIM.Trials.Blocked
    for r = 1:STIM.Trials.BlockRepeats
        % block order
        if STIM.Trials.RandomBlocks
            blockorder = randperm(size(STIM.Trials.TrialsInBlocks,1));
        else
            blockorder  = 1:size(STIM.Trials.TrialsInBlocks,1);
        end

        for b = blockorder
            if STIM.Trials.RandomTrials
                trialorder = randperm(size(STIM.Trials.TrialsInBlocks,2));
            else
                trialorder = 1:size(STIM.Trials.TrialsInBlocks,2);
            end
            LOG.TrialList = [LOG.TrialList;...
                STIM.Trials.TrialsInBlocks(b,trialorder)' ...
                ones(length(trialorder),1).*b ...
                ones(length(trialorder),1).*r];
        end
    end
else
    for r=1:STIM.Trials.TrialsRepeats
        if STIM.Trials.RandomTrials
            trialorder = randperm(size(STIM.Trials.TrialsInExp,2));
        else
            trialorder = 1:size(STIM.Trials.TrialsInExp,2);
        end
        LOG.TrialList = [LOG.TrialList;...
            STIM.Trials.TrialsInExp(1,trialorder)' ...
            ones(length(trialorder),1).*1 ...
            ones(length(trialorder),1).*r];
    end
end

%% Initialize counters for block accuracy
current_relevant_index = 1; % Start from the beginning of relevant images
current_redundant_index = length(relevant_files) + 1; % Start from the beginning of the redundant images
correct_responses_in_block = 0;
trials_in_block = 0;
nextpics = 0; % Initialize nextpics variable

% Preload the initial relevant and redundant images
STIM.img(current_relevant_index).img = imread(fullfile(STIM.bitmapdir, STIM.img(current_relevant_index).fn));
STIM.img(current_relevant_index).tex = Screen('MakeTexture', HARDWARE.window, STIM.img(current_relevant_index).img);
STIM.img(current_redundant_index).img = imread(fullfile(STIM.bitmapdir, STIM.img(current_redundant_index).fn));
STIM.img(current_redundant_index).tex = Screen('MakeTexture', HARDWARE.window, STIM.img(current_redundant_index).img);

% DEBUG: Add initial disp statements
disp(['Initial relevant image: ', STIM.img(current_relevant_index).fn]);
disp(['Initial redundant image: ', STIM.img(current_redundant_index).fn]);

% Preload all images (relevant, redundant, and distractors)
for i = 1:length(STIM.img)
    if ~isempty(STIM.img(i).fn)
        STIM.img(i).img = imread(fullfile(STIM.bitmapdir, STIM.img(i).fn));
        STIM.img(i).tex = Screen('MakeTexture', HARDWARE.window, STIM.img(i).img);
        % Add debug statement to verify preloading
        disp(['Preloading image: ' STIM.img(i).fn]);
    end
end

disp(['Loading redundant image: ', STIM.img(current_redundant_index).fn]);
STIM.img(current_redundant_index).img = imread(fullfile(STIM.bitmapdir, STIM.img(current_redundant_index).fn));
STIM.img(current_redundant_index).tex = Screen('MakeTexture', HARDWARE.window, STIM.img(current_redundant_index).img);

% Define the possible positions (in degrees visual angle, dva)
num_images = 6;  % Total number of images per trial
circle_radius = 5;
angles = linspace(0, 2*pi, num_images + 1);
angles(end) = []; % Remove the last angle to avoid overlap
positions = [circle_radius * cos(angles)' circle_radius * sin(angles)'];

for trial_num = 1:length(LOG.TrialList)
    % Use the current relevant and redundant images
    relevant_index = current_relevant_index;
    redundant_index = current_redundant_index; %start of redundant files

    % DEBUG: Print relevant and redundant image paths for the current trial
    %     disp(['Trial ', num2str(trial_num), ': Relevant image: ' STIM.img(relevant_index).fn]);
    %     disp(['Trial ', num2str(trial_num), ': Redundant image: ' STIM.img(redundant_index).fn]);

    % Randomize the order of distractors
    distractor_indices = randperm(length(distractor_files), num_images - 2);

    % DEBUG: Print distractor image paths
    %     for d = 1:length(distractor_indices)
    %         disp(['Trial ', num2str(trial_num), ': Distractor image: ' STIM.img(length(relevant_files) + length(redundant_files) + distractor_indices(d)).fn]);
    %     end

    % Combine relevant, redundant, and distractors
    images = [relevant_index, redundant_index, ...
        distractor_indices + length(relevant_files) + length(redundant_files)];

    % DEBUG: Print the images being used for this trial
    %     disp(['Trial ', num2str(trial_num), ': Relevant = ', STIM.img(relevant_index).fn, ...
    %           ', Redundant = ', STIM.img(redundant_index).fn, ...
    %           ', Distractors = ', strjoin({STIM.img(distractor_indices + length(relevant_files) + length(redundant_files)).fn}, ', ')]);

    % Randomize the positions
    randomized_positions = positions(randperm(num_images), :);

    STIM.Trials.trial(trial_num).images = images;
    STIM.Trials.trial(trial_num).imgpos = randomized_positions;

    % Set relevant image as target
    STIM.Trials.trial(trial_num).targ = 1;  % relevant image is the first one in the list

    % Define the cue (assuming a fixed cue for simplicity)
    STIM.Trials.trial(trial_num).cue = 1; % Adjust as needed
end

uniquetrials = unique(LOG.TrialList(:,1));
allimages = [];
for ut = uniquetrials'
    allimages = [allimages, STIM.Trials.trial(ut).images]; %#ok<*AGROW>
end
uniqueimages = unique(allimages);

% pre-allocate variable for all possible images
% for i = 1: length(STIM.img)
%     STIM.img(i).img = [];
%     STIM.img(i).tex = [];
% end

% load the ones we need
for ui = uniqueimages
    STIM.img(ui).img = imread(fullfile(STIM.bitmapdir,STIM.img(ui).fn));
    STIM.img(ui).tex = Screen('MakeTexture',HARDWARE.window,STIM.img(ui).img);
end

% load the sounds we need
[curpath, name, ext] = fileparts(mfilename('fullpath'));
[snd(1).wav,snd(1).fs] = audioread(fullfile(curpath,STIM.snddir,...
    STIM.Feedback.SoundCorrect{1}));
[snd(2).wav,snd(2).fs] = audioread(fullfile(curpath,STIM.snddir,...
    STIM.Feedback.SoundCorrect{2}));
[snd(3).wav,snd(3).fs] = audioread(fullfile(curpath,STIM.snddir,...
    STIM.Feedback.SoundWrong));

% Create filename ---
LOG.FileName = [LOG.Subject '_' LOG.DateTimeStr];

% Create the fixation dot area
FixRect = CenterRectOnPoint([0 0 ...
    STIM.Fix.Size*HARDWARE.Deg2Pix ...
    STIM.Fix.Size*HARDWARE.Deg2Pix ],...
    HARDWARE.Center(1),HARDWARE.Center(2));
FixWinRect = CenterRectOnPoint([0 0 ...
    2*STIM.Fix.WindowRadius*HARDWARE.Deg2Pix ...
    2*STIM.Fix.WindowRadius*HARDWARE.Deg2Pix], ...
    HARDWARE.Center(1),HARDWARE.Center(2));

% Initiate the side-cues
for c = 1:length(STIM.cue)
    x1 = round(HARDWARE.Center(1) + ...
        (STIM.cue(c).pos(1)-STIM.cue(c).sz(1)/2)*HARDWARE.Deg2Pix);
    x2 = round(HARDWARE.Center(1) + ...
        (STIM.cue(c).pos(1)+STIM.cue(c).sz(1)/2)*HARDWARE.Deg2Pix);
    y1 = round(HARDWARE.Center(2) + ...
        (STIM.cue(c).pos(2)-STIM.cue(c).sz(2)/2)*HARDWARE.Deg2Pix);
    y2 = round(HARDWARE.Center(2) + ...
        (STIM.cue(c).pos(2)+STIM.cue(c).sz(2)/2)*HARDWARE.Deg2Pix);
    STIM.cue(c).rect = [x1,y1,x2,y2];
end

%% Run the Experiment
%% Calibrate EYELINK ------------------------------------------------
if HARDWARE.EyelinkConnected
    % open file to record data to
    [~,~] = mkdir(fullfile(StartFolder,DataFolder,...
        HARDWARE.LogLabel,'Eyelink_Log'));
    EL.edfFile = 'TempEL'; %NB! Name cannot be more than 8 digits long
    cd(fullfile(StartFolder, DataFolder))
    Eyelink('Openfile',EL.edfFile);
    EL.el = EyelinkInitDefaults(HARDWARE.windowEL);
    EL.el.backgroundcolour = STIM.BackColor*HARDWARE.white;
    EL.el.foregroundcolour = HARDWARE.black;

    % Calibrate the eye tracker
    if HARDWARE.EyelinkCalibrate
        EyelinkDoTrackerSetup(EL.el); % control further from eyelink pc
        % do a final check of calibration using driftcorrection
        %EyelinkDoDriftCorrection(EL.el);
    end

    %% Initialize ---------------------------------------------------
    % start recording eye position
    Eyelink('StartRecording');
    % record a few samples before we actually start displaying
    WaitSecs(0.1);
    % mark zero-plot time in data file
    Eyelink('Message', 'SYNCTIME');
    EL.eye_used = -1;
    Eyelink('Message', LOG.FileName);
    Screen('Close', HARDWARE.windowEL);
    cd(StartFolder);
end

%% Run the trials
CorrResp = [];
for TR = 1:size(LOG.TrialList,1)
    if QuitScript
        break;
    else
        KeyWasDown = false;
    end

    % Trial-start to Eyelink
    if HARDWARE.EyelinkConnected
        pause(0.1) % send some samples to edf file
        %send message to EDF file
        edfstring=['StartTrial_' num2str(TR)];
        Eyelink('Message', edfstring);
    end

    if ~QuitScript
        vbl = Screen('Flip', HARDWARE.window);
        %%% HERE: REMEASURE FIX-POINT ======
        if HARDWARE.EyelinkConnected
            GoodCenter = false;
            nFails = 0;
            InstrText = 'Please fixate & press space';
            % Check if necessary (1 & Nth)
            if TR == 1 || ~mod(TR,HARDWARE.MeasureFixEveryNthTrials)
                while ~GoodCenter
                    % Check key-press
                    [keyIsDown,secs,keyCode] = KbCheck; %#ok<*ASGLU>
                    if keyIsDown
                        if keyCode(KeyBreak) %break when esc
                            QuitScript = true; break;
                        elseif keyCode(KeyFix)
                            % Get eye-coordinates if spacebar
                            if Eyelink('NewFloatSampleAvailable') > 0
                                evt = Eyelink('NewestFloatSample');
                                CenterFix = [evt.gx(1) evt.gy(1)];
                                % eyes can be missing
                                if evt.gx(1) < -10000 % pupil is not measured
                                    GoodCenter = false; % pupils are not at right fixation point
                                    nFails = nFails+1; % counter, calibration failed
                                    if nFails == 1 % if calibration failed, try again
                                        InstrText = 'Try again';
                                    elseif nFails >= 2
                                        InstrText = 'No eye-signal. Try again or ask for help.';
                                    end
                                else
                                    GoodCenter = true;
                                end
                            end
                        end
                        KeyIsDown = false;
                    end

                    % Draw fixdot
                    Screen('FillRect',HARDWARE.window,...
                        STIM.BackColor*HARDWARE.white);
                    Screen('FillOval', HARDWARE.window,...
                        STIM.Fix.Color.*HARDWARE.white,FixRect);
                    % Draw Fix instruction
                    DrawFormattedText(HARDWARE.window,...
                        InstrText,'center',HARDWARE.Center(2)-...
                        10*STIM.Fix.Size*HARDWARE.Deg2Pix,...
                        STIM.TextIntensity);
                    % Flip
                    vbl = Screen('Flip', HARDWARE.window);
                end
            end
            %%% ============================
        else
            CenterFix = [0,0];
        end
        LOG.Trial(TR).CenterFix = CenterFix;

        %% Fix-phase
        % First trial
        if TR == 1
            % start of the experiment
            Screen('FillRect',HARDWARE.window,...
                STIM.BackColor*HARDWARE.white);
            DrawFormattedText(HARDWARE.window,...
                STIM.WelcomeText,'center',....
                'center',STIM.TextIntensity);
            fprintf('\n>>Press key to start<<\n');
            vbl = Screen('Flip', HARDWARE.window);
            LOG.ExpOnset = vbl;

            % wait for keypress
            KbWait;while KbCheck;end

            % send message to eyelink
            if HARDWARE.EyelinkConnected
                Eyelink('Message', 'StartFix');
            end
        end
        % Draw the fixation dot
        Screen('FillRect',HARDWARE.window,...
            STIM.BackColor*HARDWARE.white);
        Screen('FillOval', HARDWARE.window,...
            STIM.Fix.Color.*HARDWARE.white,FixRect);
        vbl = Screen('Flip', HARDWARE.window);
        LOG.Trial(TR).FixOnset = vbl - LOG.ExpOnset;

        if STIM.RequireFixToStart
            FixatingNow = false; FixCheckStart = GetSecs;
            % Wait until subject fixates or a minute has passed
            while ~FixatingNow && GetSecs < (FixCheckStart + STIM.MaxDurFixCheck)
                % GET EYE POSITION
                if Eyelink('NewFloatSampleAvailable') > 0
                    evt = Eyelink('NewestFloatSample');
                    % eyepos.gx(1),eyepos.gy(1) are x ,y;
                    % eyes can be missing
                    if evt.gx(1) < -10000 % pupil is not measured
                        % 'No eye-signal. Try again or ask for help.';
                    else
                        % CHECK IF IT'S WITHIN FIX WINDOW
                        if IsInRect(evt.gx(1),evt.gy(1),FixWinRect)
                            FixatingNow = true;
                        end
                    end
                end
            end
            if ~FixatingNow
                % fixation check timed out
                QuitScript = true;
                msgbox('Fixation timed out. Check eyetracker or ask for help');
            end
        else
            % emulate fixation
            FixatingNow = true;
        end

        % Fixation phase all but first frame
        while vbl - LOG.ExpOnset < LOG.Trial(TR).FixOnset + ...
                STIM.Times.Fix/1000 && FixatingNow && ~QuitScript

            % Draw fix dot
            Screen('FillRect',HARDWARE.window,...
                STIM.BackColor*HARDWARE.white);
            Screen('FillOval', HARDWARE.window,...
                STIM.Fix.Color.*HARDWARE.white,FixRect);

            % Check fixation
            if STIM.RequireContFix
                if Eyelink('NewFloatSampleAvailable') > 0
                    evt = Eyelink('NewestFloatSample');
                    % eyepos.gx(1),eyepos.gy(1) are x ,y;
                    % eyes can be missing
                    if evt.gx(1) < -10000 % pupil is not measured
                        % 'No eye-signal. Try again or ask for help.';
                        fprintf('Eye not detected\n')
                    else
                        if IsInRect(evt.gx(1),evt.gy(1),FixWinRect)
                            FixatingNow = true;
                        else
                            FixatingNow = false;
                        end
                    end
                else
                    fprintf('No eye-samples available\n')
                end
            end

            % Flip the screen buffer and get timestamp
            vbl = Screen('Flip', HARDWARE.window);
        end


        %% Cue/Image-phase
        LOG.Trial(TR).StimPhaseOnset = vbl - LOG.ExpOnset;
        MaxDur = max([STIM.Times.Cue(2) STIM.Times.Stim(2)]);
        ResponseGiven = false;

        FirstFlipDone = false;
        CueOnLog = false;
        ImageOnLog = false;
        nl=0;
        while vbl - LOG.ExpOnset < ...
                (LOG.Trial(TR).StimPhaseOnset + MaxDur/1000) && ...
                ~ResponseGiven && FixatingNow && ~QuitScript
            % background --
            Screen('FillRect',HARDWARE.window,...
                STIM.BackColor*HARDWARE.white);

            % CUE --

            % Draw cue
            tidx = LOG.TrialList(TR,1);
            cidx = STIM.Trials.trial(tidx).cue;
            cwidth = STIM.cue(cidx).sz(1).*HARDWARE.Deg2Pix;

            if vbl - LOG.ExpOnset >= LOG.Trial(TR).StimPhaseOnset + ...
                    STIM.Times.Cue(1)/1000 && ...
                    ~isempty(STIM.Trials.trial(tidx).cue) && ...
                    ~QuitScript
            end

            veclength = STIM.cue(cidx).sz(2)*HARDWARE.Deg2Pix;
            toH = round(STIM.cue(cidx).dir(1)*veclength);
            toV = round(STIM.cue(cidx).dir(2)*veclength);

            Screen('DrawLine',HARDWARE.window,...
                STIM.cue(cidx).color.*HARDWARE.white,...
                HARDWARE.Center(1), HARDWARE.Center(2),...
                HARDWARE.Center(1)+toH, HARDWARE.Center(2)+toV,...
                cwidth);

            % DEBUG: check tidx voor trials in block
            disp(['tidx voor images', num2str(tidx)])
            %                 end

            % IMAGES --
            if vbl - LOG.ExpOnset >= LOG.Trial(TR).StimPhaseOnset + STIM.Times.Stim(1)/1000 && ~QuitScript
                % Draw stim images
                tidx = LOG.TrialList(TR, 1);
                for imgidx = 1:length(STIM.Trials.trial(tidx).images)
                    imagei = STIM.Trials.trial(tidx).images(imgidx);
                    %To shift to next image in block, now quick fix,
                    %improve later
                    %only shift for relevant and redundant pictures,
                    %not for distractors
                    if imgidx<3 % so 1 or 2 picture
                        if nextpics>0
                            imagei=imagei+nextpics;
                            if nextpics==2
                                test=1;
                            end
                        end
                    end
                    ImageRect = CenterRectOnPoint(...
                        [0 0 STIM.imgsz(1) STIM.imgsz(2)].*HARDWARE.Deg2Pix, ...
                        HARDWARE.Center(1)+STIM.Trials.trial(tidx).imgpos(imgidx, 1)*HARDWARE.Deg2Pix, ...
                        HARDWARE.Center(2)+STIM.Trials.trial(tidx).imgpos(imgidx, 2)*HARDWARE.Deg2Pix);

                    % DEBUG: check image being drawn
                    disp(['Drawing image (index): ' num2str(imagei) ' (' STIM.img(imagei).fn ')']);
                    Screen('DrawTexture', HARDWARE.window, STIM.img(imagei).tex, [], ImageRect);
                end
            end

            % FIX --
            % Draw fix dot
            Screen('FillOval', HARDWARE.window,...
                STIM.Fix.Color.*HARDWARE.white,FixRect);

            % GET RESPONSE --
            % Check for key-presses
            [keyIsDown,secs,keyCode]=KbCheck; %#ok<*ASGLU>
            if keyIsDown && ~KeyWasDown
                if keyCode(KeyBreak) %break when esc
                    %fprintf('Escape pressed\n')
                    QuitScript=1;break;
                elseif keyCode(Key1)
                    %fprintf('Key 1 pressed\n')
                    LOG.Trial(TR).Response = 'left';
                    LOG.Trial(TR).Resp = 1;
                    ResponseGiven = true;
                elseif keyCode(Key2)
                    %fprintf('Key 0 pressed\n')
                    LOG.Trial(TR).Response = 'right';
                    LOG.Trial(TR).Resp = 2;
                    ResponseGiven = true;
                end
                KeyWasDown=1;
            elseif keyIsDown && KeyWasDown
                if keyCode(KeyBreak) %break when esc
                    QuitScript=1;break;
                end
            elseif ~keyIsDown
                KeyWasDown=0;
            end

            % CHECK FIXATION --
            if STIM.RequireContFix
                if Eyelink('NewFloatSampleAvailable') > 0
                    evt = Eyelink('NewestFloatSample');
                    % eyepos.gx(1),eyepos.gy(1) are x ,y;
                    % eyes can be missing
                    if evt.gx(1) < -10000 % pupil is not measured
                        % 'No eye-signal. Try again or ask for help.';
                        fprintf('Eye not detected\n')
                    else
                        if IsInRect(evt.gx(1),evt.gy(1),FixWinRect)
                            FixatingNow = true;
                        else
                            FixatingNow = false;
                        end
                    end
                else
                    fprintf('No eye-samples available\n')
                end
            end

            % LOG --
            if ~FirstFlipDone
                % Log stim-phase onset
                LOG.Trial(TR).StimPhaseOnset = ...
                    vbl - LOG.ExpOnset;
                % send message to eyelink
                if HARDWARE.EyelinkConnected
                    Eyelink('Message', 'StartStim');
                end
                FirstFlipDone = true;
            end

            if ~CueOnLog
                % Log stim-phase onset
                LOG.Trial(TR).CueOnset = ...
                    vbl - LOG.ExpOnset;
                % send message to eyelink
                if HARDWARE.EyelinkConnected
                    Eyelink('Message', 'Cue');
                end
                CueOnLog = true;
            end

            if ~ImageOnLog
                % Log stim-phase onset
                LOG.Trial(TR).CueOnset = ...
                    vbl - LOG.ExpOnset;
                % send message to eyelink
                if HARDWARE.EyelinkConnected
                    Eyelink('Message', 'StimImg');
                end
                ImageOnLog = true;
            end

            % FLIP SCREEN --
            vbl = Screen('Flip', HARDWARE.window);
        end

        %% Feedback
if ~QuitScript
    StartFeedback = GetSecs;
    LOG.Trial(TR).FeedbackOnset = vbl - LOG.ExpOnset;

    % Check if response is correct or not
    imagei = STIM.Trials.trial(tidx).targ;
    if LOG.Trial(TR).Resp == STIM.img(imagei).correctresp
        % correct
        CorrectResponse = true;
        correct_responses_in_block = correct_responses_in_block + 1;
    else
        % wrong
        CorrectResponse = false;
    end
    
    % Debug statement to check correct response
    disp(['Trial ', num2str(TR), ': Target Image Index: ', num2str(target_image_index), ...
          ', Correct Response: ', num2str(correct_response), ', User Response: ', num2str(LOG.Trial(TR).Resp)]);
    
    LOG.Trial(TR).RespCorr = CorrectResponse;
    CorrResp = [CorrResp; CorrectResponse];
    trials_in_block = trials_in_block + 1; % Increment trial counter

    % Display feedback text --
    % Set text to be bigger
    oldTextSize = Screen('TextSize', HARDWARE.window, STIM.Feedback.TextSize(1));
    oldTextStyle = Screen('TextStyle', HARDWARE.window, 1); % bold
    % Background
    Screen('FillRect', HARDWARE.window, STIM.BackColor * HARDWARE.white);
    if CorrectResponse
        DrawFormattedText(HARDWARE.window, ...
            ['Response: ' LOG.Trial(TR).Response '\n\n' ...
            STIM.Feedback.TextCorrect], ...
            'center', 'center', ...
            STIM.Feedback.TextCorrectCol .* HARDWARE.white);
    else
        DrawFormattedText(HARDWARE.window, ...
            ['Response: ' LOG.Trial(TR).Response '\n\n' ...
            STIM.Feedback.TextWrong], ...
            'center', 'center', ...
            STIM.Feedback.TextWrongCol .* HARDWARE.white);
    end
    % Set text size back to small
    Screen('TextSize', HARDWARE.window, oldTextSize);
    Screen('TextStyle', HARDWARE.window, 0);
    vbl = Screen('Flip', HARDWARE.window);

    % Play sound --
    if STIM.UseSoundFeedback
        if CorrectResponse
            sound(snd(1).wav, snd(1).fs); % snd(2) for different correct sound
        else
            sound(snd(3).wav, snd(3).fs);
        end
    end

    % Check timing --
    while GetSecs < StartFeedback + STIM.Times.Feedback / 1000 && ...
            ~QuitScript
        % wait
    end

    %% Performance Feedback
    if STIM.Feedback.PerfShow
        if TR >= STIM.Feedback.PerfOverLastNTrials && ...
                mod(TR, STIM.Feedback.PerfShowEveryNTrials) == 0
            % Calculate performance level
            perfperc = 100 * (...
                sum(CorrResp(end - (STIM.Feedback.PerfOverLastNTrials - 1):end)) ./ ...
                STIM.Feedback.PerfOverLastNTrials);
            % Which category
            idx = find([STIM.Feedback.PerfLevels{:, 1}] >= perfperc, 1, 'first');
            perfclass = STIM.Feedback.PerfLevels{idx, 2};

            % Give as feedback
            % Set text to be bigger
            oldTextSize = Screen('TextSize', HARDWARE.window, STIM.Feedback.TextSize(1));
            oldTextStyle = Screen('TextStyle', HARDWARE.window, 1); % bold
            % Background
            Screen('FillRect', HARDWARE.window, STIM.BackColor * HARDWARE.white);

            DrawFormattedText(HARDWARE.window, ...
                [num2str(floor(perfperc)) '% correct\n\nPsychophysics ' perfclass], ...
                'center', 'center', ...
                STIM.Feedback.NeutralCol .* HARDWARE.white);

            % Set text size back to small
            Screen('TextSize', HARDWARE.window, oldTextSize);
            Screen('TextStyle', HARDWARE.window, 0);
            vbl = Screen('Flip', HARDWARE.window);
            StartPerfFB = GetSecs;

            % Check timing --
            while GetSecs < StartPerfFB + STIM.Times.Feedback / 1000 && ...
                    ~QuitScript
                % wait
            end
        end
    end
end
%         %% Feedback
%         if ~QuitScript
%             StartFeedback = GetSecs;
%             LOG.Trial(TR).FeedbackOnset = vbl - LOG.ExpOnset;
% 
%             % check if response is correct or not
%             imagei = STIM.Trials.trial(tidx).targ;
%             if LOG.Trial(TR).Resp == STIM.img(imagei).correctresp
%                 % correct
%                 CorrectResponse = true;
%                 correct_responses_in_block = correct_responses_in_block + 1;
%             else
%                 % wrong
%                 CorrectResponse = false;
%             end
% 
%             LOG.Trial(TR).RespCorr = CorrectResponse;
%             CorrResp = [CorrResp; CorrectResponse];
%             trials_in_block = trials_in_block + 1; % Increment trial counter
% 
%             imagei = STIM.Trials.trial(tidx).targ;
%             if LOG.Trial(TR).Resp == STIM.img(imagei).correctresp
%                 % correct
%                 CorrectResponse = true;
%                 % nPoints = STIM.img(imagei).points;
%             else
%                 % wrong
%                 CorrectResponse = false;
%             end
% 
%             % DEBUG: check tidx voor trials in block
%             disp(['tidx voor trials_in_block', num2str(tidx)])
% 
% 
            if trials_in_block >= 5 % Check if at least 5 trials
                nextpics=nextpics+1;
                accuracy = sum(CorrResp(end-4:end)) / 5; % Calculate accuracy over last 5 trials
                if accuracy >= 0.85
                    % DEBUG: check accuracy
                    disp('Switching images due to high accuracy.');
                    disp(['Before switch: Relevant index: ', num2str(current_relevant_index), ', Redundant index: ', num2str(current_redundant_index)]);
                    correct_responses_in_block = 0; % Reset correct response counter
                    trials_in_block = 0; % Reset trial counter
                    current_relevant_index = current_relevant_index + 1;
                    current_redundant_index = current_redundant_index + 1;

                    % Ensure the indices do not exceed the bounds of the image array
                    if current_relevant_index > length(relevant_files)
                        current_relevant_index = length(relevant_files);
                    end
                    if current_redundant_index > length(redundant_files) + length(relevant_files)
                        current_redundant_index = length(redundant_files) + length(relevant_files);
                    end

                    disp(['After switch: Relevant index: ', num2str(current_relevant_index), ', Redundant index: ', num2str(current_redundant_index)]);

                    % Preload the next images
                    disp(['Switching to next relevant image: ', STIM.img(current_relevant_index).fn]);
                    STIM.img(current_relevant_index).img = imread(fullfile(STIM.bitmapdir, STIM.img(current_relevant_index).fn));
                    STIM.img(current_relevant_index).tex = Screen('MakeTexture', HARDWARE.window, STIM.img(current_relevant_index).img);

                    disp(['Switching to next redundant image: ', STIM.img(current_redundant_index).fn]);
                    STIM.img(current_redundant_index).img = imread(fullfile(STIM.bitmapdir, STIM.img(current_redundant_index).fn));
                    STIM.img(current_redundant_index).tex = Screen('MakeTexture', HARDWARE.window, STIM.img(current_redundant_index).img);
                else
                    % DEBUG: check accuracy
                    disp('Accuracy not high enough, continuing with current images.');
                end
            end
% 
%             % display feedback text --
%             % set text to be bigger
%             oldTextSize=Screen('TextSize', HARDWARE.window,...
%                 STIM.Feedback.TextSize(1));
%             oldTextStyle=Screen('TextStyle',HARDWARE.window,1); %bold
%             % background
%             Screen('FillRect',HARDWARE.window,...
%                 STIM.BackColor*HARDWARE.white);
%             if CorrectResponse
%                 DrawFormattedText(HARDWARE.window,...
%                     ['Response: ' LOG.Trial(TR).Response '\n\n'...
%                     STIM.Feedback.TextCorrect],...
%                     'center','center',...
%                     STIM.Feedback.TextCorrectCol.*HARDWARE.white);
%             else
%                 DrawFormattedText(HARDWARE.window,...
%                     ['Response: ' LOG.Trial(TR).Response '\n\n'...
%                     STIM.Feedback.TextWrong],...
%                     'center','center',...
%                     STIM.Feedback.TextWrongCol.*HARDWARE.white);
%             end
%             
%             % Set text size back to small
%             Screen('TextSize', HARDWARE.window,oldTextSize);
%             Screen('TextStyle',HARDWARE.window,0);
%             vbl = Screen('Flip', HARDWARE.window);
% 
%             % play sound --
%             if STIM.UseSoundFeedback
%                 if CorrectResponse
%                     sound(snd(1).wav,snd(1).fs);%snd(2) for different correct sound
%                 else
%                     sound(snd(3).wav,snd(3).fs);
%                 end
%             end
% 
%             % check timing --
%             while GetSecs < StartFeedback + STIM.Times.Feedback/1000 && ...
%                     ~QuitScript
%                 % wait
%             end
% 
% 
%             %% PERFORMANCE FEEDBACK
%             if STIM.Feedback.PerfShow
%                 if TR >= STIM.Feedback.PerfOverLastNTrials && ...
%                         mod(TR,STIM.Feedback.PerfShowEveryNTrials) == 0
%                     % calculate performance level
%                     perfperc = 100*(...
%                         sum(CorrResp(end-(STIM.Feedback.PerfOverLastNTrials-1):end))./...
%                         STIM.Feedback.PerfOverLastNTrials);
%                     % which category
%                     idx = find([STIM.Feedback.PerfLevels{:,1}]>=perfperc,1,'first');
%                     perfclass = STIM.Feedback.PerfLevels{idx,2};
% 
%                     % give as feedback
%                     % set text to be bigger
%                     oldTextSize=Screen('TextSize', HARDWARE.window,...
%                         STIM.Feedback.TextSize(1));
%                     oldTextStyle=Screen('TextStyle',HARDWARE.window,1); %bold
%                     % background
%                     Screen('FillRect',HARDWARE.window,...
%                         STIM.BackColor*HARDWARE.white);
% 
%                     DrawFormattedText(HARDWARE.window,...
%                         [num2str(floor(perfperc)) '% correct\n\nPsychophysics ' perfclass],...
%                         'center','center',...
%                         STIM.Feedback.NeutralCol.*HARDWARE.white);
% 
%                     % Set text size back to small
%                     Screen('TextSize', HARDWARE.window,oldTextSize);
%                     Screen('TextStyle',HARDWARE.window,0);
%                     vbl = Screen('Flip', HARDWARE.window);
%                     StartPerfFB = GetSecs;
% 
%                     % check timing --
%                     while GetSecs < StartPerfFB + STIM.Times.Feedback/1000 && ...
%                             ~QuitScript
%                         % wait
%                     end
%                 end
%             end
%         end

        %% ITI
        StartITI=GetSecs;

        % empty screen
        Screen('FillRect',HARDWARE.window,...
            STIM.BackColor*HARDWARE.white);

        % check timing
        while GetSecs < StartITI + STIM.Times.ITI/1000
            % wait
        end
        % Add display statement to show completed trial
        disp(['Completed trial: ', num2str(TR), ' with relevant index: ', num2str(current_relevant_index), ', redundant index: ', num2str(current_redundant_index)]);

    end
end

%% WRAP UP
if ~QuitScript
    vbl = Screen('Flip', HARDWARE.window);
    Screen('FillRect',HARDWARE.window,...
        STIM.BackColor*HARDWARE.white);
    DrawFormattedText(HARDWARE.window,'Thank you!',...
        'center','center',STIM.TextIntensity);
    vbl = Screen('Flip', HARDWARE.window);
    % send message to eyelink
    if HARDWARE.EyelinkConnected
        Eyelink('Message', 'EndExperiment');
    end
    pause(2)
else
    vbl = Screen('Flip', HARDWARE.window);
    Screen('FillRect',HARDWARE.window,...
        STIM.BackColor*HARDWARE.white);
    DrawFormattedText(HARDWARE.window,...
        'Exiting...','center','center',STIM.TextIntensity);
    vbl = Screen('Flip', HARDWARE.window);
end
pause(.5)

%% Save the data
% Check if the directory exists
if ~exist(DataFolder, 'dir')
    % If the directory does not exist, create it
    mkdir(DataFolder);
end
save(fullfile(StartFolder,DataFolder,HARDWARE.LogLabel,LOG.FileName),'HARDWARE','STIM','LOG');

%% Restore screen
if HARDWARE.DoGammaCorrection
    Screen('LoadNormalizedGammaTable',HARDWARE.ScrNr,OLD_Gamtable);
end
Screen('CloseAll');ListenChar();ShowCursor;

if ~QuitScript
    fprintf('All done! Thank you for participating\n');
else
    fprintf('Quit the script by pressing escape\n');
end

%% Close up Eyelink
if HARDWARE.EyelinkConnected
    cd(fullfile(StartFolder, DataFolder,HARDWARE.LogLabel,'Eyelink_Log'))
    Eyelink('Stoprecording');
    Eyelink('Closefile');
    eyelink_receive_file(EL.edfFile);
    system(['!rename ',EL.edfFile,'.edf ',LOG.FileName,'.edf']) % was 'eval'
    disp(['Eyedata data saved under the name: ' LOG.FileName])
    Eyelink('ShutDown');
    cd(fullfile(StartFolder,DataFolder));
end
% catch e %#ok<CTCH> %if there is an error the script will go here
%     fprintf(1,'There was an error! The message was:\n%s',e.message);
%     if HARDWARE.DoGammaCorrection
%         Screen('LoadNormalizedGammaTable',HARDWARE.ScrNr,OLD_Gamtable);
%     end
%     Screen('CloseAll');ListenChar();ShowCursor;
%     %psychrethrow(psychlasterror);
%     %% Close up Eyelink
%     if HARDWARE.EyelinkConnected
%         Eyelink('Stoprecording');
%         Eyelink('Closefile');
%         Eyelink('ShutDown');
%     end
% end
cd(StartFolder); % back to where we started