
__includes ["komunikacija.nls" "bdi-agent.nls"]
globals [put-istrazivaca put-transportera put-graditelja]

breed [ stabla stablo]
breed [ciljevi cilj]
breed [transporteri transporter]
breed [graditelji graditelj]
breed [istrazivaci istrazivac]
breed [baze baza]

graditelji-own [uvjerenja namjere ulazne-poruke teret lista-stabala stanje]
baze-own [uvjerenja namjere ulazne-poruke lista-stabala lista-baterija buffer]
transporteri-own [uvjerenja namjere ulazne-poruke stanje target]
istrazivaci-own [uvjerenja namjere ulazne-poruke]

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
  ask one-of baze [popunu-listu-graditelja]
  set put-istrazivaca 0
  set put-transportera 0
  set put-graditelja 0

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
  ]  
  
end

to postavi-baze
  create-baze 1 [
    set shape "triangle 2"
    set color red
    setxy 0 0    
    set lista-stabala []
    set uvjerenja []
    set namjere []
    set ulazne-poruke []  
    set buffer []
  ]
  
end

to postavi-transportere
  create-transporteri br-transportera 
  [
    rand-koordinate
    set shape "transporter"
    set color red
    set target []
    set stanje "slobodan"
    set uvjerenja []
    set namjere []
    set ulazne-poruke []    
  ]
end

to postavi-graditelje
  create-graditelji br-graditelja [
    set shape "graditelj"
    set color red
    rand-koordinate 
    set teret 0
    set stanje "slobodan"
    set lista-stabala []
    set uvjerenja []
    set namjere []
    set ulazne-poruke []
  ]
end

to postavi-istrazivace
  create-istrazivaci br-istrazivaca [
    set shape "istrazivac"
    set color red
    rand-koordinate  
    set uvjerenja []
    set namjere []
    set ulazne-poruke [] 
  ]
end

to popunu-listu-graditelja
  trazi-slobodnog-graditelja
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; KRAJ POSTAVLJANJA


;;;; Pokretanje simulacije
to pokreni
  ask istrazivaci [ponasanje-istrazivaca]
  ask baze [ponasanje-baze]
  ask transporteri [ponasanje-transportera]
  ask graditelji [ponasanje-graditelji]
  tick
end




;;;;;;;;;;;;;;;;;;;;;;; PONASANJA AGENATA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; ISTRAZIVAC

to ponasanje-istrazivaca
  pokret-nasumicno "istrazivac"
  trazi-stabla
  trazi-baterije
end

to trazi-stabla
  if any? stabla in-radius 2 [posalji-koord-stabla-bazi [list xcor ycor] of stabla in-radius 2]
end

to trazi-baterije
  ; ako pronadje baterije u radiusu 2 salje upit svim transporterima da li su slobodni i oboja bateriju
  ; narancasto da je ne mora vise istraziti.
  if any? ciljevi in-radius 2 with [color = yellow] [
    trazi-slobodnog-transportera [list xcor ycor] of ciljevi in-radius 2
    ask ciljevi in-radius 2 [set color orange]
  ]
  ; prvi transporter koji odgovori dobije koordinate baterije 
  ; koordinate se salju u sadrzaju i vrsta poruke je "lokacija-baterije" 
  ; jednom kada ih posalje, istrazivac brise sve ostale ulazne poruke
  ifelse not empty? ulazne-poruke [
      let poruka dohvati-poruku
      posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "lokacija-baterije"
      set ulazne-poruke []
    ] [stop]
end

to trazi-slobodnog-transportera [ulaz]
    ; kada nadje bateriju salje upit svim transporterima da li su slobodni s koordinatama baterije u 
    ; sadrzaju
    let koord item 0 ulaz
    let x item 0 koord
    let y item 1 koord
    set koord (list (x - 2) y) ; da transporteri stanu do baterije a ne u njoj
    posalji-svim transporteri dodaj-sadrzaj koord stvori-poruku "slobodan?"
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; TRANSPORTER

to ponasanje-transportera
  osluskuj-poruke-tr
  izvrsi-namjere
end

to osluskuj-poruke-tr
  let poruka 0
  let vrsta 0
  while [not empty? ulazne-poruke]
  [
    set poruka dohvati-poruku
    set vrsta dohvati-vrstu poruka
    ; upit da li je transporter slobodan na sto odgovara da je
    if vrsta = "slobodan?" and stanje = "slobodan" [posalji dodaj-primatelja dohvati-posiljatelja poruka dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "slobodan"]
    ; dobivene su lokacije baterije i samim time je zadana namjera da se ode do lokacije 
    ; stanje se mijenja u "zauzet"
    if vrsta = "lokacija-baterije" [
      set stanje "zauzet"
      ; zahtjev za mostom salje zahtjev i koordinate patcha ispred transportera gdje je potreban most
      dodaj-namjeru (word "zahtjev-za-mostom " (list (item 0 dohvati-sadrzaj poruka + 1) item 1 dohvati-sadrzaj poruka)) (word "napravljen-most " dohvati-sadrzaj poruka)
      dodaj-namjeru (word "idi-prema " dohvati-sadrzaj poruka) (word "na-odredistu " dohvati-sadrzaj poruka)
      ]
  ]
end

to zahtjev-za-mostom [koord]
  posalji dodaj-primatelja id-baze dodaj-sadrzaj koord stvori-poruku "zahtjev-most"
end

to-report napravljen-most [koord]
  ifelse [pcolor] of patch (item 0 koord + 1) item 1 koord = blue
  [report false]
  [show (word "napravljen most za mene!" koord)
    report true]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; BAZA

to ponasanje-baze
  
  osluskuj-poruke-bz
  
end

to osluskuj-poruke-bz
  let poruka 0
  let vrsta 0
  while [not empty? ulazne-poruke]
  [
    set poruka dohvati-poruku
    set vrsta dohvati-vrstu poruka
    if vrsta = "zahtjev-most" [
      ifelse empty? buffer [posalji poruka]
       [ let slobodniGraditelj first buffer
        posalji dodaj-primatelja (word slobodniGraditelj) dodaj-sadrzaj dohvati-sadrzaj poruka stvori-poruku "koord-mosta"
        posalji dodaj-primatelja (word slobodniGraditelj) dodaj-sadrzaj dohvati-koord-stabla  stvori-poruku "posijeci-stablo"
        posalji dodaj-primatelja (word slobodniGraditelj) dodaj-sadrzaj dohvati-koord-stabla  stvori-poruku "posijeci-stablo"
        posalji dodaj-primatelja (word slobodniGraditelj) dodaj-sadrzaj dohvati-koord-stabla  stvori-poruku "posijeci-stablo"
        set buffer but-first buffer]
      ]
  ]
end
  
to-report dohvati-koord-stabla
  let odgovor first lista-stabala
  set lista-stabala but-first lista-stabala
  report odgovor
end

to trazi-slobodnog-graditelja
    posalji-svim graditelji dodaj-sadrzaj "" stvori-poruku "slobodan?"
    stop
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;; GRADITELJ
to ponasanje-graditelji
  osluskuj-poruke-gr
  izvrsi-namjere
end

to osluskuj-poruke-gr
  let poruka 0
  let vrsta 0
  let id who
  while [not empty? ulazne-poruke]
  [
    set poruka dohvati-poruku
    set vrsta dohvati-vrstu poruka
    if vrsta = "slobodan?" and stanje = "slobodan" [ask turtle id-baze [
        set buffer fput id buffer
        ]
     ]
    if vrsta = "koord-mosta" [
      set stanje "zauzet"
      dodaj-namjeru (word "napravi-most " dohvati-sadrzaj poruka) "true"
      dodaj-namjeru (word "idi-prema " dohvati-sadrzaj poruka) (word "na-odredistu " dohvati-sadrzaj poruka)
  ]
    if vrsta = "posijeci-stablo" [
      dodaj-namjeru (word "idi-prema " dohvati-sadrzaj poruka) (word "na-odredistu " dohvati-sadrzaj poruka)
      dodaj-namjeru (word "posijeci-stablo") "true"
  ]
    

]
end

to posijeci-stablo
  ask stabla in-radius 1 [die]
  set teret teret + 1  
end

to napravi-most [koord]
  ask patch item 0 koord item 1 koord [set pcolor brown]
end














to pokret-nasumicno [tip]
  fd 1
  set heading heading + random 30 - random 30
  if tip = "istrazivac" [set put-istrazivaca put-istrazivaca + 1]
  if tip = "graditelj" [set put-graditelja put-graditelja + 1]
  if tip = "transporter" [set put-transportera put-transportera + 1]
end

to posalji-koord-stabla-bazi [poruka]
  ask baze [
    foreach poruka [set lista-stabala fput item 0 poruka lista-stabala]
    set lista-stabala remove-duplicates lista-stabala
    ]
end

to posalji-bazi-baterije [poruka]
  ask baze [
    foreach poruka [set lista-baterija fput ? lista-baterija]
    set lista-baterija remove-duplicates lista-baterija
    ]
end

to posijeci [koord]
  
  set heading towardsxy-nowrap (first koord) (item 1 koord)
  fd 1
end

to pokret [tip]
  fd 1
  if tip = "istrazivac" [set put-istrazivaca put-istrazivaca + 1]
  if tip = "graditelj" [set put-graditelja put-graditelja + 1]
  if tip = "transporter" [set put-transportera put-transportera + 1]  
end

;;; kopirane procedure
to idi-prema [cilj]
   fd 1
   if is-number? cilj 
   [if not ((xcor = [xcor] of turtle cilj) and (ycor = [ycor] of turtle cilj))   
     [set heading towards-nowrap turtle cilj] ];; ako mozemo u tom smjeru
 
   if is-list? cilj 
   [if not ((xcor = first cilj) and (ycor = item 1 cilj)) 
     [set heading towardsxy-nowrap (first cilj) (item 1 cilj)] ];; ako mozemo u tom smjeru
end 

to-report na-odredistu [cilj]
if is-number? cilj [
 ifelse ([who] of one-of turtles-here = cilj) 
    [report true]
    [report false]
    ]
    
if is-list? cilj [
 ifelse (abs (xcor - first cilj) < 0.7 ) and (abs (ycor - item 1 cilj) < 0.7)
    [report true]
    [report false]
    ]
end  

to-report id-baze
  report first [who] of baze
end

;;; kraj kopiranih procedura

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
20
20
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
-20
20
-20
20
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
13
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
256
250
428
283
br-istrazivaca
br-istrazivaca
1
20
9
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
3
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
35
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
5
1
1
NIL
HORIZONTAL

MONITOR
11
303
85
348
Istrazivac
put-istrazivaca
17
1
11

MONITOR
88
304
157
349
Graditelj
put-graditelja
17
1
11

MONITOR
10
350
102
395
Transporter
put-transportera
17
1
11

@#$#@#$#@
Inteligentni agenti - 2014
PMFST

ALGORITAM:
- istraživač pretražuje svijet
-- šalje koordinate drva bazi
-- nađe bateriju
-- šalje koordinate slobodnom transporteru 
- transporter dođe do koordinata baterije
-- zatraži od baze most
- baza šalje zahtjev za most najbližem slobodnom graditelju
- izabrani graditelj šalje zahtjev za najbližim drvima za most bazi
- baza šalje koordinate najbližih drva graditelju
- graditelj ih pokupi
-- dolazi do cilja
-- napravi most
-- postaje slobodan
- transporter pokupi bateriju
-- prenese je do baze
-- postaje slobodan

POTREBNE PROCEDURE:
> istraživač:
- pretrazuj-svijet
- trazi-drva
- posalji-koord-stabla-bazi
- trazi-baterije
- posalji-koord-baterije-transporteru (slobodan transporter)

> transporter: (stanje:slobodan/zauzet)
- idi-do [koord]
- trazi-most
- cekaj-most
- pokupi-bateriju
- predaj-bateriju

> graditelj: (stanje:slobodan/zauzet)
- trazi-koord-stabla
- idi-do [koord]
- posjeci-stablo
- izgradi-most

> baza: (lista-stabala)
- nadji-najblizeg-graditelja [koord-cilja]
- nadji-najblize-stablo [koord-graditelja]
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
