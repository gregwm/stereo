function D = edgeStereo(I1,I2)

    % Setup
    leftI = rgb2gray(imread(I1));
    rightI = rgb2gray(imread(I2));
    
    leftI = imadjust(leftI);
    rightI = imadjust(rightI);
    
    leftI = double(leftI);
    rightI = double(rightI);
    nRowsLeft = size(leftI, 1);
    nColsLeft = size(leftI, 2);
    
    % Gaussian Filter
    % leftI = imgaussfilt(leftI, 3);
    % rightI = imgaussfilt(rightI, 3);
    
    % Parameters
    halfBlockSize = 2;
    m = 2*halfBlockSize + 1;
    mask = ones(m, m);
    disparityRange = 64;

    hWaitBar = waitbar(0,'Starting block matching...');
    
    % Find the edges
    leftI_edge = edge(leftI, 'canny');
    DSI = zeros(nRowsLeft, nColsLeft, disparityRange + 1);
    
    for d = 0 : disparityRange
         % Take the right image and shift its columns
         % to the left by d
         shift = circshift(leftI, -d, 2); % Take the right image and shift by d columns to the right
         shift_edges = circshift(leftI_edge, -d, 2);
         
         % Find the difference between the first image and the shifted one
         diff = abs(rightI - shift);
         
         % Perform convolution
         tmp = imfilter(diff, mask);
         
         % Perform distance transform with the edge map
         [~,idx] = bwdist(shift_edges);
         
         % idx gives us the locations in the disparity we need to sample with
         tmp = tmp(idx);
         
         DSI(:,:,d+1) = tmp;
        
        waitbar((d + 1) / (disparityRange + 1), hWaitBar);
    end
    close(hWaitBar);
    
    % Find the disparity - must subtract by 1 for accounting for 0 shift
    [~, D] = min(DSI, [], 3);
    D = D - 1;
    D = D(:, 1:395);
    D = uint8(D);

    % Scale the images to the ground truth
    % the encoded disparity range is 0.25 .. 63.75 pixels of the ground
    % truth
    
    figure(1);
    clf;
    image(D);
    axis image;
    colormap('jet');
    colorbar;
    D = D*4;
end