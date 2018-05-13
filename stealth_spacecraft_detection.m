%% script to assess the detection range of a stealth spacecraft with low thermal signature

%% detailed algorithm description
%   - assume spacecraft has a hot spot at temperature T0
%   - compute noise power of a bolometer with bandwidth centered at T0
%   - compute receiver sensitivity to have acceptable false alarm rate
%   - compute distance to have spacecraft signal exceeding sensitivity

clear
clc

%%  spacecraft parameters
craft_t_max = 20; % temperature of spacecraft hot spot (for open-loop cooling it is the max temperature reached by the coolant)
craft_diameter = 0.3;% diameter of the hot spot. For open-loop cooling it is the diameter of the reflective sunshade
distanceAU = 0.5; %distance to detection system in AU

%%  detection system parameter
% detection system is assumed to be an far IR telescope with a bolometer
% array and a bandpass suited to t_max
bandpass_fraction = 0.01; % design the bandpass to capture this fraction of the craft signal 
% can be played with to optimize, lower bandpass reduces background noise
% but also reduces signal
resolutionArcSec = 60;% sensor resolution in steradian; high resolution is useful to remove background hotspots
detector_diameter = 10;% diameter of the collecting area
scanAngle = 2*pi; % solid angle to scan
integTime = 3600*24; % integration time

%% physical constants
cmb_temp = 4; % temperature of cosmic microwave background in Kelvin
k = 1.38*10.^-23; %  T/K Boltzmann constant
c = 3e8; % speed of light
Jy2SI = 1e-26; % value of 1 Jansky in SI unit 
h = 6.625*10.^-34; % Planck constant 
galacticBkgMJy = 1e6; % brightness of sky at 100 microns in MJy/sr (see https://irsa.ipac.caltech.edu/applications/DUST/)
arcsec2Sr = 4.25e10; % value of 1 steradian in arcsec^2
AU2SI = 1.5e11; % value of 1 austonomical unit in m

%% Compute detector noise power
freqs = 1:1e10:1e13; %vector of frequencies in Hz

% automatically design bandpass
radiant_intensity = planckLaw_freq( craft_t_max, freqs ); % spectral radiated intensity by the craft
[maxIntensity,maxIndex] = max(radiant_intensity);

alpha = (1-bandpass_fraction)/2;

fminIndex = find(cumsum(radiant_intensity)/sum(radiant_intensity)>alpha,1);
fmin = freqs (fminIndex); % lower frequency of bandpass

fmaxIndex = find(cumsum(radiant_intensity)/sum(radiant_intensity)>1-alpha,1);
fmax = freqs (fmaxIndex); % upper frequency of bandpass

B = fmax -fmin; % bandpass bandwidth
f = (fmax + fmin)/2; % bandpass center frequency
lambda = c/f; % corresponding wavelength
lambdaMin = c/fmax; % lower bandpass wavelength
lambdaMax = c/fmin; % upper bandpass wavelength

% compute noise power
galacticBkg = galacticBkgMJy*Jy2SI; % brightness of sky at 100 microns in W/m2/sr/Hz

resolution = resolutionArcSec/arcsec2Sr; % resolution in Sr
aperture = pi/4*detector_diameter^2; % area in m2 colecting light
galacticBkgPix = galacticBkg*B*resolution*aperture; % brightness of sky at 100 microns in W per pixel
photon_energy = h*f; % mean photon enery in the bandpass
nPhotBkgPix = galacticBkgPix/photon_energy*integTime; %number of background photon /pixel 
noiseBkgPix = sqrt(nPhotBkgPix); % quantum noise /pix /s

nPix = scanAngle/resolution; % number of pixels scanned each scan cycle
SDNRreq  = norminv(1-1/nPix,0,1); % SDNR required to have 1 false alarm per scan cycle

%% spacecraft signal
craft_surface = pi/4*craft_diameter^2;
radiated_power = craft_surface*stefanLaw( craft_t_max );

received_power_norm = radiated_power*detector_diameter/(4*pi); % received power normalized at 1m distance
received_phot_norm = received_power_norm/photon_energy*integTime; % received number of photons normalized at 1m distance
SDNR_norm = received_phot_norm/noiseBkgPix;

detect_dist = sqrt(SDNR_norm/SDNRreq);
detect_dist_AU = detect_dist/AU2SI;
detect_dist_km = detect_dist/1e3