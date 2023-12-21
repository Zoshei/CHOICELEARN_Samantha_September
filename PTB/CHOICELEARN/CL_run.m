function CL_run

%% PTB3 script for ========================================================
% CHOICE_LEARNING experiment
% Questions: c.klink@nin.knaw.nl

% Response: choose A or B (learn cue-response)

% In short:
% - A fixation cross is presented
% - A number of stimuli are presented with a attention cue
% - In the reponse phase, subjects say A or B
% - Feedback can be provided on whether this was correct
% - Blockwise chunking of stimulus sets is possible
%==========================================================================

clear all; 
clc;
QuitScript = false;
Debug = true;
warning off; %#ok<*WNOFF>

%% Read in variables ------------------------------------------------------
% First get the settings
CL_settings;

%% Create data folder if it doesn't exist yet and go there ----------------
DataFolder = 'CL_data';
StartFolder = pwd;
mkdir(DataFolder);
cd(DataFolder);

try
    %% Initialize & Calculate Stimuli -------------------------------------
    if Debug
        LOG.Subject = 'TEST';
        LOG.Gender = 'x';
        LOG.Age = 0;
        LOG.Handedness = 'R';
        LOG.DateTimeStr = datestr(datetime('now'), 'yyyyMMdd_HHmm');
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

    if HARDWARE.EyelinkConnected
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
    KeyL1 = KbName('LeftArrow');
    KeyL2 = KbName('1!');
    KeyR1 = KbName('RightArrow');
    KeyR2 = KbName('2@');
    KeyFix = KbName('space');

    if ~IsLinux
        KeyBreak = KbName('Escape');
    else
        KeyBreak = KbName('ESCAPE');
    end
    ListenChar(2);

    % Get screen info
    scr = Screen('screens');
    STIM.Screen.ScrNr = max(scr); % use the screen with the highest #
    % check this at the setup

    % Gamma Correction to allow intensity in fractions
    if HARDWARE.DoGammaCorrection
        [OLD_Gamtable, dacbits, reallutsize] = ...
            Screen('ReadNormalizedGammaTable', STIM.Screen.ScrNr);
        GamCor = (0:1/255:1).^HARDWARE.GammaCorrection;
        Gamtable = [GamCor;GamCor;GamCor]';
        Screen('LoadNormalizedGammaTable',STIM.Screen.ScrNr, Gamtable);
    end

    % Get the screen size in pixels
    [STIM.Screen.PixWidth, STIM.Screen.PixHeight] = ...
        Screen('WindowSize',STIM.Screen.ScrNr);
    % Get the screen size in mm
    [STIM.Screen.MmWidth, STIM.Screen.MmHeight] = ...
        Screen('DisplaySize',STIM.Screen.ScrNr);

    % Get some basic color intensities
    STIM.Screen.white = WhiteIndex(STIM.Screen.ScrNr);
    STIM.Screen.black = BlackIndex(STIM.Screen.ScrNr);
    STIM.Screen.grey = (STIM.Screen.white+STIM.Screen.black)/2;

    % Define conversion factors
    STIM.Screen.Mm2Pix=STIM.Screen.PixWidth/STIM.Screen.MmWidth;
    STIM.Screen.Deg2Pix=(tand(1)*HARDWARE.DistFromScreen)*...
        STIM.Screen.PixWidth/STIM.Screen.MmWidth;

    % Determine color of on screen text and feedback
    % depends on background color --> Black or white
    if max(STIM.BackColor) > .5
        STIM.TextIntensity = STIM.Screen.black;
    else
        STIM.TextIntensity = STIM.Screen.white;
    end

    % Open a double-buffered window on screen
    if Debug
        % for CK desktop linux; take one screen only
        WindowRect=...
            [0 0 0.5*STIM.Screen.PixWidth STIM.Screen.PixHeight]; %debug
    else
        WindowRect = []; %fullscreen
    end

    [STIM.Screen.window, STIM.Screen.windowRect] = ...
        Screen('OpenWindow',STIM.Screen.ScrNr,...
        STIM.BackColor*STIM.Screen.white,WindowRect,[],2);

    if HARDWARE.EyelinkConnected
        [STIM.Screen.windowEL, STIM.Screen.windowRect] = ...
            Screen('OpenWindow',STIM.Screen.ScrNr,...
            STIM.BackColor*STIM.Screen.white,WindowRect,[],2);
    end

    STIM.Screen.Center = ...
        [STIM.Screen.windowRect(3)/2 STIM.Screen.windowRect(4)/2];

    % Define blend function for anti-aliassing
    [sourceFactorOld, destinationFactorOld, colorMaskOld] = ...
        Screen('BlendFunction', STIM.Screen.window, ...
        GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    % Initialize text options
    Screen('Textfont',STIM.Screen.window,'Arial');
    Screen('TextSize',STIM.Screen.window,16);
    Screen('TextStyle',STIM.Screen.window,0);

    % Maximum useable priorityLevel on this system:
    priorityLevel = MaxPriority(STIM.Screen.window);
    Priority(priorityLevel);

    % Get the refreshrate
    STIM.Screen.FrameDur = Screen('GetFlipInterval',STIM.Screen.window);

    %% Prepare stimuli ----------------------------------------------------
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
    % we may need to do this in a sensisble way to avoid slow-downs
    % or memory issues. However, try to do it the simple way first as the
    % number of unique images may not be prohibitively high in this
    % experiment

    uniquetrials = unique(LOG.TrialList(:,1));
    allimages = [];
    for ut = uniquetrials
        allimages = [allimages, STIM.Trials.trial(ut).images];
    end
    uniqueimages = unique(allimages);

    for ui = uniqueimages
        STIM.img(ui).img = imread(fullfile(STIM.bitmapdir,STIM.img(ui).fn));
        STIM.img(ui).tex = MakeTexture(STIM.Screen.window,STIM.img(ui).img);
    end

    % Create filename ---
    LOG.FileName = [LOG.Subject '_' DataFolder '_' LOG.DateTimeStr];

    % Create the fixation dot area
    FixRect = ...
        [STIM.Screen.Center(1)-STIM.Fix.Size*STIM.Screen.Deg2Pix/2 ...
        STIM.Screen.Center(2)-STIM.Fix.Size*STIM.Screen.Deg2Pix/2 ...
        STIM.Screen.Center(1)+STIM.Fix.Size*STIM.Screen.Deg2Pix/2 ...
        STIM.Screen.Center(2)+STIM.Fix.Size*STIM.Screen.Deg2Pix/2];

    % Initiate the side-cues
    for c = 1:length(STIM.cue)
        switch STIM.cue(c).type
            case 'line'
                x1 = round(STIM.Screen.Center(1) + ...
                    (STIM.cue(c).pos(1)-STIM.cue(c).sz(1)/2)*STIM.Screen.Deg2Pix);
                x2 = round(STIM.Screen.Center(1) + ...
                    (STIM.cue(c).pos(1)+STIM.cue(c).sz(1)/2)*STIM.Screen.Deg2Pix);
                y1 = round(STIM.Screen.Center(2) + ...
                    STIM.cue(c).pos(2)*STIM.Screen.Deg2Pix);
                y2 = y1;
                lw = round(STIM.cue(c).sz(2)*STIM.Screen.Deg2Pix);
                STIM.cue(c).xy = [x1,y1,x2,y2,lw];
           case 'something else'
                % keep this open for alternative cues
        end
    end

    %% Run the Experiment
    % Eyelink

    %% Calibrate EYELINK-----------------------------------------------
    if HARDWARE.EyelinkConnected
        % open file to record data to
        mkdir 'Eyelink_Log';
        EL.edfFile = 'TempEL'; %NB! Name cannot be more than 8 digits long
        Eyelink('Openfile', EL.edfFile);
        EL.el = EyelinkInitDefaults(STIM.Screen.windowEL);
        EL.el.backgroundcolour = STIM.BackColor*STIM.Screen.white;
        EL.el.foregroundcolour = STIM.Screen.black;

        % Calibrate the eye tracker
        EyelinkDoTrackerSetup(EL.el); % control further from eyelink pc
        % do a final check of calibration using driftcorrection
        %EyelinkDoDriftCorrection(EL.el);

        %% Inititialize ---------------------------------------------------
        % start recording eye position
        Eyelink('StartRecording');
        % record a few samples before we actually start displaying
        WaitSecs(0.1);
        % mark zero-plot time in data file
        Eyelink('Message', 'SYNCTIME');
        EL.eye_used = -1;
        Eyelink('Message', LOG.FileName);
        Screen('Close', STIM.Screen.windowEL);
    end

    % Run the trials
    for TR = 1:size(LOG.TrialList,1)
        if QuitScript
            break;
        end
        
        LOG.Block(LOG.SesNr).Trial(TR).CondNr = Trials(TR);
        LOG.Block(LOG.SesNr).Trial(TR).Cond = ...
            STIM.Conditions(LOG.Block(LOG.SesNr).Trial(TR).CondNr,:);

        RV_TL = LOG.Block(LOG.SesNr).Trial(TR).Cond(2:3);
        RVS = 1:length(STIM.Reward.Values);
        RTL = 1:STIM.NoOfTargets;
        RemainingRV = RVS(RVS~=RV_TL(1));
        RemainingTL = RTL(RTL~=RV_TL(2));
        RemainingTLs= RemainingTL(randperm(length(RemainingTL)));
        RVS_TLS = [RV_TL; [RemainingRV' RemainingTLs']];
        RVS_TLS_ORG = RVS_TLS;
        RVS_TLS = sortrows(RVS_TLS,2);
        LOG.Block(LOG.SesNr).Trial(TR).RV_TL = RVS_TLS;







        % 
        if HARDWARE.EyelinkConnected
            pause(0.1) % send some samples to edf file
            %send message to EDF file
            edfstring=['StartTrial_' num2str(TR)];
            Eyelink('Message', edfstring);
        end

        if ~QuitScript
            vbl = Screen('Flip', STIM.Screen.window);
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
                                QuitScript = 1; break;
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
                        Screen('FillRect',STIM.Screen.window,...
                            STIM.BackColor*STIM.Screen.white);
                        Screen('FillOval', STIM.Screen.window,...
                            STIM.Fix.Color.*STIM.Screen.white,FixRect);
                        % Draw Fix instruction
                        DrawFormattedText(STIM.Screen.window,...
                            InstrText,'center',STIM.Screen.Center(2)-...
                            10*STIM.Fix.Size*STIM.Screen.Deg2Pix,...
                            STIM.TextIntensity);
                        % Flip
                        vbl = Screen('Flip', STIM.Screen.window);
                    end
                end
                %%% ============================
            else CenterFix = [0,0];
            end
            LOG.Block(LOG.SesNr).Trial(TR).CenterFix = CenterFix;

            %% Fix-phase
            % First frame
            if TR == 1 || ~mod(TR,STIM.Reward.ColorLegendEveryN)
                % start of the experiment
                Screen('FillRect',STIM.Screen.window,...
                    STIM.BackColor*STIM.Screen.white);
                DrawFormattedText(STIM.Screen.window,...
                    '>> Press key to start <<','center',....
                    STIM.Screen.Center(2)-40,...
                    STIM.TextIntensity);
                fprintf('\n>>Press key to start the experiment<<\n');

                % display reward color legend
                if STIM.Reward.ShowColorLegend
                    for i=[3 2 1] % draw in reverse order
                        Screen('FillRect', STIM.Screen.window,...
                            STIM.Reward.Indicator.Colors(i,:).*...
                            STIM.Screen.white,LegendRect{i});
                    end
                    % set text to be bigger
                    oldTextSize=Screen('TextSize', STIM.Screen.window,...
                        STIM.Feedback.TextSize(1));
                    oldTextStyle=Screen('TextStyle',STIM.Screen.window,1); %bold
                    % Draw text
                    Screen('DrawText',STIM.Screen.window,...
                        ['+' num2str(STIM.Reward.Values(1)) '  '],...
                        STIM.Screen.Center(1)+max(RewDMpix)/2,STIM.Screen.Center(2)-...
                        max(RewDMpix)/2,...
                        STIM.Reward.Indicator.Colors(1,:).*...
                        STIM.TextIntensity);
                    Screen('DrawText',STIM.Screen.window,...
                        ['+' num2str(STIM.Reward.Values(2)) '  '],...
                        STIM.Screen.Center(1)+max(RewDMpix)/2,STIM.Screen.Center(2)-...
                        STIM.Feedback.TextSize(1)/2,...
                        STIM.Reward.Indicator.Colors(2,:).*...
                        STIM.TextIntensity);
                    Screen('DrawText',STIM.Screen.window,...
                        ['+' num2str(STIM.Reward.Values(3)) '  '],...
                        STIM.Screen.Center(1)+max(RewDMpix)/2,STIM.Screen.Center(2)+...
                        max(RewDMpix)/2,...
                        STIM.Reward.Indicator.Colors(3,:).*...
                        STIM.TextIntensity,[],1);
                    % Set text size back to small
                    Screen('TextSize', STIM.Screen.window,oldTextSize);
                    Screen('TextStyle',STIM.Screen.window,0);
                end
                vbl = Screen('Flip', STIM.Screen.window);
                pause(.5);
                KbWait;while KbCheck;end
                Screen('FillRect',STIM.Screen.window,...
                    STIM.BackColor*STIM.Screen.white);
                vbl = Screen('Flip', STIM.Screen.window);
                % send message to eyelink
                if HARDWARE.EyelinkConnected
                    Eyelink('Message', 'StartFix');
                end
            end

            % Set inital key-status
            KeyWasDown=0;

            % Draw the fixation dot
            Screen('FillOval', STIM.Screen.window,...
                STIM.Fix.Color.*STIM.Screen.white,FixRect);
            vbl = Screen('Flip', STIM.Screen.window);
            LOG.Block(LOG.SesNr).Trial(TR).FixOnset = vbl;

            % Fixation phase all but first frame
            while vbl < LOG.Block(LOG.SesNr).Trial(TR).FixOnset+ ...
                    STIM.Timing(1)/1000 && QuitScript==0

                % Draw fix dot
                Screen('FillOval', STIM.Screen.window,...
                    STIM.Fix.Color.*STIM.Screen.white,FixRect);

                % draw cue if required
                % If reward cue is required, draw it
                if STIM.Conditions(Trials(TR),1)==1 && ...
                        vbl > LOG.Block(LOG.SesNr).Trial(TR).FixOnset+STIM.Reward.Indicator.TimeOffset/1000 && ...
                        (STIM.Reward.Indicator.Duration==0 || ...
                        vbl < LOG.Block(LOG.SesNr).Trial(TR).FixOnset+STIM.Reward.Indicator.Duration/1000)
                    % Draw reward value cue
                    Screen('DrawLines', STIM.Screen.window,...
                        CueXY,CuePen,CueColor);
                    % Detect cue onset
                    if CueOnsetDetected == 0
                        CueOnsetDetected  = 1;
                    end
                end

                % Check for key-presses
                [keyIsDown,secs,keyCode]=KbCheck; %#ok<*ASGLU>
                if keyIsDown && ~KeyWasDown
                    if keyCode(KeyBreak) %break when esc
                        QuitScript=1;break;
                    end
                    KeyWasDown=1;
                elseif keyIsDown && KeyWasDown
                    if keyCode(KeyBreak) %break when esc
                        QuitScript=1;break;
                    end
                end

                % Flip the screen buffer and get timestamp
                vbl = Screen('Flip', STIM.Screen.window);
                % Log cue onset
                if CueOnsetDetected == 1
                    LOG.Block(LOG.SesNr).Trial(TR).CueOnset = vbl;
                    CueOnsetDetected  = 2;
                end
            end

            %% Sample-phase
            StartSample=vbl;FirstSampleFlipDone=0;
            % determine target positions
            % all angles
            TargetAngles=zeros(STIM.NoOfTargets,1);
            % random first angle on circle
            if STIM.RandPosCircle
                TargetAngles(1)=rand(1)*2*pi/STIM.NoOfTargets;
            else
                TargetAngles(1)=STIM.FirstPosCircle*(2*pi/360);
            end
            % other angles on circle
            for i=2:STIM.NoOfTargets
                TargetAngles(i)=TargetAngles(1)+...
                    (2*pi/STIM.NoOfTargets)*(i-1);
            end
            % distance from center
            Radius = STIM.Target.DistFromCenter*STIM.Screen.Deg2Pix;
            RadiusCue = STIM.Reward.Indicator.DistanceFromFix*...
                STIM.Screen.Deg2Pix;
            % Cartesian coordinates
            [TargetX, TargetY] = pol2cart(TargetAngles,Radius);
            [CueX, CueY] = pol2cart(TargetAngles,RadiusCue);
            % Target rects
            for i=1:length(TargetX)
                TRect{i}=[...
                    STIM.Screen.Center(1)+TargetX(i)-...
                    STIM.Target.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(2)+TargetY(i)-...
                    STIM.Target.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(1)+TargetX(i)+...
                    STIM.Target.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(2)+TargetY(i)+...
                    STIM.Target.Size*STIM.Screen.Deg2Pix/2];
                TRect2{i}=[...
                    STIM.Screen.Center(1)+TargetX(i)-...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(2)+TargetY(i)-...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(1)+TargetX(i)+...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(2)+TargetY(i)+...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2];
            end
            % Source rect
            SRect=[...
                STIM.Screen.PixHeight/2-...
                STIM.Target.Size*STIM.Screen.Deg2Pix
                STIM.Screen.PixHeight/2-...
                STIM.Target.Size*STIM.Screen.Deg2Pix
                STIM.Screen.PixHeight/2+...
                STIM.Target.Size*STIM.Screen.Deg2Pix
                STIM.Screen.PixHeight/2+...
                STIM.Target.Size*STIM.Screen.Deg2Pix];
            % angles to use
            TargetDrawAngles=zeros(1,STIM.NoOfTargets);
            TargetDrawAngles(STIM.Conditions(Trials(TR),3))=...
                STIM.Conditions(Trials(TR),4);
            AnglesUsed=STIM.Conditions(Trials(TR),4);
            TarInd=1:STIM.NoOfTargets;
            TarInd(TarInd==STIM.Conditions(Trials(TR),3))=[];
            for i=TarInd;
                OK=0;
                while OK==0
                    %pick a random orientation from the possibilities
                    PickedAngle = ...
                        STIM.Target.Orientations(ceil(rand(1)*...
                        (length(STIM.Target.Orientations))));
                    if ~ismember(PickedAngle,AnglesUsed)
                        AnglesUsed=[AnglesUsed;PickedAngle];
                        TargetDrawAngles(i)=PickedAngle;
                        OK=1;
                    end
                end
            end

            % Cue rects
            for i=1:length(TargetX)
                CRect{i}=[...
                    STIM.Screen.Center(1)+CueX(i)-...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(2)+CueY(i)-...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(1)+CueX(i)+...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2
                    STIM.Screen.Center(2)+CueY(i)+...
                    STIM.Reward.Indicator.Size*STIM.Screen.Deg2Pix/2];
            end

            % log some target info
            LOG.Block(LOG.SesNr).Trial(TR).TargetsXY = [TargetX TargetY];
            LOG.Block(LOG.SesNr).Trial(TR).TargetsAngleOnCircle = ...
                TargetAngles*(360/(2*pi));
            LOG.Block(LOG.SesNr).Trial(TR).TargetOrientSample = ...
                TargetDrawAngles;

            %Start drawing
            while vbl<StartSample+STIM.Timing(2)/1000 && QuitScript==0

                % if cues should be incorporated: use different
                % contrasts, else use middle contrast for all

                if STIM.Conditions(Trials(TR),1)==2 % use contrasts
                    % draw targets
                    for nT=1:STIM.NoOfTargets
                        % grating
                        Screen('DrawTexture',STIM.Screen.window, ...
                            STIM.Target.GratingTexture{RVS_TLS(nT,1)}, ...
                            SRect,TRect{nT},...
                            TargetDrawAngles(nT));
                        % mask
                        Screen('DrawTexture',STIM.Screen.window, ...
                            STIM.Target.MaskTexture, ...
                            SRect,TRect{nT},...
                            TargetDrawAngles(nT));
                    end
                else
                    % draw targets
                    for nT=1:STIM.NoOfTargets
                        % grating
                        Screen('DrawTexture',STIM.Screen.window, ...
                            STIM.Target.GratingTexture{2}, ...
                            SRect,TRect{nT},...
                            TargetDrawAngles(nT));
                        % mask
                        Screen('DrawTexture',STIM.Screen.window, ...
                            STIM.Target.MaskTexture, ...
                            SRect,TRect{nT},...
                            TargetDrawAngles(nT));
                    end
                end

                % draw reward indicators if required
                if STIM.Conditions(Trials(TR),1)==2 && ...
                        vbl > StartSample-STIM.Screen.FrameDur+STIM.Reward.Indicator.TimeOffset/1000 && ...
                        (STIM.Reward.Indicator.Duration==0 || ...
                        vbl < StartSample+STIM.Reward.Indicator.Duration/1000)
                    for nT=1:STIM.NoOfTargets
                        % cue
                        %                                 Screen('FillOval',STIM.Screen.window, ...
                        %                                     STIM.Reward.Indicator.Colors(RVS_TLS(nT,1),:).*...
                        %                                     STIM.Screen.white, ...
                        %                                     CRect{nT});
                        Screen('FrameOval',STIM.Screen.window, ...
                            STIM.Reward.Indicator.Colors(RVS_TLS(nT,1),:).*...
                            STIM.Screen.white, ...
                            TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                            STIM.Screen.Deg2Pix);
                    end
                    % Detect cue onset
                    if CueOnsetDetected == 0
                        CueOnsetDetected  = 1;
                    end
                else % draw neutral circle
                    for nT=1:STIM.NoOfTargets
                        Screen('FrameOval',STIM.Screen.window, ...
                            STIM.Reward.Indicator.NeutralColor.*...
                            STIM.Screen.white, ...
                            TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                            STIM.Screen.Deg2Pix);
                    end
                end

                % draw fixation
                Screen('FillOval', STIM.Screen.window,...
                    STIM.Fix.Color.*STIM.Screen.white,FixRect);

                % Check for key-presses
                [keyIsDown,secs,keyCode]=KbCheck; %#ok<*ASGLU>
                if keyIsDown && ~KeyWasDown
                    if keyCode(KeyBreak) %break when esc
                        QuitScript=1;break;
                    end
                    KeyWasDown=1;
                elseif keyIsDown && KeyWasDown
                    if keyCode(KeyBreak) %break when esc
                        QuitScript=1;break;
                    end
                end

                % flip
                % Flip the screen buffer and get timestamp
                vbl = Screen('Flip', STIM.Screen.window);
                if FirstSampleFlipDone == 0
                    StartSample = vbl;
                    FirstSampleFlipDone = 1;
                    % Log sample onset
                    LOG.Block(LOG.SesNr).Trial(TR).SampleOnset = StartSample;
                    % send message to eyelink
                    if HARDWARE.EyelinkConnected
                        Eyelink('Message', 'StartSample');
                    end
                end
                % Log cue onset
                if CueOnsetDetected == 1
                    LOG.Block(LOG.SesNr).Trial(TR).CueOnset = vbl;
                    CueOnsetDetected  = 2;
                end
            end

            %% Memory-phase
            for MemoryPhase=1
                StartMemory=vbl;FirstSampleFlipDone=0;

                %Start drawing
                while vbl<StartMemory+STIM.Timing(3)/1000 && QuitScript==0

                    % draw fixation
                    Screen('FillOval', STIM.Screen.window,...
                        STIM.Fix.Color.*STIM.Screen.white,FixRect);

                    % draw reward indicators if required
                    if STIM.Conditions(Trials(TR),1)==3 && ...
                            vbl > StartMemory-STIM.Screen.FrameDur+STIM.Reward.Indicator.TimeOffset/1000 && ...
                            (STIM.Reward.Indicator.Duration==0 || ...
                            vbl < StartMemory+STIM.Reward.Indicator.Duration/1000)
                        for nT=1:STIM.NoOfTargets
                            % cue
                            %                                 Screen('FillOval',STIM.Screen.window, ...
                            %                                     STIM.Reward.Indicator.Colors(RVS_TLS(nT,1),:).*...
                            %                                     STIM.Screen.white, ...
                            %                                     CRect{nT});
                            Screen('FrameOval',STIM.Screen.window, ...
                                STIM.Reward.Indicator.Colors(RVS_TLS(nT,1),:).*...
                                STIM.Screen.white, ...
                                TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                                STIM.Screen.Deg2Pix);
                        end
                        % Detect cue onset
                        if CueOnsetDetected == 0
                            CueOnsetDetected  = 1;
                        end
                    else % draw neutral circle
                        for nT=1:STIM.NoOfTargets
                            Screen('FrameOval',STIM.Screen.window, ...
                                STIM.Reward.Indicator.NeutralColor.*...
                                STIM.Screen.white, ...
                                TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                                STIM.Screen.Deg2Pix);
                        end
                    end

                    % Check for key-presses
                    [keyIsDown,secs,keyCode]=KbCheck; %#ok<*ASGLU>
                    if keyIsDown && ~KeyWasDown
                        if keyCode(KeyBreak) %break when esc
                            QuitScript=1;break;
                        end
                        KeyWasDown=1;
                    elseif keyIsDown && KeyWasDown
                        if keyCode(KeyBreak) %break when esc
                            QuitScript=1;break;
                        end
                    end

                    % flip
                    % Flip the screen buffer and get timestamp
                    vbl = Screen('Flip', STIM.Screen.window);
                    if FirstSampleFlipDone == 0
                        StartMemory = vbl;
                        FirstSampleFlipDone = 1;
                        % Log sample onset
                        LOG.Block(LOG.SesNr).Trial(TR).MemoryOnset = StartMemory;
                        % send message to eyelink
                        if HARDWARE.EyelinkConnected
                            Eyelink('Message', 'StartMemory');
                        end
                    end
                    % Log cue onset
                    if CueOnsetDetected == 1
                        LOG.Block(LOG.SesNr).Trial(TR).CueOnset = vbl;
                        CueOnsetDetected  = 2;
                    end
                end
            end

            %% Test-phase
            StartTest=vbl;FirstTestFlipDone=0;ResponseCollected=0;

            % Give the slected target a random starting angle
            TargetDrawAngles(STIM.Conditions(Trials(TR),3))=...
                rand(1)*360;
            Angle0=TargetDrawAngles(STIM.Conditions(Trials(TR),3));
            AngleToDraw=Angle0;

            % Log angles
            LOG.Block(LOG.SesNr).Trial(TR).TargetOrientTest = ...
                TargetDrawAngles;

            %Start drawing
            while ResponseCollected == 0 && QuitScript==0
                if STIM.Target.AllOnTest
                    nT=1:STIM.NoOfTargets;
                else
                    nT=STIM.Conditions(Trials(TR),3);
                end
                % draw targets
                for nT=nT
                    % grating
                    Screen('DrawTexture',STIM.Screen.window, ...
                        STIM.Target.GratingTexture{2}, ...
                        SRect,TRect{nT},...
                        TargetDrawAngles(nT));
                    % mask
                    Screen('DrawTexture',STIM.Screen.window, ...
                        STIM.Target.MaskTexture, ...
                        SRect,TRect{nT},...
                        TargetDrawAngles(nT));
                end

                % draw fixation
                Screen('FillOval', STIM.Screen.window,...
                    STIM.Fix.Color.*STIM.Screen.white,FixRect);

                % draw reward indicators if required
                if STIM.Conditions(Trials(TR),1)==4 && ...
                        vbl >= StartTest-STIM.Screen.FrameDur+STIM.Reward.Indicator.TimeOffset/1000  && ...
                        (STIM.Reward.Indicator.Duration==0 || ...
                        vbl < StartTest+STIM.Reward.Indicator.Duration/1000)
                    for nT=1:STIM.NoOfTargets
                        % cue
                        Screen('FrameOval',STIM.Screen.window, ...
                            STIM.Reward.Indicator.Colors(RVS_TLS(nT,1),:).*...
                            STIM.Screen.white, ...
                            TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                            STIM.Screen.Deg2Pix);
                    end
                    % Detect cue onset
                    if CueOnsetDetected == 0
                        CueOnsetDetected  = 1;
                    end
                else % draw neutral circle
                    for nT=1:STIM.NoOfTargets
                        Screen('FrameOval',STIM.Screen.window, ...
                            STIM.Reward.Indicator.NeutralColor.*...
                            STIM.Screen.white, ...
                            TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                            STIM.Screen.Deg2Pix);
                    end
                end

                % detect mouse button 1
                while (1) && FirstTestFlipDone && ...
                        ResponseCollected==0 && QuitScript==0
                    [x0,y0,buttons] = GetMouse(STIM.Screen.window);
                    if buttons(1)
                        break;
                    end
                    % Record keypress as response
                    [keyIsDown,secs,keyCode]=KbCheck;
                    if keyIsDown
                        if keyCode(KeyBreak) %break when escape is pressed
                            QuitScript=1;break;
                        else
                            ResponseCollected=1;
                            LOG.Block(LOG.SesNr).Trial(TR).RespAngle=...
                                AngleToDraw;
                            vbl = Screen('Flip', STIM.Screen.window);
                        end
                    end
                end

                while (1) && FirstTestFlipDone && ...
                        ResponseCollected==0 && QuitScript==0
                    [x,y,buttons] = GetMouse(STIM.Screen.window);
                    if ~buttons(1)
                        break;
                    end
                    if x ~= x0
                        dx=x0-x; %pos:ccw, neg:cw
                        dAngle=dx;
                        AngleToDraw=Angle0-dAngle;
                        % clear screen
                        Screen('FillRect',STIM.Screen.window,STIM.BackColor*STIM.Screen.white);

                        % draw fixation
                        Screen('FillOval', STIM.Screen.window,...
                            STIM.Fix.Color.*STIM.Screen.white,FixRect);

                        % grating
                        Screen('DrawTexture',STIM.Screen.window, ...
                            STIM.Target.GratingTexture{2}, ...
                            SRect,TRect{STIM.Conditions(Trials(TR),3)},...
                            AngleToDraw);
                        % mask
                        Screen('DrawTexture',STIM.Screen.window, ...
                            STIM.Target.MaskTexture, ...
                            SRect,TRect{STIM.Conditions(Trials(TR),3)},...
                            AngleToDraw);

                        % draw reward indicators if required
                        if STIM.Conditions(Trials(TR),1)==4
                            for nT=1:STIM.NoOfTargets
                                % cue
                                Screen('FrameOval',STIM.Screen.window, ...
                                    STIM.Reward.Indicator.Colors(RVS_TLS(nT,1),:).*...
                                    STIM.Screen.white, ...
                                    TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                                    STIM.Screen.Deg2Pix);
                            end
                            % Detect cue onset
                            if CueOnsetDetected == 0
                                CueOnsetDetected  = 1;
                            end
                        else % draw neutral circle
                            for nT=1:STIM.NoOfTargets
                                Screen('FrameOval',STIM.Screen.window, ...
                                    STIM.Reward.Indicator.NeutralColor.*...
                                    STIM.Screen.white, ...
                                    TRect2{nT},STIM.Reward.Indicator.LineWidth*...
                                    STIM.Screen.Deg2Pix);
                            end
                        end
                        vbl = Screen('Flip', STIM.Screen.window, 0, 1);
                    end
                    % Record keypress as response
                    [keyIsDown,secs,keyCode]=KbCheck;
                    if keyIsDown
                        if keyCode(KeyBreak) %break when escape is pressed
                            QuitScript=1;break;
                        else
                            ResponseCollected=1;
                            LOG.Block(LOG.SesNr).Trial(TR).RespAngle=...
                                AngleToDraw;
                            Screen('FillRect',STIM.Screen.window,...
                                STIM.BackColor*STIM.Screen.white);
                            vbl = Screen('Flip', STIM.Screen.window);
                        end
                    end
                end

                % Flip the screen buffer and get timestamp
                vbl = Screen('Flip', STIM.Screen.window);
                if FirstTestFlipDone == 0
                    StartTest = vbl;
                    FirstTestFlipDone = 1;
                    % Log test onset
                    LOG.Block(LOG.SesNr).Trial(TR).TestOnset = StartTest;
                    % send message to eyelink
                    if HARDWARE.EyelinkConnected
                        Eyelink('Message', 'StartTest');
                    end
                end

                % Log cue onset
                if CueOnsetDetected == 1
                    LOG.Block(LOG.SesNr).Trial(TR).CueOnset = vbl;
                    CueOnsetDetected  = 2;
                end
            end

            %% Feedback
            StartFeedback=vbl;FirstFBFlipDone=0;

            %Start drawing
            while vbl<StartFeedback+STIM.Timing(5)/1000 && QuitScript==0

                % convert angles to 0-180 range
                RespAng=AngleToDraw;
                StimAng=STIM.Conditions(Trials(TR),4);
                while RespAng < 0
                    RespAng=RespAng+180;
                end
                while RespAng > 180
                    RespAng=RespAng-180;
                end
                while StimAng < 0
                    StimAng=StimAng+180;
                end
                while StimAng > 180
                    StimAng=StimAng-180;
                end

                LOG.Block(LOG.SesNr).Trial(TR).StimAngle_RespAngle = ...
                    [StimAng RespAng];

                % If first frame, check if correct response
                if FirstFBFlipDone==0
                    RespDev=StimAng-RespAng;
                end

                if abs(RespDev) <= ...
                        STIM.Feedback.CorrectThreshold  && ...
                        FirstFBFlipDone==0
                    % correct
                    % check reward amount
                    RewardMagnitude=...
                        STIM.Reward.Values(STIM.Conditions(Trials(TR),2));
                    % prepare a number of dots equal to magnitude
                    AreaR = STIM.Feedback.AreaSize/2* STIM.Screen.Deg2Pix;
                    AnglesRew = rand(RewardMagnitude,1)*2*pi;
                    RadiusRew = rand(RewardMagnitude,1)*AreaR;
                    [RewX,RewY] = pol2cart(AnglesRew,RadiusRew);
                    RewY = RewY-...
                        (STIM.Feedback.AreaY*STIM.Screen.Deg2Pix);
                    Correct=1;
                    TotalReward = TotalReward + RewardMagnitude;
                    PotentialTotalReward = ...
                        PotentialTotalReward + RewardMagnitude;
                elseif FirstFBFlipDone==0 %wrong
                    Correct=0;
                    PotentialTotalReward = ...
                        PotentialTotalReward + ...
                        STIM.Reward.Values(STIM.Conditions(Trials(TR),2));
                end
                % set text to be bigger
                oldTextSize=Screen('TextSize', STIM.Screen.window,...
                    STIM.Feedback.TextSize(1));
                oldTextStyle=Screen('TextStyle',STIM.Screen.window,1); %bold

                if Correct
                    if STIM.Feedback.DotColorMatchesText
                        DotColor = ...
                            STIM.Reward.Indicator.Colors(RVS_TLS_ORG(1,1),:)...
                            *STIM.TextIntensity;
                    else
                        DotColor = STIM.Feedback.DotColor*STIM.Screen.white;
                    end

                    % draw a number of dots equal to magnitude
                    if ~isempty(RewX)
                        Screen('DrawDots', STIM.Screen.window,...
                            [RewX';RewY'], ...
                            STIM.Feedback.DotSize*STIM.Screen.Deg2Pix,...
                            DotColor(1:3),STIM.Screen.Center ,1);
                    end
                    % write reward obtained in text
                    DrawFormattedText(STIM.Screen.window,...
                        ['Correct: +' num2str(RewardMagnitude)],...
                        'center',STIM.Screen.Center(2)-...
                        STIM.Feedback.TextY(1),...
                        DotColor(1:3));

                    Screen('TextSize', STIM.Screen.window,...
                        STIM.Feedback.TextSize(2));
                    Screen('TextStyle',STIM.Screen.window,0);

                    DrawFormattedText(STIM.Screen.window,...
                        [num2str(TotalReward) ' / ' ...
                        num2str(PotentialTotalReward)],...
                        'center',STIM.Screen.Center(2)-...
                        STIM.Feedback.TextY(2),...
                        DotColor(1:3));
                else %wrong
                    % write reward obtained in text
                    DrawFormattedText(STIM.Screen.window,...
                        'Wrong: 0','center',STIM.Screen.Center(2)-...
                        STIM.Feedback.TextY(1),...
                        STIM.Feedback.DotColor*STIM.TextIntensity);

                    Screen('TextSize', STIM.Screen.window,...
                        STIM.Feedback.TextSize(2));
                    Screen('TextStyle',STIM.Screen.window,0);

                    DrawFormattedText(STIM.Screen.window,...
                        [num2str(TotalReward) ' / ' ...
                        num2str(PotentialTotalReward)],...
                        'center',STIM.Screen.Center(2)-...
                        STIM.Feedback.TextY(2),...
                        STIM.Feedback.DotColor*STIM.TextIntensity);
                end
                % Set text size back to small
                Screen('TextSize', STIM.Screen.window,oldTextSize);
                Screen('TextStyle',STIM.Screen.window,0);

                % Flip the screen buffer and get timestamp
                vbl = Screen('Flip', STIM.Screen.window);
                if FirstFBFlipDone == 0
                    StartFeedback = vbl;
                    FirstFBFlipDone = 1;
                    % Log test onset
                    LOG.Block(LOG.SesNr).Trial(TR).FeedBackOnset = ...
                        StartFeedback;
                    % send message to eyelink
                    if HARDWARE.EyelinkConnected
                        Eyelink('Message', 'StartFeedback');
                    end
                    % Log correct
                    LOG.Block(LOG.SesNr).Trial(TR).RespDev=RespDev;
                    LOG.Block(LOG.SesNr).Trial(TR).Correct=Correct;
                end
            end
        end
    end
    
    
    
    if QuitScript == 0
        vbl = Screen('Flip', STIM.Screen.window);
        DrawFormattedText(STIM.Screen.window,...
            'Thank you!','center','center',...
            [1 0 0]*STIM.TextIntensity);
        vbl = Screen('Flip', STIM.Screen.window);
        % send message to eyelink
        if HARDWARE.EyelinkConnected
            Eyelink('Message', 'EndExperiment');
        end
        pause(2)
    else
        vbl = Screen('Flip', STIM.Screen.window);
        DrawFormattedText(STIM.Screen.window,...
            'Exiting...','center','center',STIM.TextIntensity);
        vbl = Screen('Flip', STIM.Screen.window);
    end
    pause(.5)

    %% Save the data
    % only save data when experiment is completed
    save(LOG.FileName,'HARDWARE','STIM','LOG');


    %% Restore screen
    Screen('LoadNormalizedGammaTable',...
        STIM.Screen.ScrNr,OLD_Gamtable);
    Screen('CloseAll');
    ListenChar();ShowCursor;

    if QuitScript == 0
        fprintf('All done! Thank you for participating\n');
    else
        fprintf('Quit the script by pressing escape\n');
    end

    %% Close up Eyelink
    if HARDWARE.EyelinkConnected
        cd 'Eyelink_Log';
        Eyelink('Stoprecording');
        Eyelink('Closefile');
        if ~QuitScript || QuitScript % only save when experiment finished
            eyelink_receive_file(EL.edfFile);
            eval(['!rename ',EL.edfFile,'.edf ',LOG.FileName,'.edf'])
            disp(['Eyedata data saved under the name: ' LOG.FileName])
        end
        Eyelink('ShutDown');
        cd(DataFolder);
    end
catch %#ok<CTCH> %if there is an error the script will go here
    Screen('LoadNormalizedGammaTable',...
        STIM.Screen.ScrNr,OLD_Gamtable);
    Screen('CloseAll');
    ListenChar();ShowCursor;
    psychrethrow(psychlasterror);
    %% Close up Eyelink
    if HARDWARE.EyelinkConnected
        Eyelink('Stoprecording');
        Eyelink('Closefile');
        Eyelink('ShutDown');
    end
end
cd(StartFolder); % back to where we started