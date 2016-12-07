;;
;; Pandemic Netlogo Project
;;
;; -- Copyright Notice --
;;
;;
;; Copyright (c) Hannah J. Constable
;; This software is licensed under the 'Open Source License, version 1.0 (OSL-1.0)
;; which can be found at the Open Source Intiative website at...
;; https://opensource.org/licenses/OSL-1.0
;;
;;
;; -- End of Copyright Notice --
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;; Creating extensions, globals, breed and other attributes to be used within
;; the rest of the code
;;
;; Globals include citizen datsets, patches, country datasets and city datasets to setup the
;; map where the Pandemic will be occuring
;; Other data then includes the percentage of the population that is both immune and infected
;; by the bacteria or virus, along with immunity duration of the turtles. Furthermore there is
;; global that will limit the carrying capacity of the world so that the viewer doesn't become
;; over populated and too many turtles are seen on screen
;;

extensions [ gis table ]
globals [ cities-dataset
          desired-people
          patch-area-sqkm
          countries-dataset
          %immune %infected
          lifespan
          chance-reproduce
          carrying-capacity
          immunity-duration ]
breed [ city-labels city-label ]
breed [ country-labels country-label ]
breed [ country-vertices country-vertex ]
breed [ city-vertices city-vertex ]
breed [ persons person ]
patches-own [ population country-name area population-density]
persons-own [ agent-country-name]





;; Creates setup procedure that can be called to produce the area for the Pandemic to spread
;; In the this case it is the world with the projection WGS_84_Geographic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  ca
  setup-constants
  setup-turtles
  update-global-variables
  update-display

  set projection "WGS_84_Geographic"

  ; Loading in the coordinate system is an optional addition however the WGS_84_Geographic projection can
  ; be found in the example codes in models for Netlogo

  gis:load-coordinate-system (word "C:/Program Files/NetLogo 5.3.1/app/models/Code Examples/GIS/data/WGS_84_Geographic.prj")

  ; This sections loads the datasets for both the major cities around the world and countries from the code examples in the
  ; models sections of Netlogo, which are both shape files

  set countries-dataset gis:load-dataset "C:/Program Files/NetLogo 5.3.1/app/models/Code Examples/GIS/data/countries.shp"
  set cities-dataset gis:load-dataset "C:/Program Files/NetLogo 5.3.1/app/models/Code Examples/GIS/data/cities.shp"

  ; Set the world envelope using X and Y scales in this case

  gis:set-world-envelope-ds [-180 180 -90 90]

  ; Draws country boundaries from a shapefile and colours them white

  gis:set-drawing-color white
  gis:draw countries-dataset 1

  ; New code

  set patch-area-sqkm (510000000 / count patches)
  setup-gis

  reset-ticks

end






;; Create procedure setup-gis and use gis:apply coverage to copy chosen values
;; from the data-set cities to patches. In this case the chosen
;; values are population by country, area and country name
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to setup-gis
  show "Loading patches..."
  gis:apply-coverage countries-dataset "POP_CNTRY" population
  gis:apply-coverage countries-dataset "SQKM" area
  gis:apply-coverage countries-dataset "CNTRY_NAME" country-name

; Get patches to colour areas dependent on the population in said area,
; with areas with a high population density being coloured red

  ask patches [
    ifelse (area > 0 and population > 0)
      [
        set population-density (population / area)
        set pcolor (scale-color red population-density 400 0) ]

; Colour patch with no population blue, so that the ocean should be coloured
; correctly and differently to the land areas
      [
        set population-density 0
        set pcolor blue ]
  ]
end






;; Creates procedures display-cities and display-countries that will show the differen
;; countries around the globe but will also allow the user to label the countries and
;; major cities if they wish to
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to display-cities
  ask city-labels [ die ]

  foreach gis:feature-list-of cities-dataset
  [ gis:set-drawing-color scale-color red (gis:property-value ? "POPULATION") 5000000 1000
    gis:fill ? 2.0

    if label-cities  [
      let location gis:location-of (first (first (gis:vertex-lists-of ?)))

; The location will be an empty list if the point lies outside the
; bounds of the current NetLogo world

      if not empty? location
      [ create-city-labels 1
        [ set xcor item 0 location
          set ycor item 1 location
          set size 0
          set label gis:property-value ? "NAME" ] ] ] ]

end


; This section draws out polygon data from the chosen shapefile, and optionally, when the
; label countries is true, loads in data into a turtles

to display-countries
  ask country-labels [ die ]
  gis:set-drawing-color white
  gis:draw countries-dataset 1

  if label-countries
  [ foreach gis:feature-list-of countries-dataset
    [ let centroid gis:location-of gis:centroid-of ?

; centroid will be an empty list if it lies outside the bounds
; of the current NetLogo world, as defined by our current GIS
; coordinate transformation

      if not empty? centroid
      [ create-country-labels 1
        [ set xcor item 0 centroid
          set ycor item 1 centroid
          set size 0
          set label gis:property-value ? "CNTRY_NAME" ] ] ] ]

end



; Setting up turtles to be used in Pandemic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to setup-turtles

  ask turtles [ die ]

; A caculation that creates randomly how many people will be created by the procedure.
; It should be noted that because countries don't occupy an entire patch there will be
; some overestimates with using this method

         ask patches [
            if (population-density > 0) [

      let num-people (population-density * patch-area-sqkm / 10000000)

; Creates whole numbers directly

      sprout-persons (floor num-people) [ turtles-setup country-name ]

; Create fractions probabilistically

      let fractional-part (num-people - (floor num-people))
       if (fractional-part > random-float 1) [ sprout-persons 1 [ turtles-setup country-name ] ]
    ]
  ]

  show (word "Randomly created " (count persons) " people")

  reset-ticks
end




; Connects the turtles with other procedures further down that will influence the behaviour of
; the turtles and also sets the appearance of the turtles that will be viewed within the model

to turtles-setup [ ctry ]

; Size of turtle, colour and shape can be changed
; It should be noted that the optimum sizes for the turtles lay
; between 1 and 3

  set shape "person"
  set size 1.5
  set color blue

; Setup so that turtles will get sick, get healthy and have a random lifespan

  set age random lifespan
  set sick-time 0
  set remaining-immunity 0
    get-healthy
    get-sick

  set agent-country-name ctry
end






; Traits for the turtles to contain including sick-time and age
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The setup and traits for the turtles is divided into procedures that will determine
; how long the turtle is infectious for, how many will become infectious and what the
; average age of turtle is

turtles-own
  [ sick?                ;; If  this is set as true, then the turtle will be infectious
    remaining-immunity   ;; Is how many weeks of immunity the turtle has left
    sick-time            ;; Shows in weeks how long the turtle has been infectious
    age ]                ;; Shows how old the turtle is


;; We create a variable number of turtles of which a number of them are infectious and
;; and distribute them across the world map

; Turtle procedure for them to become sick

to get-sick
  set sick? true
  set remaining-immunity 0
end



; This procedure gets sick? as false which means that the
; the turtle is immune

to get-healthy
  set sick? false
  set remaining-immunity 0
  set sick-time 0
end



; Sets how long until a turtle can become immune by using
; remaining-immunity and immunity-duration

to become-immune
  set sick? false
  set sick-time 0
  set remaining-immunity immunity-duration
end



; This sets up some of the basic constants of the model
; this includes lifespan of the turtles

to setup-constants

; 71 times 52 weeks = 71 years
; This lifespan has been chosen because this is the average
; global life expectancy

  set lifespan 71 * 52
  set carrying-capacity 1
  set chance-reproduce 10
  set immunity-duration 52
end





;; Setups the procedure go to be used in the model
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Deals with whether the turtles will get older and recover or whether they
; will infect other turtles on the map and implementing it in the go procedure

to go
  ask turtles [
    get-older

; Whether the turtles become sick, reproduce or recover

    if sick? [ recover-or-die ]
    ifelse sick? [ infect ] [ reproduce ]
  ]

; updates global variables and displays

  update-global-variables
  update-display
  reset-ticks
end


; Sets how many turtles will become infected and which ones will be immmune

to update-global-variables
  if count turtles > 0
    [ set %infected (count turtles with [ sick? ] / count turtles) * 100
      set %immune (count turtles with [ immune? ] / count turtles) * 100 ]
end



; Updates display and sets the shape of the turtle when it becomes infected by the
; disease. It also places immune ivdividuals as green or grey, depending, and those
; infected as red

to update-display
  ask turtles
    [ if shape != turtle-shape [ set shape turtle-shape ]
      set color ifelse-value sick? [ red ] [ ifelse-value immune? [ grey ] [ green ] ] ]
end



; Turtle counting variables to allow for turtles to become older

to get-older

; Turtles die of old age once their age exceeds the
; lifespan, which for this model is set at the global avergae
; life expectancy of 71

  set age age + 1
  if age > lifespan [ die ]
  if immune? [ set remaining-immunity remaining-immunity - 1 ]
  if sick? [ set sick-time sick-time + 1 ]
end



; Procedure for the turtle to infect other turtles, and allows the user to
; decide how infectious the disease is

to infect

; If a turtle is sick then it  will and can infect other turtles,
; however immune turtles will not get sick and will remain immune

  ask other turtles-here with [ not sick? and not immune? ]
    [ if random-float 1 < infectiousness
      [ get-sick ] ]
end


; This procedure controls what happens to the turtle once it has been infected,
; and sets it so that once a period of time has occured the turtle will either
; recover or it dies and is removed from the map

to recover-or-die

; If the turtle has survived the sick-time then there a chance or recovery, however
; if this isn't implemented then the turtle will die

  if sick-time > duration
    [ ifelse random-float 100 < chance-recover
      [ become-immune ]
      [ die ] ]
end



; This allows for the turtles to reproduce as long as the carrying capicity
; has not been breached and there is 'room' for more turtles

to reproduce
  if count turtles < carrying-capacity and random-float 100 < chance-reproduce
    [ hatch 1
      [ set age 1
        lt 45 fd 1
        get-healthy ] ]
end


; Reports back whether they are immune or not

to-report immune?
  report remaining-immunity > 0
end


; Sets-up constants

to startup
  setup-constants
end
@#$#@#$#@
GRAPHICS-WINDOW
185
10
775
333
72
36
4.0
1
8
1
1
1
0
1
1
1
-72
72
-36
36
0
0
1
ticks
30.0

BUTTON
785
169
924
202
NIL
display-cities
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
5
12
175
45
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
786
220
923
253
label-cities
label-cities
1
1
-1000

CHOOSER
784
10
923
55
projection
projection
"WGS_84_Geographic" "US_Orthographic" "Lambert_Conformal_Conic"
0

BUTTON
73
60
177
93
NIL
setup-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
6
240
178
285
turtle-shape
turtle-shape
"person" "circle"
0

SLIDER
5
103
177
136
infectiousness
infectiousness
0.0
99.0
1
1.0
1
%
HORIZONTAL

SLIDER
5
148
177
181
duration
duration
0.0
99.0
21
1.0
1
%
HORIZONTAL

SLIDER
5
194
178
227
chance-recover
chance-recover
0.0
99.0
60
1.0
1
%
HORIZONTAL

BUTTON
6
60
69
93
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
784
119
923
152
label-countries
label-countries
1
1
-1000

BUTTON
784
69
924
102
NIL
display-countries
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model was built to test and demonstrate the functionality of the GIS NetLogo extension.

## HOW IT WORKS

This model loads four different GIS datasets: a point file of world cities, a polyline file of world rivers, a polygon file of countries, and a raster file of surface elevation. It provides a collection of different ways to display and query the data, to demonstrate the capabilities of the GIS extension.

## HOW TO USE IT

Select a map projection from the projection menu, then click the setup button. You can then click on any of the other buttons to display data. See the code tab for specific information about how the different buttons work.

## THINGS TO TRY

Most of the commands in the Code tab can be easily modified to display slightly different information. For example, you could modify `display-cities` to label cities with their population instead of their name. Or you could modify `highlight-large-cities` to highlight small cities instead, by replacing `gis:find-greater-than` with `gis:find-less-than`.

## EXTENDING THE MODEL

This model doesn't do anything particularly interesting, but you can easily copy some of the code from the Code tab into a new model that uses your own data, or does something interesting with the included data. See the other GIS code example, GIS Gradient Example, for an example of this technique.

## RELATED MODELS

GIS Gradient Example provides another example of how to use the GIS extension.

<!-- 2008 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
setup
display-cities
display-countries
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
