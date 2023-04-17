globals [
   CAR_SIZE
   BUS_SIZE
   MOTOR_SIZE
   BIKE_SIZE
   SPAWN_REGION

   BOTTOM_LANE_BOUNDARY_Y
]

breed [actors actor]
breed [cars car]
breed [buses bus]          ; TODO: Add behavior to allow multiple actors to board the bus
breed [motors motor]       ; TODO: implement
breed [bikes bike]         ; TODO: implement

actors-own [
  available?; Whether the actor is at spawn
  done?    ; Whether the actor finished their trip
  vehicle  ; What vehicle they are in

  ; Probabilities. These get updated
  pcar     ; Whether this actor will use a car
  pbus     ; Whethe this actor will use  bus
  pmotor   ; Whether this actor will use a motorcycle
  pbike    ; Whether this actor will use a bike

  ; Metrics
  trip_started ; When did the trip strt
  trip_ended  ; When did the trip end

  last_trip_time ; What was the previous trip time?
  fastest_trip ; What was my fastest trip time?
  jam_time     ; Time spent jammed
  comfort    ; How unsafe did I (quantitatively) feel during the trip? This is measured by the number of vehicles that were close to me per unit time

  ; Decision
  choice    ; What vehicle this actor will use for today

  ; Hyperparameters
  alpha ; weighting for fastest trip
  beta  ; weighting for last trip
  gamma ; weighting for jam time
  delta ; weighting for comfort / perceived safety
]

cars-own [
  speed   ; the current speed of this vehicle
  targety ; the current target ycoord of this vehicle
  lane    ; the current lane this car is traversing
  impatience; a probability that determines if they switch lanes
  impatience_threshold ; the threshld for triggering the impatience mechanics
  delta_impatience ; the last time an impatience check was not run
  jam_time ; the time this vehicle was jammed
  comfort ; whether or not this vehicle was safe during the trip (quantified as the number of vehicles that were too close to this vehicle)
]

buses-own [
  speed
  targety
  impatience
  impatience_threshold
  delta_impatience
  jam_time
  comfort
]

motors-own [
  speed
  targety
  impatience
  impatience_threshold
  delta_impatience
  jam_time
  comfort
]

bikes-own [
  speed
  targety
  impatience
  impatience_threshold
  delta_impatience
  jam_time
  comfort
]

patches-own [
  lane_no
]

to setup
  clear-all
  reset-ticks
  setup-globals
  configure-lanes
  initialize-actors
end

to setup-globals
  set CAR_SIZE 2
  set BUS_SIZE 3
  set MOTOR_SIZE 1.5
  set BIKE_SIZE 1.25
  set SPAWN_REGION 5
end

to configure-lanes
  ask patches [
    set pcolor gray
    set lane_no -1
  ]

  let half_width LANE_WIDTH / 2
  let lane_center max-pycor - half_width

  ask patches with [pycor > lane_center + half_width] [set pcolor black]

  let x 0
  let total_lanes NUM_LANES + SPECIAL_LANES_BOTTOM
  repeat total_lanes [
    ask patches with [pycor > lane_center - half_width and pycor < lane_center + half_width ] [
      set lane_no x
    ]

    ; add lane markings
    if x = 0 [
      ask patches with [pycor = floor (lane_center + half_width)] [
       set pcolor white
      ]
    ]

    if x = NUM_LANES [
      set BOTTOM_LANE_BOUNDARY_Y lane_center - half_width
    ]

    ask patches with [pycor = ceiling (lane_center - half_width)] [
      set pcolor white
    ]

    set x x + 1
    set lane_center lane_center - LANE_WIDTH
  ]

  ask patches with [pycor < lane_center - half_width + LANE_WIDTH] [set pcolor black]
end

to initialize-actors
  create-actors N[
   set xcor min-pxcor
   set ycor min-pycor

   ; Initialize the probabilities

   set pcar random-normal 1 2
   set pbus random-normal 1 2
   set pmotor random-normal 1 2
   set pbike random-normal 1 2

   normalize-probabilities
   set fastest_trip -1
   set last_trip_time -1


   set alpha random-normal FASTEST_TIME_COEFF 0.1
   set beta random-normal LAST_TIME_COEFF 0.1
   set gamma random-normal JAMMING_TIME_COEFF 0.1
   set delta random-normal COMFORT_COEFF 0.1

   reset-actor
  ]

  ask-actors-decide
end

to normalize-probabilities

  let epsilon 0.00001

  set pcar max list pcar epsilon
  set pbus max list pbus epsilon
  set pmotor max list pmotor epsilon
  set pbike max list pbike epsilon

  let total pcar + pbus + pmotor + pbike
  set pcar (pcar / total)
  set pbus (pbus / total)
  set pmotor (pmotor / total)
  set pbike (pbike / total)
end

to go
 spawn-from-lanes
 update-finished
 update-movements
 update-comforts
 run-next-epoch
 tick
end

to spawn-from-lanes
  ; Check if there are any new actors that we need to spawn
  ; The spawn period simply ensures that we don't create any overlaps between vehicles
  if ticks mod SPAWN_PERIOD = 0 [
    let x 0

    ; Tune this to determine the general lanes.
    repeat NUM_LANES [
      ; Do lane spawning logic here. Includes the logic for which vehicle to spawn
      ; Account for the traffic density
      let should_spawn make-decision
      if should_spawn < TRAFFIC_DENSITY AND count actors with [available? = true] > 0 [
        ask one-of actors with [available? = true] [
          if choice = "car"
            [spawn-car x self]
          if choice = "bus"
            [spawn-bus x self]
          if choice = "motor"
            [spawn-motor x self]
        ]
      ]
      set x (x + 1)
    ]

     repeat SPECIAL_LANES_BOTTOM [
      ; Do lane spawning logic here. Includes the logic for which vehicle to spawn
      ; Account for the traffic density
      let should_spawn make-decision
      if should_spawn < TRAFFIC_DENSITY AND count actors with [available? = true] > 0 [
        ask one-of actors with [available? = true] [
          if choice = "bike"
            [spawn-bike x self]
        ]
      ]
      set x (x + 1)
    ]
  ]
end

to spawn-car [l a]
  ask a[

  let c 0
   hatch-cars 1 [
    set shape "car"
    set color blue
    set speed random-float CAR_SPEED_LIMIT
    set size CAR_SIZE

    set targety get-lane-center l + LANE_SPREAD * (random-normal 0 size) + LANE_WIDTH / 2
    set targety clamp targety min-pycor max-pycor
    set ycor targety

    set xcor min-pxcor + random 10   ; This makes it so there's a bit of interleaving.
    set heading 90    ; This makes the cars face right

    set impatience random-normal AVERAGE_IMPATIENCE 0.1 ; Set impatience. Have a stddev of 0.1
    set impatience clamp impatience 0 1

    set impatience_threshold random-normal AVERAGE_IMPATIENCE_THRESHOLD IMPATIENCE_THRESHOLD_STD_DEV
    set delta_impatience ticks


    set c self
   ]
      set vehicle c
      set available? false
      set trip_started ticks
  ]
end


to spawn-bus [l a]
  let c 0
  ask a[
   hatch-buses 1 [
    set shape "car"
    set color red
    set speed random-float BUS_SPEED_LIMIT
    set size BUS_SIZE

    set targety get-lane-center l + LANE_SPREAD * (random-normal 0 size) + LANE_WIDTH / 2
    set targety clamp targety min-pycor max-pycor
    set ycor targety


    set xcor min-pxcor + random 10   ; This makes it so there's a bit of interleaving.
    set heading 90    ; This makes the cars face right

    set impatience random-normal AVERAGE_IMPATIENCE 0.1 ; Set impatience. Have a stddev of 0.1
    set impatience clamp impatience 0 1

    set impatience_threshold random-normal AVERAGE_IMPATIENCE_THRESHOLD IMPATIENCE_THRESHOLD_STD_DEV
    set delta_impatience ticks


    set c self


   ]

   ; This sets the agent's new state as having started a trip.
   set vehicle c
   set available? false
   set trip_started ticks
  ]

  let k round random-normal MAX_BUS_CAPACITY BUS_OCCUPANCY_STDDEV
  if k > 0 [
  ask up-to-n-of k actors with [choice = "bus" and available? = true] [
   set vehicle c
   set available? false
   set trip_started ticks
  ]
  ]
end


to spawn-motor [l a]
  ask a[

  let c 0
   hatch-motors 1 [
    set shape "car"
    set color green
    set speed random-float MOTOR_SPEED_LIMIT
    set size MOTOR_SIZE

    set targety get-lane-center l + LANE_SPREAD * (random-normal 0 size) + LANE_WIDTH / 2
    set targety clamp targety min-pycor max-pycor
    set ycor targety

    set xcor min-pxcor + random 10   ; This makes it so there's a bit of interleaving.
    set heading 90    ; This makes the cars face right

    set impatience random-normal (AVERAGE_IMPATIENCE + 0.25 )  0.1 ; Set impatience. Have a stddev of 0.1
    set impatience clamp impatience 0 1

    set impatience_threshold random-normal AVERAGE_IMPATIENCE_THRESHOLD IMPATIENCE_THRESHOLD_STD_DEV
    set delta_impatience ticks

    set c self

   ]
      set vehicle c
      set available? false
      set trip_started ticks
  ]
end

to spawn-bike [l a]
  ask a[

  let c 0
   hatch-bikes 1 [
    set shape "car"
    set color orange
    set speed random-float BIKE_SPEED_LIMIT
    set size BIKE_SIZE

    set targety get-lane-center l + LANE_SPREAD * (random-normal 0 size) + LANE_WIDTH / 2
    set targety clamp targety min-pycor max-pycor
    set ycor targety

    set xcor min-pxcor + random 10   ; This makes it so there's a bit of interleaving.
    set heading 90    ; This makes the cars face right

    set impatience random-normal AVERAGE_IMPATIENCE 0.1 ; Set impatience. Have a stddev of 0.1
    set impatience clamp impatience 0 1

    set impatience_threshold random-normal AVERAGE_IMPATIENCE_THRESHOLD IMPATIENCE_THRESHOLD_STD_DEV
    set delta_impatience ticks

    set size BIKE_SIZE

    set c self

   ]
      set vehicle c
      set available? false
      set trip_started ticks
  ]
end


to update-finished
  ; For each vehicle type, notify all the actors.
  ask cars [
    if xcor + speed >= max-pxcor [
      ask actors with [vehicle = myself]
      [
       reset-to-actor
      ]
      die
    ]
  ]
  ask buses [
    if xcor + speed >= max-pxcor [
      ask actors with [vehicle = myself]
      [
       reset-to-actor
      ]
      die
    ]
  ]

  ask motors[
    if xcor + speed >= max-pxcor [
      ask actors with [vehicle = myself]
      [
       reset-to-actor
      ]
      die
    ]
  ]

  ask bikes [
    if xcor + speed >= max-pxcor [
      ask actors with [vehicle = myself]
      [
       reset-to-actor
      ]
      die
    ]
  ]
end

to reset-to-actor
  set xcor min-pxcor
  set ycor min-pycor
  set done? true
  set available? false
  set trip_ended ticks
  set jam_time [jam_time] of myself
  set comfort [comfort] of myself
end

to update-movements
  ask cars [
    check-metrics CAR_SPEED_LIMIT * JAM_THRESHOLD_COEFFICIENT
    maneuver
    adjust-speed CAR_SPEED_LIMIT
    fd speed
  ]

  ask buses [
    check-metrics BUS_SPEED_LIMIT * JAM_THRESHOLD_COEFFICIENT
    maneuver
    adjust-speed BUS_SPEED_LIMIT
    fd speed
  ]

  ask motors [
     check-metrics MOTOR_SPEED_LIMIT * JAM_THRESHOLD_COEFFICIENT
     maneuver
     adjust-speed MOTOR_SPEED_LIMIT
     fd speed
  ]

  ask bikes [
     check-metrics BIKE_SPEED_LIMIT * JAM_THRESHOLD_COEFFICIENT
     maneuver
     adjust-speed BIKE_SPEED_LIMIT
     fd speed
  ]
end

to update-comforts
  ask cars [
    let adj min-one-of other turtles with [breed != actors] [distance myself]
    if adj != nobody [
      let c [distance myself] of adj
      set comfort comfort + (1 - 1.0 / (c + 1 )) * CAR_COMFORT
    ]
  ]

  ask buses [
    ; The more people taking a bus, the less comfortable I am
    let c count actors with [vehicle = myself]
    set comfort comfort + (1 - c / (MAX_BUS_CAPACITY - 1) ) * BUS_COMFORT
  ]

  ask motors [
    let adj min-one-of other turtles with [breed != actors] [distance myself]
    if adj != nobody [
      let c [distance myself] of adj
      set comfort comfort + (1 - 1.0 / (c + 1 )) * MOTOR_COMFORT
    ]
  ]

  ask bikes [
    let adj min-one-of other turtles with [breed != actors] [distance myself]
    if adj != nobody [
      let c [distance myself] of adj
      set comfort comfort + (1 - 1.0 / (c + 1 ) ) * BIKE_COMFORT
    ]
  ]
end

to check-metrics [avg_speed]
  if speed < avg_speed
    [set jam_time jam_time + 1]

end

to adjust-speed [max_speed]
    let adjacent min-one-of other turtles with
    [
      xcor > [xcor] of myself
    ] [distance myself]

    if-else adjacent = nobody
    [
    ; Policy: Speed up when no one is in front of you.
      set speed min list (speed + random-float 0.05) max_speed
    ]
    [
    ; Policy: Slow down when there's a car close to you.
    ; Policy: Speed up when the car in front of you is far enough.
    let dist [distance myself] of adjacent - size - [size] of adjacent

    if-else dist <= TOO_CLOSE_THRESHOLD
    [set speed 0]
    [set speed speed + 0.1 * ( dist)]

    ; Clamp the speed to be between [0, SPEED_LIMIT]
    set speed max list speed 0
    set speed min list speed max_speed

    ]
end

to maneuver
    if xcor - min-pxcor >=  SPAWN_REGION [
      try-switch
    ]

    ; Begin any maneuvers
    let target targety
    facexy xcor + speed target


end

to try-switch
  let adjacent one-of other turtles in-cone (4 * CLOSENESS_IMPATIENCE_THRESHOLD) 20 with [xcor > [xcor] of myself]
  if adjacent != nobody [
    let dist [distance myself] of adjacent
    set dist (dist - size - [size] of adjacent) / dist

    if dist <= CLOSENESS_IMPATIENCE_THRESHOLD [
      let decision sigmoid  delta_impatience IMPATIENCE_THRESHOLD_DEGREE impatience_threshold
      let p make-decision
      if-else p < decision [
        if-else [pycor] of adjacent < pycor [
          set targety pycor + random size
        ] [
          set targety pycor - random size
        ]

        if targety >= BOTTOM_LANE_BOUNDARY_Y and ALLOW_OVERTAKE_BOTTOM? = false
        [ set targety pycor]

        ; Make sure to cap the ycor to be just on the road itself
        let total_lanes NUM_LANES + SPECIAL_LANES_BOTTOM
        let lower max-pycor + LANE_WIDTH / 2 - (total_lanes) * LANE_WIDTH + 1
        let upper max-pycor - LANE_WIDTH

        set targety min list targety upper
        set targety max list targety lower

        set speed speed + 0.2 * dist
      ] [
        set delta_impatience ticks
      ]
    ]
  ]
end

to run-next-epoch
  if count actors with [done? = true] = N [

    update-plots
    ask actors [

      let time (trip_ended - trip_started)

      if-else fastest_trip < 0 [
        set fastest_trip time
        set last_trip_time time
      ] [
        ; Set the probabilities. Don't forget to normalize them after.
        update-probabilities time

        set fastest_trip min list time fastest_trip
        set last_trip_time time
      ]

      reset-actor
    ]

    ask-actors-decide
  ]
end

to reset-actor
   set available? true
   set done? false
   set jam_time 0
   set comfort 0
end

to update-probabilities [time]

      ; Outputs
      let ycar 0
      let ybus 0
      let ymotor 0
      let ybike 0

      if choice = "car" [set ycar 1]
      if choice = "bus" [set ybus 1]
      if choice = "motor" [set ymotor 1]
      if choice = "bike" [set ybike 1]


      let score alpha * (fastest_trip - time) / fastest_trip +
          beta * (last_trip_time - time) / last_trip_time +
          gamma * (time - jam_time) / time +
          delta * (comfort) / time

      set pcar pcar + ycar * eta * (score)
      set pbus pbus + ybus * eta * (score)
      set pmotor pmotor + ymotor * eta * (score)
      set pbike pbike + ybike * eta * (score)


      normalize-probabilities
end

to ask-actors-decide
  ask actors [
      ; Decide on what to do
      let decision make-decision

      if decision < pcar [set choice "car"]
      set decision (decision - pcar)

      if decision >= 0 and decision < pbus [set choice "bus"]
      set decision (decision - pbus)

      if decision >= 0 and decision < pmotor [set choice "motor" ]
      set decision (decision - pmotor)

      if decision >= 0 and decision < pbike [set choice "bike"]
      set decision (decision - pbike)
  ]
end

to-report make-decision
  report random-float 1.0    ; This represnts a decision process
end

to-report get-lane-center [x]
  report max-pycor - (x + 1) * LANE_WIDTH
end

to-report get-lane [y]
  report 1
end

to-report sigmoid [x a t0]
 report 1.0 / (1.0 + exp(- a * (x - t0)))
end

to-report clamp [x minimum maximum]
  if-else x <= maximum
  [ if-else x >= minimum
    [ report x]
    [report minimum ]
  ]
    [report maximum]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
26
1109
378
-1
-1
13.72
1
10
1
1
1
0
0
0
1
-32
32
-12
12
0
0
1
ticks
30.0

BUTTON
18
390
81
423
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
85
390
148
423
go
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

INPUTBOX
809
399
859
459
N
200.0
1
0
Number

SLIDER
1033
451
1222
484
AVERAGE_IMPATIENCE
AVERAGE_IMPATIENCE
0
1
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
216
499
388
532
CAR_SPEED_LIMIT
CAR_SPEED_LIMIT
0
2.5
1.74
0.01
1
NIL
HORIZONTAL

SLIDER
1025
570
1283
603
CLOSENESS_IMPATIENCE_THRESHOLD
CLOSENESS_IMPATIENCE_THRESHOLD
0
10
2.1
0.1
1
NIL
HORIZONTAL

SLIDER
14
334
186
367
TRAFFIC_DENSITY
TRAFFIC_DENSITY
0
1
0.34
0.01
1
NIL
HORIZONTAL

SLIDER
7
176
179
209
SPAWN_PERIOD
SPAWN_PERIOD
0
20
4.0
1
1
NIL
HORIZONTAL

SLIDER
214
555
386
588
CAR_PROBABILITY
CAR_PROBABILITY
0
1
0.1474
0.01
1
NIL
HORIZONTAL

SLIDER
395
399
567
432
MAX_BUS_CAPACITY
MAX_BUS_CAPACITY
1
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
601
560
773
593
MOTOR_PROBABILITY
MOTOR_PROBABILITY
0
1
0.1355
0.01
1
NIL
HORIZONTAL

SLIDER
794
562
966
595
BIKE_PROBABILITY
BIKE_PROBABILITY
0
1
0.31
0.01
1
NIL
HORIZONTAL

SLIDER
409
504
581
537
BUS_SPEED_LIMIT
BUS_SPEED_LIMIT
0
2.5
1.24
0.01
1
NIL
HORIZONTAL

SLIDER
604
511
776
544
MOTOR_SPEED_LIMIT
MOTOR_SPEED_LIMIT
0
2.5
1.02
0.01
1
NIL
HORIZONTAL

SLIDER
799
510
971
543
BIKE_SPEED_LIMIT
BIKE_SPEED_LIMIT
0
2.5
0.56
0.01
1
NIL
HORIZONTAL

PLOT
400
712
779
1012
Actors Per Vehicle Type
generation
count
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"cars" 1.0 0 -13791810 true "" "plot count actors with [choice = \"car\"]"
"buses" 1.0 0 -2674135 true "" "plot count actors with [choice = \"bus\"]"
"motorcycles" 1.0 0 -13840069 true "" "plot count actors with [choice = \"motor\"]"
"bikes" 1.0 0 -4079321 true "" "plot count actors with [choice = \"bike\"]"

INPUTBOX
1225
79
1380
139
FASTEST_TIME_COEFF
1.0
1
0
Number

INPUTBOX
1225
155
1380
215
LAST_TIME_COEFF
0.1
1
0
Number

TEXTBOX
1217
22
1492
113
These control the hyperparameters of each actor. These are average values instead, so the actual value per actor may be slightly different
10
0.0
1

INPUTBOX
1034
504
1189
564
AVERAGE_IMPATIENCE_THRESHOLD
500.0
1
0
Number

INPUTBOX
1251
446
1406
506
IMPATIENCE_THRESHOLD_STD_DEV
100.0
1
0
Number

INPUTBOX
1254
516
1409
576
IMPATIENCE_THRESHOLD_DEGREE
1.0E-4
1
0
Number

SLIDER
13
282
208
315
TOO_CLOSE_THRESHOLD
TOO_CLOSE_THRESHOLD
0
32
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
220
403
370
442
These control the densities of the vehicles that spawn, as well their speeds.
10
0.0
1

TEXTBOX
1042
410
1192
449
These control patience parameters (i.e., how often vehicles do overtaking)
10
0.0
1

TEXTBOX
16
131
166
170
These parameters don't need to be touched. They're mostly for viz (to make it sensible) 
10
0.0
1

TEXTBOX
1201
804
1351
830
These parmeters control the lanes 
10
0.0
1

SLIDER
1186
848
1358
881
LANE_WIDTH
LANE_WIDTH
0
5
4.0
1
1
NIL
HORIZONTAL

SLIDER
1184
931
1358
964
SPECIAL_LANES_BOTTOM
SPECIAL_LANES_BOTTOM
1
4
1.0
1
1
NIL
HORIZONTAL

SLIDER
1187
892
1359
925
NUM_LANES
NUM_LANES
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
1189
722
1408
755
LEFT_LANE_SWITCH_PRIORITY
LEFT_LANE_SWITCH_PRIORITY
0
1
0.8
0.01
1
NIL
HORIZONTAL

TEXTBOX
1200
621
1350
712
These parameters control overtaking behavior. Specifically, whether to prioritize overtaking to the left (top) lane, and whether to allow overtakes on special lanes or not 
10
0.0
1

SWITCH
1192
771
1405
804
ALLOW_OVERTAKE_BOTTOM?
ALLOW_OVERTAKE_BOTTOM?
0
1
-1000

INPUTBOX
1224
228
1379
288
JAMMING_TIME_COEFF
1.0
1
0
Number

SLIDER
204
661
425
694
JAM_THRESHOLD_COEFFICIENT
JAM_THRESHOLD_COEFFICIENT
0
1
1.0
0.01
1
NIL
HORIZONTAL

PLOT
0
718
368
1016
average KPIs
time 
value 
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"jamtime" 1.0 0 -16777216 true "" "plot mean [jam_time] of actors"
"fastest time" 1.0 0 -5298144 true "" "plot mean [fastest_trip] of actors"
"last time" 1.0 0 -14454117 true "" "plot mean [last_trip_time] of actors"

INPUTBOX
1225
302
1380
362
COMFORT_COEFF
2.0
1
0
Number

SLIDER
212
606
384
639
CAR_COMFORT
CAR_COMFORT
0
1
0.9
0.01
1
NIL
HORIZONTAL

SLIDER
403
601
575
634
BUS_COMFORT
BUS_COMFORT
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
601
601
773
634
MOTOR_COMFORT
MOTOR_COMFORT
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
796
603
968
636
BIKE_COMFORT
BIKE_COMFORT
0
1
0.7
0.01
1
NIL
HORIZONTAL

PLOT
789
717
1156
1015
Probability Plots
NIL
NIL
0.0
10.0
0.0
0.25
true
true
"" ""
PENS
"pcar" 1.0 0 -13791810 true "" "plot mean [pcar] of actors"
"pbus" 1.0 0 -2674135 true "" "plot mean [pbus] of actors"
"pmotor" 1.0 0 -13840069 true "" "plot mean [pmotor] of actors"
"pbike" 1.0 0 -987046 true "" "plot mean [pbike] of actors"

SLIDER
1230
372
1402
405
ETA
ETA
0
1
0.04
0.01
1
NIL
HORIZONTAL

SLIDER
403
447
588
480
BUS_OCCUPANCY_STDDEV
BUS_OCCUPANCY_STDDEV
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
406
556
578
589
BUS_PROBABILITY
BUS_PROBABILITY
0
1
0.4178
0.01
1
NIL
HORIZONTAL

TEXTBOX
92
560
242
586
We might not use these Probabilities anymore
10
0.0
1

SLIDER
17
227
189
260
LANE_SPREAD
LANE_SPREAD
0
1
0.34
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
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
