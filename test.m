x = uigetfile ('*.*','All Files (*.*)');
%addpath('F:\Project\projects\testings\videos\working');
%addpath('F:\Project\projects\testings\videos\fails');
%--------------------Detect face using viola jones ---------------------------------%
% Create a cascade detector object.
faceDetector = vision.CascadeObjectDetector();

% Read a video frame and run the face detector.
videoFileReader = vision.VideoFileReader(x);
videoFrame      = step(videoFileReader);
bbox            = step(faceDetector, videoFrame);

%+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
faces = numel(bbox)/4;

for i=1:faces
    for j=1:4
        p(i,j)=bbox(i,j);
    end
end

%  Display the image and store its handle:
figure;

h_im = image(videoFrame);

%  Create an rectangle defining a ROI:
e=[];
hold on;
for i=1:faces
        e = imrect(gca,[p(i,1),p(i,2),p(i,3),p(i,4)]);
        
%  Create a mask from the rectangle:

        BW = createMask(e,h_im);

%  (For color images only) Augment the mask to three channels:

    BW(:,:,2) = BW;

BW(:,:,3) = BW(:,:,1);

%  Use logical indexing to set area outside of ROI to zero:

ROI = videoFrame;

ROI(BW == 0) = 0;
figure, imshow(ROI),title('ROI');
end

%  Display extracted portion:

