function CL_run(Debug)

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

clc; QuitScript = false;

if nargin < 1
    Debug = false;
end
warning off; %#ok<*WNOFF>
DebugRect = [0 0 1024 768];

%% Read in variables ----------------------------------------------------
% First get the settings
CL_settings;

%% Create data folder if it doesn't exist yet and go there --------------
DataFolder = 'CL_data';
StartFolder = pwd;
[~,~] = mkdir(fullfile(StartFolder,DataFolder));

try
    %% Initialize & Calculate Stimuli -----------------------------------
    if Debug
        LOG.Subject = 'TEST';
        LOG.Gender = 'x';
        LOG.Age = 0;
        LOG.Handedness = 'R';
        LOG.DateTimeStr = datestr(datetime('now'), 'yyyyMMdd_HHmm'); %#ok<*DATST>
    else
        % Get registration info & check against existing data
        LOG.Subject = [];
        LOG.SesNr = [];
        % Get subject info
        while isempty(LOG.Subject)
            INFO = inputdlg({'Subject Initials', ...
                'Gender (m/f/x)', 'Age', 'Left(L)/Right(R) handed'},...
                'Subject',1,{'XX','x','0','R'},'on');
            LOG.Subject = INFO{1};
            LOG.Gender = INFO{2};
            LOG.Age = str2double(INFO{3});
            LOG.Handedness = INFO{4};
        end
        % Get timestring id
        LOG.DateTimeStr = datestr(datetime('now'), 'yyyyMMdd_HHmm');
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

    % load images that are needed ---
    % we may need to do this in a more sensisble way to avoid slow-downs
    % or memory issues. However, try to do it the simple way first as the
    % number of unique images may not be prohibitively high in this
    % experiment

    uniquetrials = unique(LOG.TrialList(:,1));
    allimages = []; 
    for ut = uniquetrials'
        allimages = [allimages, STIM.Trials.trial(ut).images]; %#ok<*AGROW>
    end
    uniqueimages = unique(allimages);

    % pre-allocate variable for all possible images
    for i = 1: length(STIM.img)
        STIM.img(i).img = [];
        STIM.img(i).tex = [];
    end

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
    LOG.FileName = [LOG.Subject '_' DataFolder '_' LOG.DateTimeStr];

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
        [~,~] = mkdir(fullfile(StartFolder, DataFolder,'Eyelink_Log'));
        EL.edfFile = 'TempEL'; %NB! Name cannot be more than 8 digits long
        cd(fullfile(StartFolder, DataFolder))
        Eyelink('Openfile',EL.edfFile);
        EL.el = EyelinkInitDefaults(HARDWARE.windowEL);
        EL.el.backgroundcolour = STIM.BackColor*HARDWARE.white;
        EL.el.foregroundcolour = HARDWARE.black;

        % Calibrate the eye tracker
        EyelinkDoTrackerSetup(EL.el); % control further from eyelink pc
        % do a final check of calibration using driftcorrection
        %EyelinkDoDriftCorrection(EL.el);

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
                    '>> Press key to start <<','center',....
                    HARDWARE.Center(2)-40,...
                    STIM.TextIntensity);
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
            CueOn = false; CueOnLog = false;
            ImageOn = false; ImageOnLog = false;
            RedrawBG = true;

            while vbl - LOG.ExpOnset < ...
                    (LOG.Trial(TR).StimPhaseOnset + MaxDur/1000) && ...
                    ~ResponseGiven && FixatingNow && ~QuitScript
                
                if RedrawBG
                    % background --
                    Screen('FillRect',HARDWARE.window,...
                        STIM.BackColor*HARDWARE.white);
                    CueOn = false;
                    ImageOn = false;
                    RedrawBG = false;
                end

                % CUE --
                if vbl - LOG.ExpOnset >= LOG.Trial(TR).StimPhaseOnset + ...
                        STIM.Times.Cue(1)/1000 && ~QuitScript
                    if ~CueOn
                        % Draw cue
                        tidx = LOG.TrialList(TR,1);
                        cidx = STIM.Trials.trial(tidx).cue;
                        cwidth = STIM.cue(cidx).sz(1).*HARDWARE.Deg2Pix;

                        veclength = STIM.cue(cidx).sz(2)*HARDWARE.Deg2Pix;
                        toH = round(STIM.cue(cidx).dir(1)*veclength);
                        toV = round(STIM.cue(cidx).dir(2)*veclength);

                        Screen('DrawLine',HARDWARE.window,...
                            STIM.cue(cidx).color.*HARDWARE.white,...
                            HARDWARE.Center(1), HARDWARE.Center(2),...
                            HARDWARE.Center(1)+toH, HARDWARE.Center(2)+toV,...
                            cwidth);

                        CueOn = true;
                    end
                end
                if vbl - LOG.ExpOnset >= LOG.Trial(TR).StimPhaseOnset + ...
                        STIM.Times.Cue(2)/1000 && ~QuitScript
                    RedrawBG = true;
                end

                % IMAGES --
                if vbl - LOG.ExpOnset >= LOG.Trial(TR).StimPhaseOnset + ...
                        STIM.Times.Stim(1)/1000 && ~QuitScript
                    % Draw stim images
                    if ~ImageOn
                        tidx = LOG.TrialList(TR,1);
                        for imgidx = 1: length(STIM.Trials.trial(tidx).images)
                            imagei = STIM.Trials.trial(tidx).images(imgidx);
                            ImageRect = CenterRectOnPoint(...
                                [0 0 STIM.imgsz(1) STIM.imgsz(2)].*HARDWARE.Deg2Pix,...
                                STIM.Trials.trial(tidx).imgpos(imgidx,1)*HARDWARE.Deg2Pix,...
                                STIM.Trials.trial(tidx).imgpos(imgidx,2)*HARDWARE.Deg2Pix)
                            Screen('DrawTexture', HARDWARE.window,...
                                STIM.img(imagei).tex,[],ImageRect)
                        end
                        ImageOn = true;
                    end
                end
                if vbl - LOG.ExpOnset >= LOG.Trial(TR).StimPhaseOnset + ...
                        STIM.Times.Stim(2)/1000 && ~QuitScript
                    RedrawBG = true;
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
                        QuitScript=1;break;
                    elseif keyCode(Key1)
                        LOG.Trial(TR).Response = 'left';
                        LOG.Trial(TR).Resp = 1;
                    elseif keyCode(Key2)
                        LOG.Trial(TR).Response = 'right';
                        LOG.Trial(TR).Resp = 2;
                    end
                    KeyWasDown=1;
                elseif keyIsDown && KeyWasDown
                    if keyCode(KeyBreak) %break when esc
                        QuitScript=1;break;
                    end
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
            StartFeedback=GetSecs;
            LOG.Trial(TR).FeedbackOnset = vbl - LOG.ExpOnset; 

            % check if response is correct or not
            imagei = STIM.Trials.trial(tidx).targ;
            if LOG.Trial(TR).Resp == STIM.img(imagei).correctresp
                % correct
                CorrectResponse = true;
                nPoints = STIM.img(imagei).points;
            else
                % wrong
                CorrectResponse = false;
            end
            LOG.Trial(TR).RespCorr = CorrectResponse;
            CorrResp = [CorrResp; CorrectResponse];

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
                    [STIM.Feedback.TextCorrect '\n' num2str(nPoints) 'points'],...
                    'center',HARDWARE.Center(2)-STIM.Feedback.TextY(1),...
                    STIM.Feedback.TextCorrectCol.*HARDWARE.white);
            else
                DrawFormattedText(HARDWARE.window,...
                    STIM.Feedback.TextWrong,...
                    'center',HARDWARE.Center(2)-STIM.Feedback.TextY(1),...
                    STIM.Feedback.TextWrongCol.*HARDWARE.white);
            end
            % Set text size back to small
            Screen('TextSize', HARDWARE.window,oldTextSize);
            Screen('TextStyle',HARDWARE.window,0);
            vbl = Screen('Flip', HARDWARE.window);
            
            % play sound --
            if CorrectResponse
                if nPoints == 0
                    sound(snd(1).wav,snd(1).fs);
                else
                    sound(snd(2).wav,snd(2).fs);
                end
            else
                sound(snd(3).wav,snd(3).fs);
            end

            % check timing --
            while GetSecs < StartFeedback + STIM.Times.Feedback/1000 && ...
                    ~QuitScript
                % wait
            end


            %% PERFORMANCE FEEDBACK
            if STIM.Feedback.PerfShow
                if TR > STIM.Feedback.PerfOverLastNTrials && ...
                        mod(TR,STIM.Feedback.PerfShowEveryNTrials) == 0
                    % calculate performance level
                    perfperc = 100*(...
                        sum(CorrResp(end-(STIM.Feedback.PerfOverLastNTrials-1):end))./...
                        STIM.Feedback.PerfOverLastNTrials);
                    % which category
                    i = 1;
                    while perfperc <= STIM.Feedback.PerfLevels{i,1}
                        perfclass = STIM.Feedback.PerfLevels{i,2};
                        i=i+1;
                    end
                    % give as feedback
                    % set text to be bigger
                    oldTextSize=Screen('TextSize', HARDWARE.window,...
                        STIM.Feedback.TextSize(1));
                    oldTextStyle=Screen('TextStyle',HARDWARE.window,1); %bold
                    % background
                    Screen('FillRect',HARDWARE.window,...
                        STIM.BackColor*HARDWARE.white);

                    DrawFormattedText(HARDWARE.window,...
                        [num2str(floor(perfperc)) '% correct\nPsychophysics ' perfclass],...
                        'center',HARDWARE.Center(2)-STIM.Feedback.TextY(1),...
                        STIM.Feedback.TextCorrectCol.*HARDWARE.white);

                    % Set text size back to small
                    Screen('TextSize', HARDWARE.window,oldTextSize);
                    Screen('TextStyle',HARDWARE.window,0);
                    vbl = Screen('Flip', HARDWARE.window);
                    StartPerfFB = GetSecs;

                    % check timing --
                    while GetSecs < StartPerfFB + STIM.Times.Feedback/1000 && ...
                            ~QuitScript
                        % wait
                    end
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
    end
    
    %% WRAP UP
    if ~QuitScript
        vbl = Screen('Flip', HARDWARE.window);
        Screen('FillRect',HARDWARE.window,...
                    STIM.BackColor*HARDWARE.white);
        DrawFormattedText(HARDWARE.window,'Thank you!',...
            'center','center',[1 0 0]*STIM.TextIntensity);
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
    save(fullfile(StartFolder,DataFolder,LOG.FileName),'HARDWARE','STIM','LOG');

    %% Restore screen
    Screen('LoadNormalizedGammaTable',HARDWARE.ScrNr,OLD_Gamtable);
    Screen('CloseAll');ListenChar();ShowCursor;

    if ~QuitScript
        fprintf('All done! Thank you for participating\n');
    else
        fprintf('Quit the script by pressing escape\n');
    end

    %% Close up Eyelink
    if HARDWARE.EyelinkConnected
        cd(fullfile(StartFolder, DataFolder,'Eyelink_Log'))
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
    Screen('CloseAll');ListenChar();ShowCursor;psychrethrow(psychlasterror);
    %% Close up Eyelink
    if HARDWARE.EyelinkConnected
        Eyelink('Stoprecording');
        Eyelink('Closefile');
        Eyelink('ShutDown');
    end
end
cd(StartFolder); % back to where we started