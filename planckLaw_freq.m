function [ radiant_intensity ] = planckLaw_freq( T, f )
% computes the hemispheric spectral radiated intensity based on Max Planck's law 
% inputs:
%    T temperature  in Kelvin
%    f: frequencies in Hz
% outputs:
%     radiant_intensity, in W/m2/m

c0 = 2.997*10.^8; % m/s speed of light in vaccum
h = 6.625*10.^-34; % J.s Planck constant 
k = 1.38*10.^-23; %  T/K Boltzmann constant

radiant_intensity =(2*pi.*h.*(f.^3))./((c0.^2).*(exp((h.*f)./(k.*T))-1));
end

