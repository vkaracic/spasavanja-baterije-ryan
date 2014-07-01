
__includes ["komunikacija.nls" "bdi-agent.nls"]



breed [ stabla stablo]
breed [ciljevi cilj]
breed [transporteri transporter]
breed [graditelji graditelj]
breed [istrazivaci istrazivac]
breed [baze baza]

graditelji-own [uvjerenja namjere ulazne-poruke stanje teret koord-mosta narucilac]
istrazivaci-own [uvjerenja namjere ulazne-poruke stanje imam-transportera]
transporteri-own [uvjerenja namjere ulazne-poruke stanje teret imam-graditelja]
baze-own [uvjerenja namjere ulazne-poruke lista-stabala koord-mostova]

globals [mostovi baterije broj-ciljeva]
patches-own [otok]

;;; Postavljanje okruzenja

to postavi
  ca
  reset-ticks
  random-seed seed
  postavi-baze
  postavi-otok  
  postavi-stabla
  postavi-transportere
  postavi-graditelje
  postavi-istrazivace
  set mostovi []
  set baterije []
end

;;; Stvaranje prepreka u okruzenju
;;; Broj prepreka ovisi o vrijednosti na sucelju 
to postavi-stabla
  create-stabla br-stabala [
    rand-koordinate
    set shape "tree" 
    set color green
  ]
end 

to postavi-otok
  create-ciljevi br-ciljeva
  [
    rand-koordinate
    set color yellow
    set shape "square"
    ask neighbors
    [ 
      set pcolor blue
      set otok 1
    ]    
    set broj-ciljeva br-ciljeva
  ]  
  
end

to postavi-baze
  create-baze 1 [
    set shape "triangle 2"
    set color red
    setxy 20 20   
    set lista-stabala []
    set uvjerenja []
    set namjere []
    set ulazne-poruke [] 
    set koord-mostova [[0 0]]
  ]
end

to postavi-transportere
  create-transporteri br-transportera 
  [
    rand-koordinate
    set shape "transporter"
    set color red
    set uvjerenja []
    set namjere []
    set ulazne-poruke [] 
    set stanje "slobodan"
    set teret 0
    set imam-graditelja 0
  ]
end

to postavi-graditelje
  create-graditelji br-graditelja [
    set shape "graditelj"
    set color red
    rand-koordinate 
    set uvjerenja []
    set namjere []
    set ulazne-poruke [] 
    set stanje "slobodan"
    set teret 0
    set koord-mosta 0
    set narucilac 0
  ]
end

to postavi-istrazivace
  create-istrazivaci br-istrazivaca [
    set shape "istrazivac"
    set color red
    rand-koordinate  
    set uvjerenja []
    set namjere [["pretrazivanje" "false"]]
    set ulazne-poruke []
    set imam-transportera 0
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; KRAJ POSTAVLJANJA


;;;; Pokretanje simulacije
to pokreni
  if broj-ciljeva = 0 [stop]
  ask istrazivaci [ponasanje-istrazivaca]
  ask transporteri [ponasanje-transportera]
  ask graditelji [ponasanje-graditelji]
  ask baze [ponasanje-baze]
  tick
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; ISTRAZIVAC 

to ponasanje-istrazivaca
  izvrsi-namjere-provjera
  osluskuj-poruke-is
end

to pretrazivanje
  trazi-stabla
  trazi-baterije
  pokret-nasumicno
end

to trazi-stabla
  if any? stabla in-radius 2 [posalji-koord-stabla-bazi [list xcor ycor] of stabla in-radius 2]
end

to posalji-koord-stabla-bazi [poruka]
  ask baze [
    foreach poruka [set lista-stabala fput item 0 poruka lista-stabala]
    set lista-stabala remove-duplicates lista-stabala
    ]
end

to trazi-baterije
  if any? ciljevi in-radius 1 with [color = yellow] [
    let koord [list xcor ycor] of ciljevi in-radius 1
    ask ciljevi in-radius 1 [set color orange] 
    dodaj-namjeru "reset-transp" "true"
    dodaj-namjeru (word "trazi-slobodnog-transportera " koord) "nasao-transportera"
  ]
end

to reset-transp
  set imam-transportera 0
end

to trazi-slobodnog-transportera [ulaz]
    let koord item 0 ulaz
    let x item 0 koord
    let y item 1 koord
    set koord (list x y)
    posalji-svim transporteri dodaj-sadrzaj koord stvori-poruku "slobodan?"
end

to osluskuj-poruke-is
  let poruka 0
  let vrsta 0
  let id who
  while [not empty? ulazne-poruke]
  [
    set poruka dohvati-poruku
    set vrsta dohvati-vrstu poruka
    if vrsta = "slobodan"[
      set ulazne-poruke []
      ;pop-intention
      posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "lokacija-baterije" 
      stop
    ]
    if vrsta = "idem-do-tebe" [
      set imam-transportera imam-transportera + 1
      set ulazne-poruke []
    ]
  ]
end

to-report nasao-transportera
  ifelse imam-transportera = 1
  [report true]
  [report false]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; TRANSPORTER

to ponasanje-transportera
  osluskuj-poruke-tr
  izvrsi-namjere-provjera
end

to osluskuj-poruke-tr
  let poruka 0
  let vrsta 0
  let id who
  while [not empty? ulazne-poruke]
  [
    set poruka dohvati-poruku
    set vrsta dohvati-vrstu poruka
    if vrsta = "slobodan?" and stanje = "slobodan" [
      posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "slobodan"
      stop
    ]
    if vrsta = "lokacija-baterije" [
      set stanje "zauzet"
      posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "idem-do-tebe"
      let koord dohvati-sadrzaj poruka
      let x (item 0 koord - 3)
      let y item 1 koord
      let rnd random 3
      ifelse any? transporteri-at x y [
        dodaj-namjeru "oslobodi-se" "oslobodjen"
      ]
      [
        dodaj-namjeru (word "zahtjev-za-most " (list (x + 2) y)) (word "zaposlen-graditelj " koord)
        dodaj-namjeru (word "idi-prema-tr " (list x y)) (word "na-odredistu " (list x y))
      ]
      dodaj-namjeru (word "idi-prema-tr " (list (x - rnd) y)) (word "na-odredistu " (list (x - rnd) y))
      set ulazne-poruke []
      
    ]
    if vrsta = "slobodan" [
      posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "gradi-most"
      set ulazne-poruke []
      ;pop-intention
    ]
    if vrsta = "gradim-ti-most" [
      set imam-graditelja 1
      set ulazne-poruke []
    ]
    if vrsta = "izgradjen-ti-most" [
      set namjere []
      show "izgradjen mi most"
      let koord-bat (list (item 0 dohvati-sadrzaj poruka + 1) item 1 dohvati-sadrzaj poruka)
      dodaj-namjeru "oslobodi-se" "oslobodjen"
      dodaj-namjeru "ostavi-bateriju" "ostavljena-baterija"
      dodaj-namjeru (word "idi-prema-tr " (list 20 20)) (word "na-odredistu " (list 20 20))
      dodaj-namjeru (word "pokupi-bateriju " koord-bat) "baterija-pokupljena"
      dodaj-namjeru (word "idi-prema-tr " koord-bat) (word "na-odredistu " koord-bat)
    ]
  ]
end

to-report zaposlen-graditelj [koord]
  ifelse not member? koord baterije [
  ifelse imam-graditelja = 1 or [pcolor] of patch (item 0 koord - 1) item 1 koord = black
  [report true]
  [report false]
  ]
  [
    dodaj-namjeru "oslobodi-se" "oslobodjen"
    report true
  ]
end

to ostavi-bateriju
  set teret 0
  set broj-ciljeva broj-ciljeva - 1
end

to-report ostavljena-baterija
  ifelse teret = 0
  [report true]
  [report false]  
end

to-report oslobodjen
  ifelse stanje = "slobodan"
  [report true]
  [report false]
end

to-report baterija-pokupljena
  ifelse teret = 1
  [report true]
  [report false]
end

to pokupi-bateriju [koord]
  if any? ciljevi in-radius 1 [
  ask ciljevi in-radius 1 [die]
  set baterije fput koord baterije
  set teret 1]
  stop
end

to oslobodi-se
  set teret 0
  set stanje "slobodan"
  set imam-graditelja 0
  set namjere []
  fd 2
  stop
end

to zahtjev-za-most [koord]
  posalji-svim graditelji dodaj-sadrzaj koord stvori-poruku "slobodan?"
  stop
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; BAZA 

to ponasanje-baze
  osluskuj-poruke-bz
  stop
end

to osluskuj-poruke-bz
  let poruka 0
  let vrsta 0
  let id who
  while [not empty? ulazne-poruke]
  [
    set poruka dohvati-poruku
    set vrsta dohvati-vrstu poruka
    if vrsta = "zahtjev-za-stablima" [
      if not empty? lista-stabala [
        posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj item 0 lista-stabala stvori-poruku "koord-stabla"
        set lista-stabala but-first lista-stabala]
      
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;; GRADITELJI 

to ponasanje-graditelji
  izvrsi-namjere-provjera
  osluskuj-poruke-gr

  stop
end

to osluskuj-poruke-gr
  let poruka 0
  let vrsta 0
  let id who
  while [not empty? ulazne-poruke]
  [
    set poruka dohvati-poruku
    set vrsta dohvati-vrstu poruka
    if vrsta = "slobodan?" and stanje = "slobodan" [
      let provjera dohvati-sadrzaj poruka
      posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "slobodan"
      set ulazne-poruke []
    ]
    
    if vrsta = "gradi-most" [
      let provj dohvati-sadrzaj poruka
      let tmp 0
      ;set stanje "zauzet"
      
      if not member? provj mostovi
      [      
      set stanje "zauzet"
      set narucilac dohvati-posiljatelja poruka
      set koord-mosta dohvati-sadrzaj poruka
      
      posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj "" stvori-poruku "gradim-ti-most"
      dodaj-namjeru "pokreni-transportera" "oslobodjen"
      dodaj-namjeru "izgradnja-mosta" (word "izgradjen-most " koord-mosta)
      dodaj-namjeru (word "idi-prema-gr " koord-mosta) (word "na-odredistu " koord-mosta)
      dodaj-namjeru (word "trazi-koord-stabla") "dovoljno-drva"
      
      
      set mostovi fput provj mostovi
      ]
      
    
    ]
    if vrsta = "koord-stabla" [
      dodaj-namjeru (word "posijeci-stablo") "posjeceno-stablo"
      dodaj-namjeru (word "idi-prema-gr " dohvati-sadrzaj poruka) (word "na-odredistu " dohvati-sadrzaj poruka)
    ]
  ]
end

to-report posjeceno-stablo
  ifelse not any? stabla in-radius 0.7
  [report true]
  [report false]
end

to-report dovoljno-drva
  ifelse teret < 3 and stanje = "zauzet"
  [report false]
  [report true]
end

to trazi-koord-stabla
  posalji dodaj-primatelja id-baze dodaj-sadrzaj "" stvori-poruku "zahtjev-za-stablima"
end

to-report izgradjen-most [koord]
  ifelse [pcolor] of patch item 0 koord item 1 koord = black
  
  [report true]
  [report false]
end

to izgradnja-mosta
  ask patch item 0 koord-mosta item 1 koord-mosta [set pcolor black]
  set teret teret - 3
  lt 180
  fd 2
  stop
end

to pokreni-transportera
  posalji dodaj-primatelja narucilac dodaj-sadrzaj koord-mosta stvori-poruku "izgradjen-ti-most"

  set ulazne-poruke []
  set stanje "slobodan"
end

to posijeci-stablo

      if any? stabla in-radius 0.7[
        ask stabla in-radius 0.7 [die]
        set teret teret + 1
      ]  


end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Zajednicke procedure

to pokret-nasumicno
  
  fd 1
  set heading heading + random 30 - random 30
end

to zaobidji-prepreku
  set heading heading + random 45
end  

to-report detektiraj-prepreku-tr
  ifelse any? stabla in-cone 2 90 or any? graditelji in-cone 2 90 or any? other transporteri in-cone 2 90 
  [report true]
  [report false]
end

to-report detektiraj-prepreku-gr
  ifelse any? other graditelji in-cone 2 60 or any? transporteri in-cone 2 60
  [report true]
  [report false]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Kopirane procedure

to idi-prema-tr [cilj]
  ifelse detektiraj-prepreku-tr [zaobidji-prepreku]
  [
   fd 1
   if is-number? cilj 
   [if not ((xcor = [xcor] of turtle cilj) and (ycor = [ycor] of turtle cilj))   
     [set heading towards-nowrap turtle cilj] ];; ako mozemo u tom smjeru
 
   if is-list? cilj 
   [if not ((xcor = first cilj) and (ycor = item 1 cilj)) 
     [set heading towardsxy-nowrap (first cilj) (item 1 cilj)] ];; ako mozemo u tom smjeru
   
  ]
end 

to idi-prema-gr [cilj]
  ifelse detektiraj-prepreku-gr [zaobidji-prepreku]
  [
   fd 1
   if is-number? cilj 
   [if not ((xcor = [xcor] of turtle cilj) and (ycor = [ycor] of turtle cilj))   
     [set heading towards-nowrap turtle cilj] ];; ako mozemo u tom smjeru
 
   if is-list? cilj 
   [if not ((xcor = first cilj) and (ycor = item 1 cilj)) 
     [set heading towardsxy-nowrap (first cilj) (item 1 cilj)] ];; ako mozemo u tom smjeru
   
  ]
end 

to-report na-odredistu [cilj]
if is-number? cilj [
 ifelse ([who] of one-of turtles-here = cilj) 
    [report true]
    [report false]
    ]
    
if is-list? cilj [
 ifelse (abs (xcor - first cilj) < 0.5 ) and (abs (ycor - item 1 cilj) < 0.5)
    [report true]
    [report false]
    ]
end  

to-report id-baze
  report first [who] of baze
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Pomocne procedure
;;; Nasumicno postaljva novog agenta u okruzenje, 
;;; pri tome pazi da ga ne postavi iznad drugog agenta
to rand-koordinate
  let x 0
  let y 0
  
  loop [ 
    set x random-pxcor
    set y random-pycor
    if not any? turtles-on patch x y and not (abs x < 4 and abs y < 4) and not [otok = 1] of patch x y [setxy x y stop]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
481
10
1024
574
-1
-1
13.0
1
10
1
1
1
0
1
1
1
0
40
0
40
0
0
1
ticks
30.0

SLIDER
257
169
429
202
br-transportera
br-transportera
0
20
8
1
1
NIL
HORIZONTAL

BUTTON
20
17
91
50
Postavi
postavi
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
257
106
429
139
br-stabala
br-stabala
0
50
50
1
1
NIL
HORIZONTAL

SLIDER
257
249
429
282
br-istrazivaca
br-istrazivaca
1
20
20
1
1
NIL
HORIZONTAL

SLIDER
257
211
429
244
br-graditelja
br-graditelja
0
20
5
1
1
NIL
HORIZONTAL

BUTTON
96
17
190
50
Trazi
pokreni
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
195
18
289
51
Trazi
pokreni
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
256
377
408
410
prikazi-namjere
prikazi-namjere
1
1
-1000

SWITCH
256
413
408
446
prikazi-poruke
prikazi-poruke
1
1
-1000

SLIDER
14
62
186
95
seed
seed
0
100
85
1
1
NIL
HORIZONTAL

TEXTBOX
21
115
171
213
Seed varijabla sluzi za generiranje pseudonasumicnih brojeva.\nIsta seed vrijednost daje jednake pozicije agenata te se moze koristiti za usporedbu rezultata.
11
0.0
0

SLIDER
256
70
428
103
br-ciljeva
br-ciljeva
0
10
10
1
1
NIL
HORIZONTAL

@#$#@#$#@
Inteligentni agenti - 2014
PMFST
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
Circle -7500403 true true 30 30 240

circle 2
false
0
Circle -7500403 true true 16 16 270
Circle -16777216 true false 46 46 210

circle 3
true
0
Circle -7500403 false true 0 0 300

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

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

graditelj
true
0
Rectangle -7500403 true true 60 45 240 270
Circle -2674135 true false 74 104 152
Rectangle -1184463 true false 75 15 105 105
Rectangle -1184463 true false 135 15 165 90
Rectangle -1184463 true false 195 15 225 105

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

istrazivac
true
0
Rectangle -1184463 true false 45 75 120 240
Rectangle -1184463 true false 180 75 255 240
Rectangle -7500403 true true 120 30 180 285
Rectangle -16777216 true false 60 90 105 105
Rectangle -16777216 true false 60 120 105 135
Rectangle -16777216 true false 60 150 105 165
Rectangle -16777216 true false 60 180 105 195
Rectangle -16777216 true false 60 210 105 225
Rectangle -16777216 true false 195 210 240 225
Rectangle -16777216 true false 195 180 240 195
Rectangle -16777216 true false 195 150 240 165
Rectangle -16777216 true false 195 120 240 135
Rectangle -16777216 true false 195 90 240 105

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

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
Polygon -7500403 true true 60 270 150 0 240 270 15 105 285 105
Polygon -7500403 true true 75 120 105 210 195 210 225 120 150 75

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

transporter
true
0
Rectangle -1184463 true false 45 45 255 255
Rectangle -13345367 true false 75 15 225 75
Line -13345367 false 45 90 150 90
Line -13345367 false 150 90 255 90
Rectangle -6459832 true false 30 75 60 135
Rectangle -6459832 true false 30 165 60 225
Rectangle -6459832 true false 240 75 270 135
Rectangle -6459832 true false 240 165 270 225
Circle -2674135 true false 118 43 62
Rectangle -7500403 true true 105 120 195 255

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
NetLogo 5.0.5
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

simple
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0

@#$#@#$#@
0
@#$#@#$#@
