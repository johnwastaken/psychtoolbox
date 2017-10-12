% Clear the workspace and the screen
sca;
close all;
clearvars;

%% Modifiable variables

%define colors
x= 255; % convert RGB values to percentage values
col.black = 0;
col.white = 1;
col.grey = .6;
col.red    = [185/x 35/x 42/x];       %   18.1	.604	.337
col.green  = [0 112/x 0];       %   18.2	.290	.633
col.gold   = [115/x 95/x 0];      %   18.3	.458	.495

%timing
fixationDuration = 1; %length of stage in seconds
targDuration = 2;

%trial types (n = trpercond x targ x dist)
trpercond =  4; %trials per condition
targ = 3; %1=left, 2=right, 3=center
dist = 2; %1=left, 2=right

%determine the stim number
numStim = 10;
locLeft = [6 7 8 9];
locRight = [1 2 3 4];
locMid = [5 10];

%% Screen setup

PsychDefaultSetup(2);
scrID = max(Screen('Screens'));
scrHz = Screen('FrameRate',scrID);
if scrHz > 0
    Screen('Preference', 'SkipSyncTests', 0);
else
    Screen('Preference', 'SkipSyncTests', 1);
end
[expWin,rect] = PsychImaging('OpenWindow', scrID, col.black);
Screen('BlendFunction', expWin, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%determine resolution and pixels per degree (ppd)
[resVal(1), resVal(2)] = Screen('WindowSize', expWin);
mon_width = 53.133;   % horizontal dimension of viewable screen (cm)
v_dist = 100;   % viewing distance (cm)
ppd = round(pi * resVal(1) / atan(mon_width/v_dist/2) / 360);
ctrX = resVal(1)/2;
ctrY = resVal(2)/2;

%% Stimulus Setup

%circle stimuli
stimRect = [0 0 1.7*ppd 1.7*ppd]; % Size of stimuli
lineRect = [0 0 1*ppd .06*ppd; 0 0 .06*ppd 1*ppd];
sizeCircle = 4.6*ppd; % Size of the circlar array
circleWidth = .06*ppd;

%fixation cross info
lineWidthPix = 2;
fixCrossDimPix = 4 ;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
fixCoords = [xCoords; yCoords];

%% Timing information

ifi = Screen('GetFlipInterval', expWin);
topPriorityLevel = MaxPriority(expWin);
waitframes = 1;
fixationFrames = round(fixationDuration / ifi); %length of stage in frames
targFrames = round(targDuration / ifi);
vbl = Screen('Flip', expWin);

%% Matrix information

trmat=repmat(fullfact([targ dist]),trpercond,1) ; %make matrix
mixtr=trmat(randperm(length(trmat)),:); %randomize order

%%%%%%%%%%%%%%%%%%%%%%
%% Start Experiment %%
%%%%%%%%%%%%%%%%%%%%%%

%show prefixation cross for first trial
for frame = 1:100
    Screen('DrawLines', expWin, fixCoords, lineWidthPix, col.white-.3, [ctrX ctrY], 2);
    Screen('Flip', expWin);
end

for trial=1:length(mixtr)
    
    %shuffle locations
    randLeftLoc = Shuffle(locLeft);
    randRightLoc = Shuffle(locRight);
    randMidLoc = Shuffle(locMid);
    
    %set target location
    if mixtr(trial,1)==1
        targLoc = randLeftLoc(1);
    elseif mixtr(trial,1)==2
        targLoc = randRightLoc(1);
    elseif mixtr(trial,1)==3
        targLoc = randMidLoc(1);
    end
        
    %set distractor location
    if mixtr(trial,2)==1
        distLoc = randLeftLoc(2);
    elseif mixtr(trial,2)==2
        distLoc = randRightLoc(2);
    end
    
    %% Present stimuli BEGIN

    Priority(topPriorityLevel);
    curRun.trial(trial).trialNum = trial;
    
    %fixation
    jitter = [.100 .250];
    jitterDuration = rand(1,1)*range(jitter)+min(jitter);
    jitterFrames = round(jitterDuration / ifi);
    fixationFramesJittered = fixationFrames + jitterFrames;
    for frame = 1:fixationFramesJittered
        Screen('DrawLines', expWin, fixCoords, lineWidthPix, col.white, [ctrX ctrY], col.white);
        Screen('DrawingFinished', expWin);
        vbl = Screen('Flip', expWin, vbl + (waitframes - 0.5) * ifi);
    end

    %randomly orient line
    lineOrient = zeros(numStim,4);
    lineRecord = cell(1,numStim);
    for l=1:numStim
        randLine = randi(2);            
        if randLine == 1
            lineOrient(l,:) = lineRect(1,:);
            lineRecord{l} = 'horizonal';
        else
            lineOrient(l,:) = lineRect(2,:);
            lineRecord{l} = 'vertical';
        end
    end
    
    %target array
    circleCompute = (360/numStim)*pi/180; %computer angle and convert to radians    
    allCircs = zeros(4,numStim);
    allLines = zeros(4,numStim);
    for frame = 1:targFrames 
        for a=1:numStim
            circleDist = circleCompute*(a-round(numStim));
            circleX = sizeCircle*sin(circleDist)+ctrX;
            circleY = sizeCircle*cos(circleDist)+ctrY;
            allCircs(:,a) = CenterRectOnPointd(stimRect, circleX, circleY);
            Screen('FrameOval', expWin, col.green, allCircs(:,a), circleWidth);
            allLines(:,a) = CenterRectOnPointd(lineOrient(a,:), circleX, circleY);
            Screen('FillRect', expWin, col.grey, allLines(:,a));            
        end
        Screen('DrawLines', expWin, fixCoords, lineWidthPix, col.white, [ctrX ctrY], col.white);
        Screen('FrameOval', expWin, col.red, allCircs(:,distLoc), circleWidth);
        Screen('FrameOval', expWin, col.gold, allCircs(:,targLoc), circleWidth);
        Screen('DrawingFinished', expWin);
        vbl = Screen('Flip', expWin, vbl + (waitframes - 0.5) * ifi);
    end
    
    %print to console
    disp(['Trial = ' num2str(trial)]);
    disp(['Target Location = ' num2str(targLoc)]);
    disp(['Line orientation = ' num2str(lineRecord{targLoc})]);    
    disp(['Distractor Location = ' num2str(distLoc)]);
    disp(['Line orientation = ' num2str(lineRecord{distLoc})]);
    disp([' ']);
    
end

%clear the screen
sca;
