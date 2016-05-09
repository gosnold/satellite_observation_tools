
# coding: utf-8

# In[80]:

#script to generate an ACP plan (for use with itelescope website for instance) to image geostationnary satellites
#points the telescope to the location of the satellite and lets it drift in the field of view

from ephem import *
import numpy
import string


# In[81]:

def loadtle(satname,tlepath):
    tleiter = iter(open(tlepath))
    for line in tleiter:
        if satname in line:
            line1 = line
            line2 = next(tleiter)
            line3 = next(tleiter)
    sat = readtle(line1, line2, line3)        
    return sat


# In[82]:

observation_site='Nerpio'
obsStartTimeLocal = '2015/8/24 02:30:00' #local start time of plan


# In[83]:

tlepath='3ledebless.txt'
tleclassfdpath='classfd.tle'
planpath='auto_plan.txt'


# In[84]:

#watchlist=['SYRACUSE 3A','SYRACUSE 3B','ATHENA FIDUS','SICRAL 1A', 'SICRAL 1B', 'SKYNET 5A', 'SKYNET 5B', 'SKYNET 5C','SKYNET 5D']
watchlist=['ASTRA 1N']


# In[85]:

exposure_time = 60 #exposure time in seconds
filters = ['R', 'V', 'B'] #choose among Luminance, R, V, B, Ha, SII, OIII, I for T16


# In[86]:

if(observation_site=='Nerpio'):
    lat='38.150000'
    long='-2.31667'
    ele=1650
    timeZoneOffset= +2 #time zone difference in hours compared to UTC
elif(observation_site=='Mayhill'):
    lat='32.9'
    long='-105.5'
    ele=2250
    timeZoneOffset= -6 #time zone difference in hours compared to UTC
elif(observation_site=='SSO'):
    lat='-31.273333'
    long='149.064444'
    ele=1165
    timeZoneOffset= +10 #time zone difference in hours compared to UTC


# In[87]:

pointing_time = 120 #mean time needed to point an object in seconds
repointing_time = 60 #mean time needed to repoint an object after initial acquisistion in seconds
reading_time =  60 #mean time needed to read CCD in seconds


# In[88]:

obsStartTime = Date(obsStartTimeLocal)
obsStartTime = Date(obsStartTime - timeZoneOffset*hour)


# In[89]:

plan=open(planpath,'w')


# In[90]:

comment = '; observation site: %s \n; local start time %s \n' % (observation_site,obsStartTimeLocal)
plan.write(comment);
plan.write('#trackoff\n#Sets 1\n#tiff\n#count 1\n#binning 1\n')
interval='#interval %s\n' %exposure_time
plan.write(interval)
# waitCommand='#WAITUNTIL 1, %s:%s:%s\n' %(obsStartTime.tuple()[3],obsStartTime.tuple()[4],int(obsStartTime.tuple()[5]))
# plan.write(waitCommand)


# In[91]:

acq=Observer()
acq.lat=lat
acq.long=long
acq.elevation=ele


# In[92]:

for i in watchlist:
    try:
        sat = loadtle(i,tlepath)
        obsStartTime = Date(obsStartTime + pointing_time*second)
    except:
        print('satellite not found in NORAD list')
    try:
        sat = loadtle(i,tleclassfdpath)
        obsStartTime = Date(obsStartTime + pointing_time*second)
    except:
        print('satellite not found in classified list')
    try:
        for j in filters:
            acq.date=obsStartTime
            sat.compute(acq)
            ra = numpy.degrees(sat.a_ra)/360*24
            dec = numpy.degrees(sat.a_dec)
            filterCommand ='#filter %s \n' %j
            plan.write(filterCommand)
            plan.write('%s\t%s\t%s\n' % (i.replace(' ', '_'), ra, dec))
            obsStartTime = Date(obsStartTime + (exposure_time+repointing_time+reading_time)*second)
    except:
        print('could not compute acquisition')


# In[93]:

plan.close()


# In[94]:

print("observation end time")
print(obsStartTime)


# In[ ]:



