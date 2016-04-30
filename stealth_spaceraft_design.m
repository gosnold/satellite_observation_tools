%% script to asses the design of a stealth spacecraft with low thermal signature

%% detailed algorithm description
%   -compute energy absorbed sy spacecraft due to sunlight (spacecraft
%   assumed to be fully passive, no heat generation)
%   -compute quantity of coolant needed to absorb this energy
%   -compute volume of coolant needed to absorb this energy

%% spacecraft bus specs
% spacecraft minimizes the sunlight it catches by using a reflective
% coating and point its smallest side towards the sun

diameter=0.3;% diameter of area exposed to sun in m
solar_reflectance=0.94;% alpha, fraction of solar power reflected

%% cooling system specs
% cooling system is just an open-loop coolant that absorbs heat by liquefying
% and/or gassifying
% values are for H2

spec_th_cap=14e3;% specific thermal capacity in J/K/kg
melt_spec_heat=60e3;% specific latent heat of melting in J/kg
vap_spec_heat=450e3;% specific latent heat of vaporization in J/kg
vap_temp=20;% vaporization temperature in K
melt_temp=14;% melting temperature in K
t_min=14.1; % minimum coolant temperature in K (it is stored at this temperature)
t_max=20.5; % maximum coolant temperature in K (it is vented at this temperature)
density=86;% density of coolant in kg/m^3 %solid h2 86 liquid H2 at 20K 70

%% spacecraft trajectory 
% values are for Earth-Mars Homann transfer

travel_time=250;% travel time in days
mean_distance=(1+1/2.25)/2;% mean distance to sun in astronomical units

%% physical constants 
sigma=5.68e-8;% Stefan Boltzmann constant
solar_irradiance_1UA=1377;
solar_irradiance_mean=solar_irradiance_1UA*mean_distance;% mean solar irradiance on trajectory in W/m^2
bckgrd_temp=4;% temperature of background radiation in K

%% computations
front_area=diameter^2/4*pi;% frontal area of spacecraft in m^2
power_absorbed=solar_irradiance_mean*front_area*(1-solar_reflectance);
% absorbed power
tot_spec_heat=(t_max-t_min)*spec_th_cap+(vap_temp<t_max & vap_temp>t_min)...
    *vap_spec_heat+(melt_temp<t_max & melt_temp>t_min)*melt_spec_heat;
% total specific heat for coolant going to t_min to t_max with phase changes in J/kg

spec_time=tot_spec_heat/power_absorbed;% specific time it take to consume 1kg of coolant
%in s

travel_time_s=travel_time*24*3600;% travel time in seconds
tot_conso=travel_time_s/spec_time;% total consumption of coolant over travel 
%in kg

coolant_vol=tot_conso/density;% volume of coolant required in m^3
height_coolant=coolant_vol/front_area;% height of a cylinder with diameter of the spacecraft containing
%all coolant
surf_area=pi*diameter*height_coolant;
% surface area of satellite(approximated by coolant cylinder) in m^2
radiated_pow=surf_area*sigma*t_max^4;% radiated power in W
received_bckgrd_pow=surf_area*sigma*bckgrd_temp^4;% power received from cosmic background in W