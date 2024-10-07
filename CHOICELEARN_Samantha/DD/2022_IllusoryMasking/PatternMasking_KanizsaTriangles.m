%% ILLUSORY MASKING: PATTERN MASKING WITH KANIZSA squares
% By Doris Dijksterhuis
% Version 20220309
% @Netherlands Institute for Neuroscience

% QUESTION: is it possible to use an illusory surface (like the Kanizsa
% squares) to mask a target and does it work as good as actual
% surfaces/objects?

% Hirose (2009) showed that illusory objects can cause object substition
% masking. Therefore, I expect that the Kanizsa squares will be able to
% elicit pattern masking as well. However, the question is what the degree
% of masking is compared to a real surface/object.

%% Directories/Start
dbstop if error
clear all
% Real experiment or debugging?
dbug = 1;

% Directories
list = {'psychroom','Doris PC'};
[indx,~] = listdlg('ListString',list);
switch indx
    case 2
        dropboxdir = 'C:\Users\dijksterhuis\Dropbox\NIN PhD\HumanPatExps';
        addpath(genpath('M:\MatlabFiles\CogGphTB\')) % Cogent
        addpath([dropboxdir,'\2022_IllusoryMasking']) % study specific folder
    case 1
        addpath(genpath(' D:\Doris D\2022_IllusoryMasking\'))
end

% How and where to save new data

% Open Cogent
cgloadlib
cgopen(3,0,0,1-dbug) % Open the cogent window
cogstd('sPriority','high')
% Colors
bg          = [1,1,1];
inducers    = [0,0,0];
realSquare  = [0.5,0.5,0.5];

% Sizes (= Sz)
spriteSz        = 250;
sqHalfWidth     = 50; % square half width
inducerSz       = 60;
tarSz           = 25; % target
fixSz           = 5; % fixation cross

% Timings
Hz = 59.92; % adjust to computer screen
Flip = 1/Hz;
tarFlip     = [2 3 4 5 4 6 7 8];
intFlip     = 0;
fixFlip     = round(0.5/Flip); % 0.5seconds
maskFlip    = round(0.3/Flip); %300miliseconds (like Enns&DiLollo), 2000)
isiFlip     = round(1/Flip); % 1second

%% Create stimuli etc
% MASKS
% IM = Illusory Kanizsa Square Mask
cgflip(bg)
cgmakesprite(1,spriteSz,spriteSz,bg)
cgsetsprite(1)
cgpencol(inducers)
cgellipse(-sqHalfWidth,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth,-sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(-sqHalfWidth,-sqHalfWidth,inducerSz,inducerSz,'f')
cgpencol(bg)
cgrect(0,0,2*sqHalfWidth,2*sqHalfWidth)
cgsetsprite(0)

% RM = Real Square Mask
cgflip(bg)
cgmakesprite(2,spriteSz,spriteSz,bg)
cgsetsprite(2)
cgpencol(inducers)
cgellipse(-sqHalfWidth,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth,-sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(-sqHalfWidth,-sqHalfWidth,inducerSz,inducerSz,'f')
cgpencol(realSquare)
cgrect(0,0,2*sqHalfWidth,2*sqHalfWidth)
cgsetsprite(0)

% TARGET
cgflip(bg)
cgmakesprite(3,spriteSz,spriteSz,bg)
cgsetsprite(3)
cgpencol(inducers)
cgellipse(0,0,tarSz,tarSz)
cgsetsprite(0)

% Fixation cross
cgmakesprite(4,spriteSz,spriteSz,bg)
cgsetsprite(4)
cgpencol(inducers)
cgpenwid(2)
cgdraw(0,fixSz,0,-fixSz)
cgdraw(fixSz,0,-fixSz,0)
cgsetsprite(0)

% Try out
% cgdrawsprite(4,0,0)
% cgflip(bg)

%% Design
repeats = 10;

% Create conditions
dets = [];
for r = 1:repeats
    for m = 1:2 % mask types
        for t = 1:length(tarFlip)
            dets = [dets; m,tarFlip(t)];
        end
    end
end
order = randperm(length(dets));
randtab = dets(order,:);

%% Start experiment
% Introduction text

% Trials
for trial = 1:length(randtab)
    
    
    % List of variables used in loop
    mask = randtab(trial,1);
    
    % Show the fixation cross
    for f = 1:fixFlip
        cgdrawsprite(4,0,0)
        cgflip
    end
    
    % TARGET PRESENTATION
    for t = 1:tarFlip
        cgdrawsprite(3,0,0)
        cgflip
    end
    
    %INTERVAL
    for i = 1:intFlip
        cgflip(bg)
    end
    
    % MASK PRESENTATION
    for m = 1:maskFlip
        cgdrawsprite(mask,0,0)
        cgflip
    end
    
   
    % RESPONSE INTERVAL
    for i = 1:intFlip
        cgflip(bg)
    end
    
    % Get response
    [kd,kp] = cgkeymap;
    response = NaN;
    while 1
        [kd,kp] = cgkeymap;
        kp = find(kp);
        if length(kp) == 1
            switch kp
                case 72
                    response = 1; % Arrow up button
                    break
                case 80
                    response = 0; % Arrow down button
                    break
                case 1 % Escape button
                    cgshut
                    return
            end
        end
    end
    
    % Save response in a way it can be checked later
    
    % BREAK (in the middle of the experiment)
   
    for f = 1:isiFlip
        cgflip(bg)
    end
       
end

% Show end text
cgfont('Arial',30)
cgtext('Thank you for participating!',0,0)
cgflip

% Let the sprite dissapear after 3 seconds and shut down the window
pause(3)
cgshut

