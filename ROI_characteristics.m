function [ noise, meanSignal] = ROI_characteristics( balancedFrame,debayerFrame,highPass,bayer,displayHistogram)
% compute standard deviation of noise and signal insde a ROI
% -balancedFrame: processed frame, used for ROI selection
% -debayerFrame: sensor raw frame, debayered with bilinear interpolation  (dcraw -r 1 1 1 1 -q 0 -o 0 -v -4 -T 
% -highPass: high-passed version of debayerFrame, containing the noise
% -bayer: bayer masks 

[I2, ROIcoords]=imcrop(uint16(balancedFrame));
ROIcoords=uint16(ROIcoords);

% crop images to ROI
ROI(:,:,1)=highPass(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),1);
ROI(:,:,2)=highPass(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),2);
ROI(:,:,3)=highPass(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),3);

ROIMask(:,:,1)=bayer(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),1);
ROIMask(:,:,2)=bayer(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),2);
ROIMask(:,:,3)=bayer(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),3);

ROIdebayer(:,:,1)=debayerFrame(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),1);
ROIdebayer(:,:,2)=debayerFrame(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),2);
ROIdebayer(:,:,3)=debayerFrame(ROIcoords(2):ROIcoords(2)+ROIcoords(4),ROIcoords(1):ROIcoords(1)+ROIcoords(3),3);

if(displayHistogram)
    % plot histograms of ROI
    figure(4)
    tmp=ROI(:,:,1);
    tmp=tmp(ROIMask(:,:,1));
    hist(tmp(:),-2000:2000)
    title('histogram of ROI, R channel')

    figure(5)
    tmp=ROI(:,:,2);
    tmp=tmp(ROIMask(:,:,2));
    hist(tmp(:),-2000:2000)
    title('histogram of ROI, G channel')

    figure(6)
    tmp=ROI(:,:,3);
    tmp=tmp(ROIMask(:,:,3));
    hist(tmp(:),-2000:2000)
    title('histogram of ROI, B channel')
end

% measure noise
noise(1)=std2_Mask(ROI(:,:,1),ROIMask(:,:,1))
noise(2)=std2_Mask(ROI(:,:,2),ROIMask(:,:,2))
noise(3)=std2_Mask(ROI(:,:,3),ROIMask(:,:,3))

% measure signal level
meanSignal(1)=mean(mean(ROIdebayer(:,:,1)))
meanSignal(2)=mean(mean(ROIdebayer(:,:,2)))
meanSignal(3)=mean(mean(ROIdebayer(:,:,3)))

end

