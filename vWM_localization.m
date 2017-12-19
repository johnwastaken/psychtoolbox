  %clear the workspace and the screen
sca;
close all;  
clearvars;

%% Modifiable variables

%define colors  
x= 255; % convert RGB values to percentage values
col.black = 0;
col.white = 1;
col.grey = [60/x, 60/x, 60/x];
colors(:,:,1)=[238/x 162/x 173/x; 205/x 38/x 38/x; 255/x 165/x 79/x; 205/x 133/x 0/x; 255/x 235/x 139/x; 205/x 105/x 201/x];
colors(:,:,2)=[107/x 142/x 35/x; 113/x 198/x 113/x; 3/x 168/x 158/x; 135/x 206/x 250/x; 125/x 38/x 205/x; 154/x 205/x 50/x];

%timing
fixationDuration = 1; %length of stage in seconds
rememberDuration = .2; 
retentionDuration = .9; 
recallDuration = 2;

%trial types (n = trpercond xl targ x dist) 
trpercond =  1; %trials per condition of practice
changeLocation = 6; %1=left, 2=right, 3=center
colorCategory = 2;

%determine the stim number
numStim = 6;

%% Collect subject information

prompt = {'Enter subject number', 'Practice? Y/N'}';
def={'99', 'Y'};
answer = inputdlg(prompt, 'Experimental setup information',1,def);
[subjID, prac]  = deal(answer{:});

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
stimRect = [0 0 1*ppd 1*ppd]; % Size of stimuli
sizeCircle = 3*ppd; % Size of the circlar array

%fixation cross info
lineWidthPix = 2;
fixCrossDimPix = 4 ;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
fixCoords = [xCoords; yCoords];

%import image files
load1Image = imread('media/load1.png', 'png');
load2Image = imread('media/load2.png', 'png');
load3Image = imread('media/load3.png', 'png');
load1Texture = Screen('MakeTexture', expWin, load1Image);
load2Texture = Screen('MakeTexture', expWin, load2Image);
load3Texture = Screen('MakeTexture', expWin, load3Image);

%% Timing information

ifi = Screen('GetFlipInterval', expWin);
topPriorityLevel = MaxPriority(expWin);
waitframes = 1;
fixationFrames = round(fixationDuration / ifi); %length of stage in frames
rememberFrames = round(rememberDuration / ifi);
retentionFrames = round(retentionDuration / ifi); %length of stage in frames
recallFrames = round(recallDuration / ifi);
vbl = Screen('Flip', expWin);

%% Create data file

if prac == 'N'
    trpercond = 8;
    fileName =['Results/' subjID '_CLTask.txt'];
    dataFile=fopen(fileName,'a+');
    fprintf(dataFile,'SubjectID\t Trial\t Change\t Response\t Accuracy\t X\t Y\t RT\n');
end

%% Matrix information

trmat=repmat(fullfact([changeLocation colorCategory]),trpercond,1) ; %make matrix
mixtr=trmat(randperm(length(trmat)),:); %randomize order

%%%%%%%%%%%%%%%%%%%%%%
%% Start Experiment %%
%%%%%%%%%%%%%%%%%%%%%%

HideCursor; 
clickResp = 0;
while  clickResp == 0
    %loading animation
    Screen('TextSize', expWin, 25);
    Screen('DrawTexture', expWin, load1Texture, [], []);
    DrawFormattedText(expWin, 'Press any button to begin the experiment...', 'center', ctrY+(ctrY*.25), col.white);
    Screen('Flip',expWin);
    WaitSecs(.05);    
    Screen('DrawTexture', expWin, load2Texture, [], []);    
    DrawFormattedText(expWin, 'Press any button to begin the experiment...', 'center', ctrY+(ctrY*.25), col.white);
    Screen('Flip',expWin);
    WaitSecs(.05);    
    Screen('DrawTexture', expWin, load3Texture, [], []);    
    DrawFormattedText(expWin, 'Press any button to begin the experiment...', 'center', ctrY+(ctrY*.25), col.white);
    Screen('Flip',expWin);
    WaitSecs(.05);
    [x,y,buttons]=GetMouse(); %waits for a key-press
    clickResp=any(buttons); %sets to 1 if a button was pressed
end

%show prefixation cross for first trial
for frame = 1:100
    Screen('FillRect', expWin, col.grey, [])
    Screen('DrawLines', expWin, fixCoords, lineWidthPix, col.white-.3, [ctrX ctrY], 2);
    Screen('Flip', expWin);
end

for trial=1:length(mixtr)

    %% Present stimuli BEGIN

    Priority(topPriorityLevel);
    ShowCursor;
    HideCursor;    
    curRun.trial(trial).trialNum = trial;

    %determine change location
    if mixtr(trial,1)==1
        changeLoc = 1;
    elseif mixtr(trial,1)==2
        changeLoc = 2;
    elseif mixtr(trial,1)==3
        changeLoc = 3;
    elseif mixtr(trial,1)==4
        changeLoc = 4;
    elseif mixtr(trial,1)==5
        changeLoc = 5;
    elseif mixtr(trial,1)==6
        changeLoc = 6;
    end

    %determine color set
    if mixtr(trial,2)==1
        arrayCol = 1;
        changeCol = 2;
    elseif mixtr(trial,2)==2
        arrayCol = 2;
        changeCol = 1;
    end
    
    %shuffle color order for all stim
    colorShuffle = Shuffle(1:6);
    
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

    %remember array
    circleCompute = (360/numStim)*pi/180; %computer angle and convert to radians    
    allCircs = zeros(4,numStim);
    for frame = 1:rememberFrames 
        for a=1:numStim
            circleDist = circleCompute*(a-round(numStim));
            circleX = sizeCircle*sin(circleDist)+ctrX;
            circleY = sizeCircle*cos(circleDist)+ctrY;
            allCircs(:,a) = CenterRectOnPointd(stimRect, circleX, circleY);
            Screen('FillOval', expWin, colors(colorShuffle(a),:,arrayCol), allCircs(:,a));           
        end
        Screen('DrawLines', expWin, fixCoords, lineWidthPix, col.white, [ctrX ctrY], col.white);
        Screen('DrawingFinished', expWin);
        vbl = Screen('Flip', expWin, vbl + (waitframes - 0.5) * ifi);
    end
    
    %retention
    for frame = 1:retentionFrames
        Screen('DrawLines', expWin, fixCoords, lineWidthPix, col.white, [ctrX ctrY], col.white);
        Screen('DrawingFinished', expWin);
        vbl = Screen('Flip', expWin, vbl + (waitframes - 0.5) * ifi);
    end
    
    %recall array
    for a=1:numStim
        circleDist = circleCompute*(a-round(numStim));
        circleX = sizeCircle*sin(circleDist)+ctrX;
        circleY = sizeCircle*cos(circleDist)+ctrY;
        allCircs(:,a) = CenterRectOnPointd(stimRect, circleX, circleY);
        Screen('FillOval', expWin, colors(colorShuffle(a),:,arrayCol), allCircs(:,a));           
    end
    Screen('FillOval', expWin, colors(colorShuffle(changeLoc),:,changeCol), allCircs(:,changeLoc));    
    Screen('DrawLines', expWin, fixCoords, lineWidthPix, col.white, [ctrX ctrY], col.white);
    Screen('DrawingFinished', expWin);
    vbl = Screen('Flip', expWin, vbl + (waitframes - 0.5) * ifi);

    %% Get Response
    
    SetMouse(ctrX, ctrY, expWin);
    ShowCursor('CrossHair');
    %WaitSecs(.1);
    startResp = GetSecs;
    clickResp = 0; 

    while clickResp == 0
        [clicks, mx, my, buttons]=GetClicks(expWin, .1);

        %determine which object was clicked 
        if mx > allCircs(1,1) && mx < allCircs(3,1) && my > allCircs(2,1) && my < allCircs(4,1)
            clickReport = 1;
        elseif mx > allCircs(1,2) && mx < allCircs(3,2) && my > allCircs(2,2) && my < allCircs(4,2)
            clickReport = 2;
        elseif mx > allCircs(1,3) && mx < allCircs(3,3) && my > allCircs(2,3) && my < allCircs(4,3)
            clickReport = 3;
        elseif mx > allCircs(1,4) && mx < allCircs(3,4) && my > allCircs(2,4) && my < allCircs(4,4)
            clickReport = 4;
        elseif mx > allCircs(1,5) && mx < allCircs(3,5) && my > allCircs(2,5) && my < allCircs(4,5)
            clickReport = 5;
        elseif mx > allCircs(1,6) && mx < allCircs(3,6) && my > allCircs(2,6) && my < allCircs(4,6)
            clickReport = 6;
        else
            clickReport = 0;
        end
        
        if any(buttons)
            clickLoc = [mx,my];
            clickTime = GetSecs-startResp;
        end
        
        if sum(clickReport) >0
            clickResp = 1;
        end
    end

    %% Print to console and file
    
    if clickReport == changeLoc
        Acc = 1;
    else
        Acc = 0;
    end
    
    disp(['Trial = ' num2str(trial)]);
    disp(['Change Location = ' num2str(changeLoc)]);
    disp(['Response = ' num2str(clickReport)]);
    disp(['Accuracy = ' num2str(Acc)]);
    disp('...');

    %% Print to file
    
    if prac == 'N'
        fprintf(dataFile, '%s\t %.0f\t %.0f\t %.0f\t %.0f\t %.0f\t %.0f\t %.0f\n', ...
        subjID, trial, changeLoc, clickReport, Acc, clickLoc(1), clickLoc(2), clickTime);
    end
    
end

%clear the screen
sca;
