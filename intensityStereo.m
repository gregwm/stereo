function D = intensityStereo(I1,I2)

    % Setup
    leftI = rgb2gray(imread(I1));
    rightI = rgb2gray(imread(I2));

    leftI = imadjust(leftI); 
    rightI = imadjust(rightI);
   
    leftI = single(leftI);
    rightI = single(rightI);
    
    nRowsLeft = size(leftI, 1);
    nColsLeft = size(leftI, 2);
    
    % Parameters
    halfBlockSize = 1;
    m = 2*halfBlockSize + 1;
    mask = ones(m, m);
    disparityRange = 64;
    
    hWaitBar = waitbar(0,'Starting block matching...');
    
    DSI = zeros(nRowsLeft, nColsLeft, disparityRange + 1);
    DSI2 = zeros(nRowsLeft, nColsLeft, disparityRange+1);
    
    for d = 0 : disparityRange
        
         % Shift left image to the right by d columns
         shift = circshift(leftI, -d, 2); % Take the right image and shift by d columns to the right
         % Do opposite for occlusion filling
         shift2 = circshift(rightI, d, 2);
         
         % Find the difference between the first image and the shifted one
         diff = abs(rightI - shift);
         diff2 = abs(leftI - shift2);
         
         % Perform convolution
         tmp = imfilter(diff, mask);
         tmp2 = imfilter(diff2, mask);
         
         DSI(:,:,d+1) = tmp;
         DSI2(:,:,d+1) = tmp2;
         
         waitbar((d + 1) / (disparityRange + 1), hWaitBar);
    end
    close(hWaitBar);
    hWaitBar = waitbar(0,'Occlusion filling...');
    
    % Find the disparity - must subtract by 1 for accounting for 0 shift
    [~, D] = min(DSI, [], 3);
    [~, D2] = min(DSI2, [], 3);
    
    D = D - 1;
    D2 = D2 - 1;
    
    D = horzcat(D2(:,1:55), D);
    D3 = D;
    searchSize = 1;
    
    % Occlusion Filling Algorithm
    % Use both left-right and right-left map
    % If pixel disparities are different
    % Use function to decide which window contains noise/occlusion
    % Use opposite window
    for rows=1:nRowsLeft
        minr = max(1,rows-searchSize);
        maxr = min(nRowsLeft, rows+searchSize);
        for cols=1:nColsLeft
            if(D(rows,cols)~=D2(rows,cols))
                minc = max(1, cols-searchSize);
                maxc = min(nColsLeft, cols+searchSize);
                % Disparity mis-match - comment out to use different noise
                % identification functions
                D_window = length(unique(D(minr:maxr,minc:maxc)));
                D2_window = length(unique(D2(minr:maxr,minc:maxc))); 
	            %D_window = D(minr:maxr,minc:maxc);
                %D_window = var(D_window(:));
                %D_window = std(D_window(:));
                %D2_window = D2(minr:maxr,minc:maxc); 
                %D2_window = var(D2_window(:));
                %D2_window = std(D2_window(:));
               % D_window = D_window*threshold;
    
                if(D_window>D2_window)
                   D3(rows,cols) = D2(rows,cols);
                else
                   D3(rows,cols) = D(rows,cols);
                end
            end
        end
        waitbar((rows) / (nRowsLeft), hWaitBar);
        
    end
    
    close(hWaitBar);
    
    D3 = D3(:, 56:nColsLeft);
    D = uint8(D3);
    figure(1);
    clf;
    image(D);
    axis image;
    colormap('jet');
    colorbar;
    % For ground-truth evaluation
    D = D * 4;
end