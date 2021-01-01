 clear classes;

    %%
faceDetector = vision.CascadeObjectDetector('trainedfacesorgoct28.xml'); % Finds faces by default
%faceDetector = vision.CascadeObjectDetector();
tracker = multiface;
faceDetector.MergeThreshold =9;

%% Get a frame for frame-size information

[file_name,file_path] = uigetfile ('*.*','All Files (*.*)');
inputFile = fullfile(file_path, file_name);
videoFileReader = VideoReader(inputFile);
frame = readFrame(videoFileReader);
frameSize = size(frame);
bbox            = step(faceDetector, frame);
frameh= frame;
%% Create a video player instance
videoPlayer  = vision.VideoPlayer('Position',[200 100 fliplr(frameSize(1:2)+30)]);

%% Iterate until we have successfully detected a face
bboxes = [];
while isempty(bboxes)
    framergb = readFrame(videoFileReader); 
    frame1 = rgb2gray(framergb);
    frame=wiener2(frame1,[5 5]);
    bboxes = faceDetector.step(frame);
end
tracker.addDetections(frame, frameh, bbox, bboxes);

%% And loop until the player is closed
frameNumber = 0;
keepRunning = true;
while keepRunning
    
    framergb = readFrame(videoFileReader); 
    frame1 = rgb2gray(framergb);
    frame=wiener2(frame1,[5 5]);
    if mod(frameNumber, 10) == 0
        % (Re)detect faces.
        %
        % NOTE: face detection is more expensive than imresize; we can
        % speed up the implementation by reacquiring faces using a
        % downsampled frame:
        % bboxes = faceDetector.step(frame);
        bboxes = 2 * faceDetector.step(imresize(frame, 0.5));
        if ~isempty(bboxes)
            tracker.addDetections(frame,frameh, bbox, bboxes);
        end
    else
        % Track faces
        tracker.track(frame);
    end
    
    % Display bounding boxes and tracked points.
    %displayFrame = insertObjectAnnotation(framergb, 'rectangle',...
    % tracker.Bboxes, tracker.BoxIds);
    displayFrame = insertObjectAnnotation(framergb, 'rectangle',...
     tracker.Bboxes,'faces');
% imshow(framergb);
%hold on;
%plot(tracker.Points,'r+');
     %displayFrame = insertMarker(displayFrame, tracker.Points);
    videoPlayer.step(displayFrame);
%videoPlayer.step(framergb);

    frameNumber = frameNumber + 1;
end

%% Clean up
release(videoPlayer);