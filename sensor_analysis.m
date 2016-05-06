%% script to analyse a sensor noise and sensitivity

%% algorithm short description:
%   -1) load bayer matrix for sensor, dark frame, raw signal frame and
%   debayered signal frame
%   -2) compute sum of read noise, uncorrected fixed pattern noise and dark noise from dark frame
%   -3) compute signal and remaining noise from a long exposure sky
%   photograph, in several different ROIs
%   -4) assess if sensor is quantum-limited and compute sensor gain

clear, clc

% 1) load images
bayer(:,:,1)=logical(imread('nikon_1j2_bayer_R.tif'));
% bayer mask for red channel
bayer(:,:,2)=logical(imread('nikon_1j2_bayer_G.tif'));
% bayer mask for green channel
bayer(:,:,3)=logical(imread('nikon_1j2_bayer_B.tif'));
% bayer mask for blue channel
dark=double(imread('2016 4 30 malakoff\DSC_2505.tiff'));
% dark frame, debayered with bilinear interpolation (dcraw -r 1 1 1 1 -q 0 -o 0 -v -4 -T 
debayerFrame=double(imread('2016 4 30 malakoff\DSC_2504_debayer.tiff'));
% sensor raw frame, debayered with bilinear interpolation 
balancedFrame=double(imread('2016 4 30 malakoff\DSC_2504_balanced.tiff'));
% processed version of debayerFrame, adjusted for display

% correct for scaling of dcraw
dark=dark/16;
debayerFrame=debayerFrame/16;

%% plot histograms of dark frame
figure(1)
tmp=dark(:,:,1);
tmp=tmp(bayer(:,:,1));
hist(tmp(:),0:200)
title('histogram of dark, R channel')

figure(2)
tmp=dark(:,:,2);
tmp=tmp(bayer(:,:,2));
hist(tmp(:),0:200)
title('histogram of dark, G channel')

figure(3)
tmp=dark(:,:,3);
tmp=tmp(bayer(:,:,3));
hist(tmp(:),0:200)
title('histogram of dark, B channel')

%% 2) compute noise in dark frame, taking into account clipping of negative values 
% clipping occurs due to Fixed Pattern Noise Reduction (dark frame subtraction) in camera, when FPNR
% is active
darkNoise(1)=std2_Mask(dark(:,:,1),bayer(:,:,1),'true')
darkNoise(2)=std2_Mask(dark(:,:,2),bayer(:,:,2),'true')
darkNoise(3)=std2_Mask(dark(:,:,3),bayer(:,:,3),'true')


%% 3) compute noise in signal frame
% create high-pass version of the frame to remove backround non-uniformity
% from noise calculation

lowPass(:,:,1)=double(medfilt2(uint16(debayerFrame(:,:,1)),[20 20]));
lowPass(:,:,2)=double(medfilt2(uint16(debayerFrame(:,:,2)),[20 20]));
lowPass(:,:,3)=double(medfilt2(uint16(debayerFrame(:,:,3)),[20 20]));

highPass=debayerFrame-lowPass;

noise=[];
meanSignal=[];
nROI=10;

%select a ROI to show noise histogram
ROI_characteristics( balancedFrame,debayerFrame,highPass,bayer,true);

for i=1:nROI
    % select a ROI 
    [noiseROI, meanSignalROI]= ROI_characteristics( balancedFrame,debayerFrame,highPass,bayer,false);
    noise=[noise; noiseROI];
    meanSignal=[meanSignal; meanSignalROI];
end


%% 4) Assess if sensor is quantum limited
remainingNoise=sqrt(noise.^2-repmat(darkNoise.^2,nROI,1))
remainingNoiseVar=remainingNoise.^2;

figure(7)
hold on
scatter(meanSignal(:,1),remainingNoise(:,1),'r')
scatter(meanSignal(:,2),remainingNoise(:,2),'g')
scatter(meanSignal(:,3),remainingNoise(:,3),'b')
xlim([0 1000])
xlabel('mean signal')
ylabel('noise standard deviation')
title('noise vs signal plot')

figure(8)
hold on
scatter(meanSignal(:,1),remainingNoiseVar(:,1),'r')
scatter(meanSignal(:,2),remainingNoiseVar(:,2),'g')
scatter(meanSignal(:,3),remainingNoiseVar(:,3),'b')
xlim([0 1000])
xlabel('mean signal')
ylabel('noise variance')
title('variance vs signal plot')
%if sensor is quantum-limited, points are on a line going through (0,0) 

snr=meanSignal./remainingNoise;
snr2=snr.^2 % if sensor is quantum-limited, this is the number of photons per pixel
gain=meanSignal./snr2 % if sensor is quantum-limited, this is the gain in digital gray level/captured photon

figure(9)
hold on
scatter(meanSignal(:,1),gain(:,1),'r')
scatter(meanSignal(:,2),gain(:,2),'g')
scatter(meanSignal(:,3),gain(:,3),'b')
xlim([0 1000])
ylim([0 0.5])
xlabel('mean signal')
ylabel('sensor gain')
title('sensor gain vs signal plot')

