%% script to simulate an observation of a LEO satellite

%% algorithm short description:
%   -compute the system psf, taking into account diffraction, seeing, and
%   motion blur
%   -compute the system sampling
%   -compute the amount of signal received from target satellite
%   -compute the number of frames with the satellite inside them
%   -generate a representative image of the satellite, taking into account
%   system psf, system sampling and quantum and electronic noise

%% inputs

% physical constants
solFlux=1360;% solar irradiance at top of atmosphere in W/m2
atmAbs=1050/1360;% 1-way atmospheric transmittance
lambda=5e-7;% mean wavelength of interest in m
h=6.6E-34;% planck constant in SI units
c=3E8;% speed of light, in m/s

% object (values are for ISS)
albedo=1;% object albedo
height=108;% height of object in m
width=70;% width of object in m
sigma=height*width% object cross section in m2
d=540e3;% object distance in m
speed=8e3;% orthoradial object speed in m/s
zenitAngle=0;% zenit angle in radian
passDuration=180;% duration of the pass, in s

% instrument 
% (values are for an Orion XT8 OTA with 3x Barlow and ZWO asi174mm camera)
% optical assembly
focal=3.6;% focal length of telescope in m (XT8:1.2)
aperture=0.2;% diameter of aperture in m
strehl=0.8;% strehl ratio
curvature=3.6;% telescope field curvature in m
% sensor
useSpectrum=0.4;% portion of the spectrum used (in fraction of total power)
pixSpace=5.86e-6;% pixel pitch in m 6.8e-6=nikon 1 j2 2x binned (video mode)
DQE=0.5;% DQE of detector without bayer
transBayer=1;% DQE of Bayer filter
expTime=1/4000;% exposure time in ms
imFreq=164;% frequency at which images are taken in Hz
widthSensor=1936;% width of sensor in number of pixels 1920=nikon 1j2 HD video
heightSensor=1216; % height of sensor in number of pixels 
noiseStd=0;% std deviation of sensor noise (dark current+read noise)
sensorGain=1;% ADC gain factor, from electrons to digital gray level
rolling=false;% set to true if sensor has a rolling shutter
shutterTime=1/60;% time it takes for the shutter to go from 1st to last sensor line, in s
% (worst case is 1/ maximum supported framerate at this resolution)

% tracking performance
tracked=true;% set to false is shot is untracked (target drifts into field of view)
% set to yes if shot is tracked (observer tries to maintain target center in
% field of view)
trackingBiais=2.7e4;% probability density of having the target in field of view when tracking, 
%, per rad^2 of field of view (value for manual tracking with xt8 dob + finder  w crosshair)
%(it is the low-frequency tracking error) 
trackingError=0.0065;% mean apparent movement of the target between 2 successive frames, when tracking the target, in rad/s
% (value for manual tracking with xt8 dob + finder  w crosshair)
% (it is the high-frequency tracking error)
% TODO: add tracking jitter

% seeing parameters
r0=0.15;% atmosphere length of coherence at 0 zenit angle at observation, in m
H=7e3;% mean effective turbulence height in m
windSpeed=20;% wind speed in turbulent layer m/s

%% Computations

% seeing-related stuff
r1=r0*cos(zenitAngle)^(3/5);% corrected r0 for zenit angle
t0=r1/windSpeed;% atmospheric time of frozen turbulence at observation in s
theta0=r1/H*0.314*cos(zenitAngle);% isoplanatic angle


% compute signal intensity at observer position
nu=c/lambda;% mean frequency of interest in Hz
photonE=h*nu;% photon energy in J, approximated to be constant in band of interest;
irrad=solFlux*atmAbs*useSpectrum*albedo*sigma/d^2/4/pi;% irradiance ...
%in band of interest at observer location in W/m2
collectA=aperture^2*pi/4;% light collecting area in m2
nPhotonExp=irrad*collectA*expTime/photonE;% number of photons per exposure at aperture;

% compute the size of different imaging artifacts
resolPix=pixSpace*d/focal;% projected size of a pixel at object distance, in m
resolDiff=1.22*lambda/aperture*d/strehl;% projected size of rayleigh FWHM at object distance, in m
resolAtm=1.22*lambda/r1*d;% projected size of turbulence PSF at object distance, in m
resolSpeed=speed*expTime;% size of blurring due to movement of object when not tracking, in m
resolTracking=trackingError*expTime*d;% size of  blurring due to movement of object when  tracking, in m
resolCurvature=aperture*((pixSpace*widthSensor/focal)^2)/8*d;
% size of  blurring dur to field curvature, at the edgde of sensor, in m


%compute rolling shutter distortion (worst case, shutter takes 1 frame to
%complete)
if (rolling)
    shutterSpeed=height/shutterTime; % shutter vertical speed in pix/s
    objectSpeed=trackingError*d/resolPix;% object speed on sensor in pix/s
    shutterDistortion=shutterSpeed/(shutterSpeed-objectSpeed);
end

if(tracked)
    resolMotion=resolTracking;
else
    resolMotion=resolSpeed;
end


angleResolPix=pixSpace/focal;% angular resolution of 1 pixel
nPixisoplan=theta0/angleResolPix;% isoplanatic angle in pixels


% compute amount of quantum noise in image
TQE=DQE*transBayer;% total quantum efficiency of instrument
nPixObj=ceil(height*width/(resolPix^2));
% number of pixels filled by the object, without any blurring effects
nPhotonObj=nPhotonExp*TQE;% number of converted photons coming from object
nPhotonPix=nPhotonObj/nPixObj;% number of converted photon from object per pixel

% compute number of images with target in frame
FoV=widthSensor*resolPix;% size of FoV at object in m
angleFov=widthSensor*pixSpace/focal;% full FoV angle in radians
angleFovDegrees=angleFov*360/2/pi;% full FoV angle in degrees

if(tracked)
    % tracking, objects is only in some frames,assuming probability of object in 1 frame <<1
    probaFrame=trackingBiais*widthSensor*heightSensor*(pixSpace/focal)^2;
    nFrames=passDuration*imFreq*probaFrame;
else
    % no tracking, objects drifts in FoV
    timeFoV=FoV/speed;% time object remains in sensor FoV, in s
    nImages=timeFoV*imFreq;
end

%% simulated images
fullrez=imread('targets/iss.jpg','jpeg'); %high-resolution image of the target
im_rez=0.5;%size in meter of 1 pixel of the high-rez image
% for iss.jpg, im_rez=0.5
% hubble.jpeg, im_rez=0.07 resurs=0.06 pleiades.jpg=0.03 iss2.jpg=0.1
lumi=sum(fullrez,3); % transform it to a grayscale image
mean_lumi=mean(mean(lumi(lumi>10)));
lumi=double(lumi);
lumi=lumi/mean_lumi; % rescale the image to have mean value of 1 inside object


imtool(lumi);


blur=fspecial('gaussian',[ceil(resolDiff/im_rez*10),ceil(resolDiff/im_rez*10)],...
    sqrt(resolDiff^2+0*resolAtm^2)/im_rez);
%compute size of diffraction+seeing psf in high-rez image pixels
blurred=conv2(lumi,blur);% apply psf to high-rez image

motionblur=fspecial('motion',1+round(resolMotion/im_rez),0); % blur due to motion
blurred=conv2(blurred,motionblur);% apply motion blur


imtool(blurred);


sampling=ceil(resolPix/im_rez);% compute system samplign in high-rez image pixels
downsampled=conv2(blurred,ones(sampling,sampling)/sampling^2);
downsampled=downsampled(1:sampling:end,1:sampling:end);% downsample high-rez image


imtool(downsampled);

if(rolling)
    tform = affine2d([1 0 0; 0 shutterDistortion 0;0 0 1]);
    downsampled = imwarp(downsampled,tform);
    nPhotonPix=nPhotonPix/shutterDistortion; % correct for distorted object size
end
%add quantum and sensor noise
frame=downsampled*nPhotonPix;
frame=uint16(frame);
frame=imnoise(frame,'poisson');
frame=double(frame);
frame=frame*sensorGain;
maxFrame=max(max(frame));
frame=frame/maxFrame;
frame=imnoise(frame,'gaussian',0,noiseStd/maxFrame);
frame=frame*maxFrame;

%% final image obtained for this object
imtool(frame);

