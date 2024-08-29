function CLL_run(SettingsFile,Debug,WLOG)

%% PTB3 script for ======================================================
% CHOICE_LEARNING experiment
% Questions: c.klink@nin.knaw.nl

% Response: choose one of two keys (learn cue-response)

% In
% short:
% - A fixation dot is presented
% - A number of stimuli are presented with an attention cue
% - In the reponse phase, subjects say A or B
% - Feedback can be provided on whether this was correct
%==========================================================================
global STIM
clc; QuitScript = false;

if nargin < 3
    WLOG = [];
    if nargin < 2
        Debug = false;
        if nargin < 1
            SettingsFile = 'CLL_settings';
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
DataFolder = 'CLL_data';
StartFolder = pwd;
[~,~] = mkdir(fullfile(StartFolder,DataFolder));

%% Run the experiment ---------------------------------------------------
try
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
    HideCursor;

    %Define response keys
    Key1 = KbName(STIM.Key1); %#ok<*NODEF>
    Key2 = KbName(STIM.Key2);
    KeyFix = KbName('space');

    if ~IsLinux
        KeyBreak = KbName('Escape');
    else
        KeyBreak = KbName('ESCAPE');
    end
    ListenChar(2);

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
    % generate a trial list ---
    LOG.TrialList = [];
    if STIM.Trials.RandomTrials
        trialorder = randperm(size(STIM.Trials.TrialsInExp,2));
    else
        trialorder = 1:size(STIM.Trials.TrialsInExp,1);
    end
    LOG.TrialList = STIM.Trials.TrialsInExp(trialorder);

    % load images that are needed ---
    % we may need to do this in a more sensible way to avoid slow-downs
    % or memory issues. However, try to do it the simple way first as the
    % number of unique images may not be prohibitively high in this
    % experiment

    uniquetrials = unique(LOG.TrialList);
    allimages = STIM.Template.distractor_idx;
    for ut = uniquetrials'
        allimages = [allimages, ...
            STIM.TrialType(ut).relevant_idx ...
            STIM.TrialType(ut).redundant_idx ]; %#ok<*AGROW>
    end
    uniqueimages = unique(allimages);

    % pre-allocate variable for all possible images
    for i = uniqueimages
        for j = 1:length(STIM.morphimgs)
            STIM.img(i,j).img = [];
            STIM.img(i,j).tex = [];
        end
    end

    % load the ones we need
    fprintf('Loading images to textures...');
    for ui = uniqueimages
        for j = STIM.morphimgs
            serieslabel = ['c' num2str(STIM.morphs(ui).class{1},'%04.f') ...
                '-' num2str(STIM.morphs(ui).class{2},'%04.f')];
            STIM.img(ui,j+1).img = imread(fullfile(STIM.imagedir,serieslabel,...
                [serieslabel '_i' num2str(j,'%02.f') '.png']));
            STIM.img(ui,j+1).tex = Screen('MakeTexture',HARDWARE.window,...
                STIM.img(ui,j+1).img);
        end
    end
    fprintf('DONE\n');

    for tt = STIM.Trials.TrialsInExp
        for j = 1:length(STIM.morphimgs)
            STIM.dyn(tt).resp{j} = [];
        end
        STIM.dyn(tt).done = false;
        STIM.dyn(tt).currentimg = 1;
    end

    % load the sounds we need
    [curpath, name, ext] = fileparts(mfilename('fullpath'));
    [snd(1).wav,snd(1).fs] = audioread(fullfile(curpath,STIM.snddir,...
        STIM.Feedback.SoundCorrect{1}));
    [snd(2).wav,snd(2).fs] = audioread(fullfile(curpath,STIM.snddir,...
        STIM.Feedback.SoundCorrect{2}));
    [snd(3).wav,snd(3).fs] = audioread(fullfile(curpath,STIM.snddir,...
        STIM.Feedback.SoundWrong));

    % convert image locations to rects and the cue lines to coordinates
    for p = 1:length(STIM.Template.imgpos.angle)
        % img rect
        [X,Y] = pol2cart(...
            deg2rad(STIM.Template.imgpos.angle(p)),...
            STIM.Template.imgpos.r.*HARDWARE.Deg2Pix);
        X = HARDWARE.Center(1)+X;
        Y = HARDWARE.Center(2)-Y;
        STIM.imgszpix = round(STIM.imgsz.*HARDWARE.Deg2Pix);
        rect = [0 0 STIM.imgszpix];
        STIM.pos(p).rect = CenterRectOnPoint(rect,X,Y);
        % cue points
        STIM.cue.szpix = round(STIM.cue.sz.*HARDWARE.Deg2Pix);
        [x1,y1]=pol2cart(...
            deg2rad(STIM.Template.imgpos.angle(p)),...
            STIM.cue.pos*HARDWARE.Deg2Pix);
        [x2,y2]=pol2cart(...
            deg2rad(STIM.Template.imgpos.angle(p)),...
            STIM.cue.pos*HARDWARE.Deg2Pix+STIM.cue.szpix(2));
        x1 = HARDWARE.Center(1)+x1;
        y1 = HARDWARE.Center(2)-y1;
        x2 = HARDWARE.Center(1)+x2;
        y2 = HARDWARE.Center(2)-y2;
        STIM.pos(p).cuexy = [x1,y1,x2,y2];
        STIM.pos(p).cuewidth = STIM.cue.szpix(1);
    end

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
    trialsdone = 0; AllSeriesDone = false;
    if STIM.Trials.InterMixed
        CurrTrialList = LOG.TrialList;
    else
        CurrTrialList = LOG.TrialList(1);
        CurrTrialListIdx = 1;
    end

    while trialsdone <= STIM.Trials.MaxNumTrials && ~AllSeriesDone && ~QuitScript
        for TR = 1:length(CurrTrialList)
            if QuitScript
                break;
            else
                KeyWasDown = false;
            end
            tidx = CurrTrialList(TR);
            LOG.Trial(trialsdone+1).TrialType = tidx;
            LOG.Trial(trialsdone+1).currimg = STIM.dyn(tidx).currentimg;


            % Trial-start to Eyelink
            if HARDWARE.EyelinkConnected
                pause(0.1) % send some samples to edf file
                %send message to EDF file
                edfstring=['StartTrial_' num2str(trialsdone+1)];
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
                    if trialsdone == 0 || ~mod(trialsdone+1,HARDWARE.MeasureFixEveryNthTrials)
                        while ~GoodCenter
                            % Check key-press
                            [keyIsDown,secs,keyCode] = KbCheck; %#ok<*ASGLU>
                            if keyIsDown
                                if keyCode(KeyBreak) %break when esc
                                    QuitScript = true;
                                    break;
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
                LOG.Trial(trialsdone+1).CenterFix = CenterFix;

                %% Fix-phase
                % First trial
                if trialsdone == 0
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
                LOG.Trial(trialsdone+1).FixOnset = vbl - LOG.ExpOnset;

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
                while vbl - LOG.ExpOnset < LOG.Trial(trialsdone+1).FixOnset + ...
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
                LOG.Trial(trialsdone+1).StimPhaseOnset = vbl - LOG.ExpOnset;
                MaxDur = max([STIM.Times.Cue(2) STIM.Times.Stim(2)]);
                ResponseGiven = false;

%                 % prep distractors
%                 didx = STIM.Template.distractor_idx;
%                 didx = didx(randperm(length(didx)));
%                 didx = didx(1:length(STIM.TrialType(tidx).distractor_pos));
%                 LOG.Trial(trialsdone+1).distractor_idx = didx;

                %% SW: Prep distractors
                % Initialize the last used distractor for all positions in the trial
                last_used_distractors = NaN(1, max(STIM.TrialType(tidx).distractor_pos));
                
                % Randomly select distractor images for each predefined distractor position
                selected_distractors = [];
                for p = STIM.TrialType(tidx).distractor_pos  % Iterate over the predefined distractor positions
                    current_pool = [];
                    
                    % Select the correct pool based on the current position
                    switch p
                        case 1
                            current_pool = STIM.DistractorPool.Pos1;
                        case 3
                            current_pool = STIM.DistractorPool.Pos3;
                        case 4
                            current_pool = STIM.DistractorPool.Pos4;
                        case 6
                            current_pool = STIM.DistractorPool.Pos6;
                        % Add more cases if you have more distractor positions defined
                    end
                    
                    % Select a random image, ensuring it's not the same as the last used
                    valid_selection = false;
                    while ~valid_selection
                        selected_image = current_pool(randperm(length(current_pool), 1));  % Randomly pick an image
                        
                        % Check if the last used distractor for this position is the same
                        if ~isnan(last_used_distractors(p)) && selected_image == last_used_distractors(p)
                            valid_selection = false;
                        else
                            valid_selection = true;
                        end
                    end
                    
                    % Store the selected image in the list of distractors for this trial
                    selected_distractors = [selected_distractors selected_image];
                    
                    % Update the last used distractor for this position
                    last_used_distractors(p) = selected_image;
                end
                
                % Assign the selected distractors to the current trial
                LOG.Trial(trialsdone+1).distractor_idx = selected_distractors;

                % Assign selected_distractors to didx for backward compatibility
                didx = selected_distractors;
                
                %%% End SW

                FirstFlipDone = false;
                CueOnLog = false;
                ImageOnLog = false;
                nl=0;
                while vbl - LOG.ExpOnset < ...
                        (LOG.Trial(trialsdone+1).StimPhaseOnset + MaxDur/1000) && ...
                        ~ResponseGiven && FixatingNow && ~QuitScript
                    % background --
                    Screen('FillRect',HARDWARE.window,...
                        STIM.BackColor*HARDWARE.white);

                    % CUE --
                    if vbl - LOG.ExpOnset >= LOG.Trial(trialsdone+1).StimPhaseOnset + ...
                            STIM.Times.Cue(1)/1000 && ...
                            ~QuitScript

                        % Draw cue
                        p = STIM.TrialType(tidx).relevant_pos;
                        Screen('DrawLine',HARDWARE.window,...
                            STIM.cue.color.*HARDWARE.white,...
                            STIM.pos(p).cuexy(1), STIM.pos(p).cuexy(2),...
                            STIM.pos(p).cuexy(3), STIM.pos(p).cuexy(4),...
                            STIM.pos(p).cuewidth);
                    end

                    % IMAGES --
                    if vbl - LOG.ExpOnset >= LOG.Trial(trialsdone+1).StimPhaseOnset + ...
                            STIM.Times.Stim(1)/1000 && ~QuitScript
                        % Draw stim images

                        % relevant
                        idx = STIM.TrialType(tidx).relevant_idx;
                        p = STIM.TrialType(tidx).relevant_pos;
                        Screen('DrawTexture', HARDWARE.window,...
                            STIM.img(idx,STIM.dyn(tidx).currentimg).tex,...
                            [],STIM.pos(p).rect)

                        % redundant
                        idx = STIM.TrialType(tidx).redundant_idx;
                        p = STIM.TrialType(tidx).redundant_pos;
                        Screen('DrawTexture', HARDWARE.window,...
                            STIM.img(idx,STIM.dyn(tidx).currentimg).tex,...
                            [],STIM.pos(p).rect)

                        % other
                        for d=1:length(didx)
                            p = STIM.TrialType(tidx).distractor_pos(d);
                            Screen('DrawTexture', HARDWARE.window,...
                                STIM.img(didx(d),STIM.dyn(tidx).currentimg).tex,...
                                [],STIM.pos(p).rect);
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
                            QuitScript=1;
                            break;
                        elseif keyCode(Key1)
                            %fprintf('Key 1 pressed\n')
                            j = STIM.dyn(tidx).currentimg;
                            if STIM.TrialType(tidx).correctresponse == 1
                                STIM.dyn(tidx).resp{j} = [STIM.dyn(tidx).resp{j} 1];
                                CorrectResponse = true;
                            else
                                STIM.dyn(tidx).resp{j} = [STIM.dyn(tidx).resp{j} 0];
                                CorrectResponse = false;
                            end
                            LOG.Trial(trialsdone+1).Response = 'left';
                            LOG.Trial(trialsdone+1).Resp = 1;
                            ResponseGiven = true;
                        elseif keyCode(Key2)
                            %fprintf('Key 0 pressed\n')
                            j = STIM.dyn(tidx).currentimg;
                            if STIM.TrialType(tidx).correctresponse == 2
                                STIM.dyn(tidx).resp{j} = [STIM.dyn(tidx).resp{j} 1];
                                CorrectResponse = true;
                            else
                                STIM.dyn(tidx).resp{j} = [STIM.dyn(tidx).resp{j} 0];
                                CorrectResponse = false;
                            end
                            LOG.Trial(trialsdone+1).Response = 'right';
                            LOG.Trial(trialsdone+1).Resp = 2;
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
                        LOG.Trial(trialsdone+1).StimPhaseOnset = ...
                            vbl - LOG.ExpOnset;
                        % send message to eyelink
                        if HARDWARE.EyelinkConnected
                            Eyelink('Message', 'StartStim');
                        end
                        FirstFlipDone = true;
                    end
                    if ~CueOnLog
                        % Log stim-phase onset
                        LOG.Trial(trialsdone+1).CueOnset = ...
                            vbl - LOG.ExpOnset;
                        % send message to eyelink
                        if HARDWARE.EyelinkConnected
                            Eyelink('Message', 'Cue');
                        end
                        CueOnLog = true;
                    end

                    if ~ImageOnLog
                        % Log stim-phase onset
                        LOG.Trial(trialsdone+1).CueOnset = ...
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
                trialsdone = trialsdone+1;

                %% Feedback
                if ~QuitScript
                    StartFeedback=GetSecs;
                    LOG.Trial(trialsdone).FeedbackOnset = vbl - LOG.ExpOnset;
                    LOG.Trial(trialsdone).RespCorr = CorrectResponse;

                    % display feedback text --
                    % set text to be bigger
                    oldTextSize=Screen('TextSize', HARDWARE.window,...
                        STIM.Feedback.TextSize(1));
                    oldTextStyle=Screen('TextStyle',HARDWARE.window,1); %bold
                    % background
                    Screen('FillRect',HARDWARE.window,...
                        STIM.BackColor*HARDWARE.white);
                    if CorrectResponse
                        DrawFormattedText(HARDWARE.window,...
                            ['Response: ' LOG.Trial(trialsdone).Response '\n\n'...
                            STIM.Feedback.TextCorrect],...
                            'center','center',...
                            STIM.Feedback.TextCorrectCol.*HARDWARE.white);
                    else
                        DrawFormattedText(HARDWARE.window,...
                            ['Response: ' LOG.Trial(trialsdone).Response '\n\n'...
                            STIM.Feedback.TextWrong],...
                            'center','center',...
                            STIM.Feedback.TextWrongCol.*HARDWARE.white);
                    end
                    % Set text size back to small
                    Screen('TextSize', HARDWARE.window,oldTextSize);
                    Screen('TextStyle',HARDWARE.window,0);
                    vbl = Screen('Flip', HARDWARE.window);

                    % play sound --
                    if STIM.UseSoundFeedback
                        if CorrectResponse
                            sound(snd(1).wav,snd(1).fs);
                            %sound(snd(2).wav,snd(2).fs);
                        else
                            sound(snd(3).wav,snd(3).fs);
                        end
                    end

                    % check timing --
                    while GetSecs < StartFeedback + STIM.Times.Feedback/1000 && ...
                            ~QuitScript
                        % wait
                    end
                end

                %% ITI
                StartITI=GetSecs;

                % empty screen
                Screen('FillRect',HARDWARE.window,...
                    STIM.BackColor*HARDWARE.white);

                % check timing
                while GetSecs < StartITI + STIM.Times.ITI/1000
                    % wait
                end
            end

            % performance for this series
            % SW: PerformanceThreshold is defined as [required_correct_responses, trial_window]
            STIM.Trials.PerformanceThreshold = [4, 5]; % Requires 2 correct responses out of the last 3 trials

            resp = STIM.dyn(tidx).resp{STIM.dyn(tidx).currentimg};
            respinv = fliplr(resp);
            if size(resp,2) >= STIM.Trials.PerformanceThreshold(2) && ...
                    sum(respinv(1:STIM.Trials.PerformanceThreshold(2))) >= ...
                    STIM.Trials.PerformanceThreshold(1)
                % next image
                STIM.dyn(tidx).currentimg = STIM.dyn(tidx).currentimg+1;
                if STIM.dyn(tidx).currentimg > length(STIM.morphimgs)
                    STIM.dyn(tidx).done = true;
                    if ~STIM.Trials.InterMixed
                        CurrTrialListIdx = CurrTrialListIdx + 1;
                        if CurrTrialListIdx > length(LOG.TrialList)
                            AllSeriesDone = true;
                        else
                            CurrTrialList = LOG.TrialList(CurrTrialListIdx);
                        end
                    end
                end
            end
        end

        % check if there are series incomplete
        if STIM.Trials.InterMixed
            AllSeriesDone = true; remidx = [];
            for TT  = 1:size(CurrTrialList,2)
                if STIM.dyn(CurrTrialList(TT)).done
                    remidx = [remidx TT];
                else
                    AllSeriesDone = false;
                end
            end
            if ~isempty(remidx)
                CurrTrialList(remidx) = [];
            end
            if isempty(CurrTrialList)
                AllSeriesDone = true;
            end
        end

        if STIM.Trials.RandomTrials && ~AllSeriesDone
            CurrTrialList = CurrTrialList(randperm(length(CurrTrialList)));
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
        pause(1)
    else
        vbl = Screen('Flip', HARDWARE.window);
        Screen('FillRect',HARDWARE.window,...
            STIM.BackColor*HARDWARE.white);
        DrawFormattedText(HARDWARE.window,...
            'Exiting...','center','center',STIM.TextIntensity);
        vbl = Screen('Flip', HARDWARE.window);
    end
    pause(1);
        
    %% Save the data
    % remove the images from the log to save space
    if STIM.RemoveImagesFromLog
        for i = 1: size(STIM.img,1)
            for j = 1:size(STIM.img,2)
                STIM.img(i,j).img = [];
            end
        end
    end
    [~,~] = mkdir(fullfile(StartFolder,DataFolder,HARDWARE.LogLabel));
    save(fullfile(StartFolder,DataFolder,HARDWARE.LogLabel,LOG.FileName),...
        'HARDWARE','STIM','LOG');

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
catch e %#ok<CTCH> %if there is an error the script will go here
    fprintf(1,'There was an error! The message was:\n%s',e.message);
    if HARDWARE.DoGammaCorrection
        Screen('LoadNormalizedGammaTable',HARDWARE.ScrNr,OLD_Gamtable);
    end
    Screen('CloseAll');ListenChar();ShowCursor;
    %psychrethrow(psychlasterror);
    %% Close up Eyelink
    if HARDWARE.EyelinkConnected
        Eyelink('Stoprecording');
        Eyelink('Closefile');
        Eyelink('ShutDown');
    end
end
cd(StartFolder); % back to where we started