
%   Functions
%   addDetections - add detected bounding boxes
%   track         - track the objects

classdef multiface < handle     %class dwfinition
    properties
        % PointTracker A vision.PointTracker object
        PointTracker; 
        
        % Bboxes M-by-4 matrix of [x y w h] object bounding boxes
        Bboxes = [];
        
        % BoxIds M-by-1 array containing ids associated with each bounding box
        BoxIds = [];
        
        % Points M-by-2 matrix containing tracked points from all objects
        Points = [];
        
        
        % PointIds M-by-1 array containing object id associated with each 
        %   point. This array keeps track of which point belongs to which object.
        PointIds = [];
        
        % NextId The next new object will have this id.
        NextId = 1;
      %  cnt=0;thi
        % BoxScores M-by-1 array. Low box score means that we probably lost the object.
        BoxScores = [];
    end
    
    methods
        %------------------------------------------------------------------
        function this = multiface()
        % Constructor
            this.PointTracker = ...
                vision.PointTracker('MaxBidirectionalError', 2);
        end
        
        %------------------------------------------------------------------
        function addDetections(this, I, I1, bbox1, bboxes)
        % addDetections Add detected bounding boxes.
        % addDetections(tracker, I, bboxes) adds detected bounding boxes.
        % tracker is the MultiObjectTrackerKLT object, I is the current
        % frame, and bboxes is an M-by-4 array of [x y w h] bounding boxes.
        % This method determines whether a detection belongs to an existing
        % object, or whether it is a brand new object.
            for i = 1:size(bboxes, 1)
                % Determine if the detection belongs to one of the existing
                % objects.
                boxIdx = this.findMatchingBox(bboxes(i, :));
                  if isempty(boxIdx)
                    % This is a brand new object.
                    this.Bboxes = [this.Bboxes; bboxes(i, :)];
                     bw = im2bw(I, graythresh(I));   
                    region_borders = imdilate(bw,ones(3,3)) > imerode(bw,ones(3,3));%plot(region_borders);
                    points1 = detectMinEigenFeatures(region_borders, 'ROI', bboxes(i, :));
                    region_borders = edge(region_borders, 'Sobel');
                    %points1 = detectFASTFeatures(region_borders, 'ROI', bboxes(i, :));
                    faces = numel(bbox1)/4;

                    for i=1:faces
                        for j=1:4
                            p(i,j)=bbox1(i,j);
                        end
                    end

                    %  Display the image and store its handle:
                    figure;

                    h_im = image(I1);

                    %  Create an rectangle defining a ROI:

                    hold on;
                  %  points3 = detectHarrisFeatures(region_borders, 'ROI', bboxes(i, :));
                    points2 = [];
                    for i=1:faces
                            e = imrect(gca,[p(i,1),p(i,2),p(i,3),p(i,4)]);

                    %  Create a mask from the rectangle:

                            BW = createMask(e,h_im);

                    %  (For color images only) Augment the mask to three channels:

                        BW(:,:,2) = BW;

                    BW(:,:,3) = BW(:,:,1);

                    %  Use logical indexing to set area outside of ROI to zero:

                    ROI = I1;

                    ROI(BW == 0) = 0;
                    ROI= rgb2gray(ROI);

                    fx = [-1 0 1;-1 0 1;-1 0 1];
                    Ix = filter2(fx,ROI);
                    fy = [1 1 1;0 0 0;-1 -1 -1];
                    Iy = filter2(fy,ROI); 

                    Ix2 = Ix.^2;
                    Iy2 = Iy.^2;
                    Ixy = Ix.*Iy;
                    clear Ix;
                    clear Iy;

                    %applying gaussian filter on the computed value
                    h= fspecial('gaussian',[7 7],2); 
                    Ix2 = filter2(h,Ix2);
                    Iy2 = filter2(h,Iy2);
                    Ixy = filter2(h,Ixy);
                    height = size(ROI,1);
                    width = size(ROI,2);
                    result = zeros(height,width); 
                    R = zeros(height,width);

                    Rmax = 0; 
                    for i = 1:height
                    for j = 1:width
                    M = [Ix2(i,j) Ixy(i,j);Ixy(i,j) Iy2(i,j)]; 
                    R(i,j) = det(M)-0.01*(trace(M))^2;
                    if R(i,j) > Rmax
                    Rmax = R(i,j);
                    end;
                    end;
                    end;
                    cnt = 0;
                    for i = 2:height-1
                    for j = 2:width-1
                    if R(i,j) > 0.1*Rmax && R(i,j) > R(i-1,j-1) && R(i,j) > R(i-1,j) && R(i,j) > R(i-1,j+1) && R(i,j) > R(i,j-1) && R(i,j) > R(i,j+1) && R(i,j) > R(i+1,j-1) && R(i,j) > R(i+1,j) && R(i,j) > R(i+1,j+1)
                    result(i,j) = 1;
                    cnt = cnt+1;
                    end;
                    end;
                    end;
                    [posc, posr] = find(result == 1);
                    result1 = [posc,posr];
                    points2 = [points2;result1];
                    end

                    
                    [features1, valid_points1,ptVis1] = extractHOGFeatures(region_borders, points2);
                    % plot(ptVis1);
                    
                    ii=1;
                    jj=size(points2,1);
                    midrow=[];
                    while(ii<=size(points2,1) && jj>=1)
                        midrow(ii,:) = (points2(ii) + points2(jj))/2;
                         ii=ii+1;
                         jj=jj-1;
                    end
                   % midcorner=cornerPoints(midrow);
                      valid_points1 = cornerPoints(valid_points1);

                    try
                         midcorner=cornerPoints(midrow);
                        % points=[points1; valid_points1;midcorner];
                          points=[points1;points2;midcorner];
                     catch
                         points=[points1; valid_points1];
                      end
                    
                    
                    
                   % points=[points1; valid_points1;midcorner];
                   imshow(I)
                    hold on 
                    plot(points)
                    points = points.Location;
                    this.BoxIds(end+1) = this.NextId;
                    idx = ones(size(points, 1), 1) * this.NextId;
                    this.PointIds = [this.PointIds; idx];
                    this.NextId = this.NextId + 1;
                    this.Points = [this.Points; points];
                    this.BoxScores(end+1) = 1;
                    
                else % The object already exists.
                    
                    % Delete the matched box
                    currentBoxScore = this.deleteBox(boxIdx);
                    % Replace with new box
                    this.Bboxes = [this.Bboxes; bboxes(i, :)];
                    
                    % Re-detect the points. This is how we replace the
                    % points, which invariably get lost as we track.
                    bw = im2bw(I, graythresh(I));   
                    region_borders2 = imdilate(bw,ones(3,3)) > imerode(bw,ones(3,3));
                   points4 = detectMinEigenFeatures(region_borders2, 'ROI', bboxes(i, :));
                   region_borders2 = edge(region_borders2, 'Sobel');
                  %  points4 = detectFASTFeatures(region_borders2, 'ROI', bboxes(i, :));
                    
                     points5=detectHarrisFeatures(region_borders2, 'ROI', bboxes(i, :));
                    %[features1, valid_points2,ptVis1] = extractHOGFeatures(region_borders2, points3);
                    faces = numel(bbox1)/4;
                    for i=1:faces
                        for j=1:4
                            p(i,j)=bbox1(i,j);
                        end
                    end

                    %  Display the image and store its handle:
                    figure;

                    h_im = image(I1);

                    %  Create an rectangle defining a ROI:
                    hold on;

                    points3 =[];
                    for i=1:faces
                            e = imrect(gca,[p(i,1),p(i,2),p(i,3),p(i,4)]);

                    %  Create a mask from the rectangle:

                            BW = createMask(e,h_im);

                    %  (For color images only) Augment the mask to three channels:

                        BW(:,:,2) = BW;

                    BW(:,:,3) = BW(:,:,1);

                    %  Use logical indexing to set area outside of ROI to zero:

                    ROI = I1;

                    ROI(BW == 0) = 0;
                    ROI= rgb2gray(ROI);
                    fx = [-1 0 1;-1 0 1;-1 0 1];
                    Ix = filter2(fx,ROI);
                    fy = [1 1 1;0 0 0;-1 -1 -1];
                    Iy = filter2(fy,ROI); 

                    Ix2 = Ix.^2;
                    Iy2 = Iy.^2;
                    Ixy = Ix.*Iy;
                    clear Ix;
                    clear Iy;

                    %applying gaussian filter on the computed value
                    h= fspecial('gaussian',[7 7],2); 
                    Ix2 = filter2(h,Ix2);
                    Iy2 = filter2(h,Iy2);
                    Ixy = filter2(h,Ixy);
                    height = size(ROI,1);
                    width = size(ROI,2);
                    result = zeros(height,width); 
                    R = zeros(height,width);

                    Rmax = 0; 
                    for i = 1:height
                    for j = 1:width
                    M = [Ix2(i,j) Ixy(i,j);Ixy(i,j) Iy2(i,j)]; 
                    R(i,j) = det(M)-0.01*(trace(M))^2;
                    if R(i,j) > Rmax
                    Rmax = R(i,j);
                    end;
                    end;
                    end;
                    cnt = 0;
                    for i = 2:height-1
                    for j = 2:width-1
                    if R(i,j) > 0.1*Rmax && R(i,j) > R(i-1,j-1) && R(i,j) > R(i-1,j) && R(i,j) > R(i-1,j+1) && R(i,j) > R(i,j-1) && R(i,j) > R(i,j+1) && R(i,j) > R(i+1,j-1) && R(i,j) > R(i+1,j) && R(i,j) > R(i+1,j+1)
                    result(i,j) = 1;
                    cnt = cnt+1;
                    end;
                    end;
                    end;
                    [posc, posr] = find(result == 1);
                    result1 = [posc,posr];
                    points3 = [points3;result1];
                    end
                    %ii=1;
                    %jj=size(points4,2);
                   % midrow2=[];
                   % while(ii<=size(points4,2) && jj>=1)
                   %     midrow2(ii,:) = (points4(ii).Location + points4(jj).Location)/2;
                   %      ii=ii+1;
                   %      jj=jj-1;
                   % end
                    % midcorner2=cornerPoints(midrow2);
                    
                    points3=cornerPoints(points3);
                    points=[points4;points5];
                    
                  % points=[points4; valid_points2];
                   % plot(ptVis1);
                     imshow(I)
                    hold on 
                    plot(points)
                  
                    points = points.Location;
                    this.BoxIds(end+1) = boxIdx;
                    idx = ones(size(points, 1), 1) * boxIdx;
                    this.PointIds = [this.PointIds; idx];
                    this.Points = [this.Points; points];                    
                    this.BoxScores(end+1) = currentBoxScore + 1;
                    %oldpoints=points;
                end
            end
            
            % Determine which objects are no longer tracked.
            minBoxScore = -2;
            this.BoxScores(this.BoxScores < 3) = ...
                this.BoxScores(this.BoxScores < 3) - 0.5;
            boxesToRemoveIds = this.BoxIds(this.BoxScores < minBoxScore);
            while ~isempty(boxesToRemoveIds)
                this.deleteBox(boxesToRemoveIds(1));
                boxesToRemoveIds = this.BoxIds(this.BoxScores < minBoxScore);
            end
            
            % Update the point tracker.
            if this.PointTracker.isLocked()
                this.PointTracker.setPoints(this.Points);
            else
                this.PointTracker.initialize(this.Points, I);
            end
        end
                
        %------------------------------------------------------------------
        function track(this, I)
        % TRACK Track the objects.
        % TRACK(tracker, I) tracks the objects into frame I. tracker is the
        % MultiObjectTrackerKLT object, I is the current video frame. This
        % method updates the points and the object bounding boxes.
            [newPoints, isFound] = this.PointTracker.step(I);
            this.Points = newPoints(isFound, :);
            this.PointIds = this.PointIds(isFound);
            generateNewBoxes(this);
            if ~isempty(this.Points)
                this.PointTracker.setPoints(this.Points);
            end
        end
    end
    
    methods(Access=private)        
        %------------------------------------------------------------------
        function boxIdx = findMatchingBox(this, box)
           
        % Determine which tracked object (if any) the new detection belongs to. 
            boxIdx = [];
            for i = 1:size(this.Bboxes, 1)
                area = rectint(this.Bboxes(i,:), box);                
                if area > 0.2* this.Bboxes(i, 3) * this.Bboxes(i, 4) 
                   % cnt=cnt+1;
                   boxIdx = this.BoxIds(i);
                    return;
                end
            end           
        end
        
        %------------------------------------------------------------------
        function currentScore = deleteBox(this, boxIdx)            
        % Delete object.
            this.Bboxes(this.BoxIds == boxIdx, :) = [];
            this.Points(this.PointIds == boxIdx, :) = [];
            this.PointIds(this.PointIds == boxIdx) = [];
            currentScore = this.BoxScores(this.BoxIds == boxIdx);
            this.BoxScores(this.BoxIds == boxIdx) = [];
            this.BoxIds(this.BoxIds == boxIdx) = [];
            
        end
        %------------------------------------------------------------------
        function generateNewBoxes(this)  
        % Get bounding boxes for each object from tracked points.
            oldBoxIds = this.BoxIds;
            oldScores = this.BoxScores;
            this.BoxIds = unique(this.PointIds);
            numBoxes = numel(this.BoxIds);
            this.Bboxes = zeros(numBoxes, 4);
            this.BoxScores = zeros(numBoxes, 1);
            for i = 1:numBoxes
                points = this.Points(this.PointIds == this.BoxIds(i), :);
                newBox = getBoundingBox(points);
                this.Bboxes(i, :) = newBox;
                this.BoxScores(i) = oldScores(oldBoxIds == this.BoxIds(i));
            end
        end 
    end
end

%--------------------------------------------------------------------------
function bbox = getBoundingBox(points)
x1 = min(points(:, 1));
y1 = min(points(:, 2));
x2 = max(points(:, 1));
y2 = max(points(:, 2));
bbox = [x1 y1 x2-x1 y2-y1];
end