function D = surfStereo(I1,I2)
    % This didn't work. Feel free to try anyway.
    % Setup
    leftI = rgb2gray(imread(I1));
    rightI = rgb2gray(imread(I2));
    
    leftI = imadjust(leftI); 
    rightI = imadjust(rightI);
    
    nRowsLeft = size(leftI, 1);
    nColsLeft = size(leftI, 2);
    
    imshow(leftI);
    hold on;
    
    leftI = single(leftI);
    rightI = single(rightI);
    
    pointsLeft = detectSURFFeatures(leftI, 'MetricThreshold', 0);
    pointsRight = detectSURFFeatures(rightI, 'MetricThreshold', 0);
   
    plot(pointsLeft);
   
    [featuresLeft, validPointsLeft] = extractFeatures(leftI, pointsLeft);
    [featuresRight, validPointsRight] = extractFeatures(rightI, pointsRight);
    validPointsLeft = floor(double(validPointsLeft.Location));
    validPointsRight = floor(double(validPointsRight.Location));
        
    % Parameters
    halfBlockSize = 15;
    m = 2*halfBlockSize + 1;
    
    % Create 3D Mask for convolution
    mask_3d = ones(m, m, 64);
    disparityRange = 50;
    
    % Create comparison images for SURF
    featuresImageLeft = zeros(nRowsLeft + m - 1, nColsLeft + m - 1, 64);
    featuresImageRight = zeros(nRowsLeft + m - 1, nColsLeft + m - 1, 64);
    
    % Create it
    for i = 1 : size(validPointsLeft, 1)
        row = validPointsLeft(i, 2) + halfBlockSize;
        col = validPointsLeft(i, 1) + halfBlockSize;
        featuresImageLeft(row, col, :) = featuresLeft(i, :);
    end
    
    for i = 1 : size(validPointsRight, 1)
        row = validPointsRight(i, 2) + halfBlockSize;
        col = validPointsRight(i, 1) + halfBlockSize;
        featuresImageRight(row, col, :) = featuresRight(i, :);
    end
    
    hWaitBar = waitbar(0,'Starting block matching...');
    
    DSI = zeros(nRowsLeft, nColsLeft, disparityRange + 1);
    for d = 0 : disparityRange
        
         % Shift left image to the left by d columns
         shift = circshift(featuresImageLeft, -d, 2);
     
         % Find the difference between the first image and the shifted one
         diff = abs(featuresImageRight - shift);
         
         % Perform convolution
         tmp = convn(diff, mask_3d, 'valid');
         
         % Add to DSI
         DSI(:,:,d+1) = tmp;
         
         waitbar((d + 1) / (disparityRange + 1), hWaitBar);
    end
    close(hWaitBar);
    
    % Find the disparity - must subtract by 1 for accounting for 0 shift
    [~, D] = min(DSI, [], 3);
    D = D - 1;
    
    figure;
    clf;
    image(D);
    axis image;
    colormap('jet');
    colorbar;
end