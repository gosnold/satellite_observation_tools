%% script to measure the brightness of statellite trails in an image

%% algorithm detailed design
%   - perform median filtering to remove stars
%   - average result perpendicular to trail direction
%   - clean result to find the peaks
%   - measure intensity of peaks and report it in original image

folder='D:\Clement\Documents\Espace\perso\itelescope\20150819\'
file='Calibrated-T16-gosnold-ASTRA_1N-20150819-003141-Luminance-BIN1-E-120-001'
im=imread(strcat(folder,file),'TIFF');
alongMed=medfilt2(im,[800,3],'symmetric'); %image filtered along-track to remove stars
maxes=double(max(alongMed,[],1)); %take the max of each row
maxMed=medfilt2(maxes,[1 20],'symmetric'); %high-pass the data
maxes=maxes-maxMed;

figure (1),
plot(maxes), 
title ('maxes')

sigma=std(maxes);

figure (2),
findpeaks(maxes.*(maxes>5*sigma),'MinPeakDistance',2);
title('peaks')

[values,locVert]=findpeaks(maxes.*(maxes>5*sigma),'MinPeakDistance',2);
[~,locHor]=max(alongMed(:,locVert));
rgb=insertText(imadjust(im),[locVert.' locHor.'],values,'FontSize',72);

figure(3),
imshow(rgb)
title('measurements')

%imwrite(rgb,strcat(folder,file,'_meas.png'))