# Netlogo Project 
## Pandemic

A model created using the GIS extension in Netlogo to show the spread of a disease through the world's population



## Getting Started

The only file that is needed to work the model is **Finished.nlogo**



## Prerequisities and Installing

Before running this program Netlogo will need to be downloaded from:  
_https://ccl.northwestern.edu/netlogo/download.shtml_   
Any version should work and allow for the model to run, however Netlogo 5.3.1 was utilised
during this project, so it may be recommended to download this version, instead of the 6.0
beta version as this may prove to have some of unknown issues

With the version that is downloaded it is also important to make sure that some of the free
example codes are also downloaded in, and these can be found typically in a file like this:  
_/Program Files/NetLogo 5.3.1/app/models/Code Examples/GIS/data/_  
This file should contain a number of files including shape files, however the ones of 
importance for this project is the *WGS_84_Geographic*, *cities.shp* and *countries.shp*



## Running the Model

To begin running the model first open **Finished.nlogo**  

Then make sure the interface is selected (not info and code) and then follow the following instructions to to run the model.

**1.** Press _setup button_ and wait for map, and map colour to load  
**2.** Press _setup-turtles_ button, which should create a random number of turtles within the landmasses of the world map  
**3.** Press go button to then run model

# Other Options

- **Infectiousness** : A slider that allows the user to set how infectious the disease is
- **Duration** : A slider that allows the user to change the duration
- **Chance-recover** : A slider that allows a user to change the time it takes for the turtles to recover
- **display-countries** : Will display countries separately from the setup
- **label-countries** : Will label the countries, however will only function when display_countries is in use
- **display-cities** : Will display majour cities around the world as long display_countries or setup is in use
- **label-countries** : Will label the cities as long as display_cities is in use

_**IMPORTANT: It should be noted that the speed of the model may need to be adjusted so that the user can see the spread of the infection**_



## Built With

Netlogo version 5.3.1



## Authors

The Only Enigma



## License

 Pandemic Netlogo Project
 
 -- Copyright Notice --

 This software is licensed under the 'Open Source License, version 1.0 (OSL-1.0)
 which can be found at the Open Source Intiative website at...  
https://opensource.org/licenses/OSL-1.0

-- End of Copyright Notice --
