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


%% Directories/Variables
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
bg          = [0.8,0.8,0.8];
inducers    = [0,0,0];
realSquare  = [0.5,0.5,0.5];

% Sizes (= Sz)
spriteSz        = 600;
sqHalfWidth     = 50; % square half width
inducerSz       = 60;
tarSz           = 35; % target
fixSz           = 10; % fixation cross

% Locations
latLoc = 150; % lateral location (left/right from fix cross)

% Timings
Hz = 59.92; % adjust to computer screen
Flip = 1/Hz;
tarFlip     = [1];% 2 3 4 5  6  8];
intFlip     = 0;
fixFlip     = round(0.5/Flip); % 0.5seconds
maskFlip    = round(0.3/Flip); %300miliseconds (like Enns&DiLollo), 2000)
isiFlip     = round(0.5/Flip); % 1second

%% Create stimuli etc
% MASKS
% IM = Illusory Kanizsa Square Mask
cgflip(bg)
cgmakesprite(1,spriteSz,spriteSz,bg)
cgsetsprite(1)
cgpencol(inducers)
% Left
cgellipse(-sqHalfWidth-latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth-latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth-latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(-sqHalfWidth-latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgpencol(bg)
cgrect(-latLoc,0,2*sqHalfWidth,2*sqHalfWidth)
% Right
cgpencol(inducers)
cgellipse(-sqHalfWidth+latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth+latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth+latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(-sqHalfWidth+latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgpencol(bg)
cgrect(latLoc,0,2*sqHalfWidth,2*sqHalfWidth)
cgsetsprite(0)

% RM = Real Square Mask
cgflip(bg)
cgmakesprite(2,spriteSz,spriteSz,bg)
cgsetsprite(2)
cgpencol(inducers)
% Left
cgellipse(-sqHalfWidth-latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth-latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth-latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(-sqHalfWidth-latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgpencol(realSquare)
cgrect(-latLoc,0,2*sqHalfWidth,2*sqHalfWidth)
% Right
cgpencol(inducers)
cgellipse(-sqHalfWidth+latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth+latLoc,sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(sqHalfWidth+latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgellipse(-sqHalfWidth+latLoc,-sqHalfWidth,inducerSz,inducerSz,'f')
cgpencol(realSquare)
cgrect(latLoc,0,2*sqHalfWidth,2*sqHalfWidth)
cgsetsprite(0)

% TARGETS
cgpenwid(1)
cgflip(bg)
cgmakesprite(3,spriteSz,spriteSz,bg)
cgsetsprite(3)
cgpencol(inducers)
cgellipse(-latLoc,0,tarSz,tarSz)
cgellipse(latLoc,0,tarSz,tarSz)
cgsetsprite(0)

% Fixation cross
cgmakesprite(4,fixSz*2,fixSz*2,bg)
cgsetsprite(4)
cgpencol(inducers)
cgpenwid(2)
cgdraw(0,fixSz,0,-fixSz)
cgdraw(fixSz,0,-fixSz,0)
cgsetsprite(0)

%% Design
repeats = 1;
leftright = [-1 1];
holeLoc = [0 20; -20 0; 0 -20; 20 0];

% Create conditions
dets = [];
for r = 1:repeats
    for m = 1:2 % mask types
        for s = 1:2 % target is left or right s
            for t = 1:length(tarFlip)
                for h = 1:4 % where is the hole in the target? left/right/up/down
                    dets = [dets; m,tarFlip(t),leftright(s),holeLoc(h,:)];
                end
            end
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
    mask        = randtab(trial,1);
    tarDur      = randtab(trial,2);
    tarSide     = randtab(trial,3);
    holeSide    = randtab(trial,[4 5]);
    
    % Show the fixation cross
    for f = 1:fixFlip
        cgdrawsprite(4,0,0)
        cgflip
    end
    
    % TARGET PRESENTATION
    for t = 1:tarDur
        cgdrawsprite(3,0,0)
        cgpencol(bg)
        x = (tarSide*latLoc)+holeSide(1);
        y = holeSide(2);
        cgellipse(x,y,tarSz-22,tarSz-15,'f')
        cgdrawsprite(4,0,0)
        cgflip
    end
    
    %INTERVAL
    for i = 1:intFlip
        cgdrawsprite(4,0,0)
        cgflip(bg)
    end
    
    % MASK PRESENTATION
    for m = 1:maskFlip
        cgdrawsprite(mask,0,0)
        cgdrawsprite(4,0,0)
        cgflip
    end
    
   
    % RESPONSE INTERVAL
    for i = 1:intFlip
        cgdrawsprite(4,0,0)
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
                case 75
                    response = 1; % Arrow left button
                    break
                case 77
                    response = 0; % Arrow right button
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
        cgdrawsprite(4,0,0)
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

