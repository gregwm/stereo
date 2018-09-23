function D = gradientStereo(I1,I2)

    % Setup
    leftI = rgb2gray(imread(I1));
    rightI = rgb2gray(imread(I2));
    
    % Brightness test
    leftI = leftI + 75;
    
    leftI = imadjust(leftI); 
    rightI = imadjust(rightI);
       
    leftI = single(leftI);
    rightI = single(rightI);
    
    nRowsLeft = size(leftI, 1);
    nColsLeft = size(leftI, 2);
    
    % Parameters
    halfBlockSize = 2;
    m = 2*halfBlockSize + 1;
    mask_3d = ones(m, m, 2);
    disparityRange = 64;
    
    % Gradient based features
    [rGx, rGy] = imgradientxy(rightI);
    [lGx, lGy] = imgradientxy(leftI);
    
    hWaitBar = waitbar(0,'Starting block matching...');
    
    DSI = zeros(nRowsLeft, nColsLeft, disparityRange + 1);
    DSI2 = zeros(nRowsLeft, nColsLeft, disparityRange+1);
 
    for d = 0 : disparityRange
        
         % Shift left image to the left by d columns
         shift_x = circshift(lGx, -d, 2);
         shift_y = circshift(lGy, -d, 2);
         
         shift_x2 = circshift(rGx, d, 2);
         shift_y2 = circshift(rGy, d, 2);
         
         % Find the difference between the first image and the shifted one
         diff_x = abs(rGx - shift_x);
         diff_y = abs(rGy - shift_y);
         
         diff_x2 = abs(lGx - shift_x2);
         diff_y2 = abs(lGy - shift_y2);
         
         diff_x = padarray(diff_x, [halfBlockSize halfBlockSize]);
         diff_y = padarray(diff_y, [halfBlockSize halfBlockSize]);
         
         diff_x2 = padarray(diff_x2, [halfBlockSize halfBlockSize]);
         diff_y2 = padarray(diff_y2, [halfBlockSize halfBlockSize]);
         
         % Stack into 3D image
         diff = cat(3, diff_x, diff_y);
         diff2 = cat(3, diff_x2, diff_y2);
         
         % Perform convolution
         tmp = convn(diff, mask_3d, 'valid');
         tmp2 = convn(diff2, mask_3d, 'valid');
         
         % Add to DSI
         DSI(:,:,d+1) = tmp;
         DSI2(:,:,d+1) =tmp2;
         
         waitbar((d + 1) / (disparityRange + 1), hWaitBar);
    end
    
    close(hWaitBar);
    hWaitBar = waitbar(0,'Occlusion filling...');
    % Find the disparity - must subtract by 1 for accounting for 0 shift
    [~, D] = min(DSI, [], 3);
    D = D - 1;
    
    [~,D2] = min(DSI2, [], 3);
    D2 = D2 - 1;
    
    D = horzcat(D2(:,1:55), D);
    D3 = D;
    searchSize = 1;
    
    for rows=1:nRowsLeft
        minr = max(1,rows-searchSize);
        maxr = min(nRowsLeft, rows+searchSize);
        for cols=1:nColsLeft
            if(D(rows,cols)~=D2(rows,cols))
                minc = max(1, cols-searchSize);
                maxc = min(nColsLeft, cols+searchSize);
                % Disparity mis-match comment out to use different noise
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
    
    figure;
    clf;
    image(D);
    axis image;
    colormap('jet');
    colorbar;
    
    D = D*4;
end