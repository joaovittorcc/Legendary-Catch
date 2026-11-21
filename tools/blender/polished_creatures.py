"""Finished silhouettes for the six small-creature pilots."""

import math

from creature_mesh import Piece
from lib_creatures import painted_head, station


def swept_fin(name, sign, attach, reach, swatch="fin"):
    x,y,z=attach
    fin=Piece(name)
    fin.sweep([station(sign*x,y,z,.064,.13),station(sign*(x+.24*reach),y+.05,z-.055,.070,.21),
               station(sign*(x+.64*reach),y+.17,z-.105,.054,.15),
               station(sign*(x+reach),y+.33,z-.12,.012,.025)],swatch,sides=6,reference=(0,0,1))
    return fin


def fins(attach, reach, swatch="fin"):
    return [swept_fin(name,s,attach,reach,swatch) for name,s in (("FinL",1),("FinR",-1))]


def fish(p):
    w,h=p.get("width",.39),p.get("height",.48)
    body,tail,dorsal=(Piece(n) for n in ("Body","Tail","Fins"))
    body.sweep([station(0,-.57,.015,w*.75,h*.77),station(0,-.32,.01,w*.98,h*.99),
                station(0,.02,0,w*1.07,h*1.01),station(0,.39,-.005,w*.88,h*.86),
                station(0,.72,.015,w*.53,h*.53),station(0,.96,.04,.12,.15)],
               "skin",sides=14)
    head=painted_head((0,-.60,.02),(w*.91,.43,h*.80))
    for s in (-1,1):
        tail.sweep([station(0,.83,.038,.130,.132),station(0,1.10,s*.13,.091,.22),
                    station(0,1.32,s*.30,.067,.23),station(0,1.49,s*.43,.015,.030)],
                   "fin",sides=7,reference=(1,0,0))
    dorsal.sweep([station(0,-.008,h*.79,.082,.26),station(0,.19,h*1.22,.056,.27),
                  station(0,.46,h*1.32,.029,.147),station(0,.65,h*1.16,.016,.046)],
                 "fin",sides=6)
    return [body,head,tail,dorsal,*fins((w*.80,.0,-h*.32),.37)]


def shrimp(p):
    body,tail,legs,feelers,claws=(Piece(n) for n in ("Body","Tail","Legs","Fins","Claws"))
    body.sweep([station(0,-.49,.32,.31,.30),station(0,-.25,.36,.40,.37),
                station(0,.07,.30,.415,.39),station(0,.37,.13,.36,.32),
                station(0,.53,-.15,.26,.23),station(0,.49,-.42,.17,.16)],
               "skin",sides=12)
    head=painted_head((0,-.61,.36),(.40,.35,.35),levels=5)
    for s in (-1,0,1):
        tail.sweep([station(0,.49,-.32,.14,.134),station(s*.175,.60,-.58,.124,.17),
                    station(s*.26,.76,-.63,.046,.09)],"fin",sides=6,reference=(1,0,0))
    for s in (-1,1):
        feelers.sweep([station(s*.14,-.46,.62,.045,.041),station(s*.215,-.53,.77,.043,.036),
                       station(s*.34,-.56,.89,.033,.027),station(s*.48,-.61,.94,.013,.016)],
                      "fin",sides=5)
        claws.sweep([station(s*.27,-.34,.16,.064,.064),station(s*.42,-.49,-.04,.082,.093),
                     station(s*.48,-.71,.025,.042,.031)],"fin",sides=5)
        for i in range(3):
            y=.29-i*.20
            legs.sweep([station(s*.23,y,-.02,.040,.043),station(s*.33,y-.08,-.24,.033,.034),
                        station(s*.52,y-.10,-.33+.028*i,.016,.018)],"fin",sides=3)
    return [body,head,tail,legs,feelers,claws]


def star(p):
    body,tail,hat=(Piece(n) for n in ("Body","Tail","Extra"))
    angles=[math.tau*(lobe+offset)/5 for lobe in range(5) for offset in (0,.19,.40,.60,.81)]
    radii=(1.13,.87,.62,.62,.87)*5
    profile=[(.32,-.157),(.89,-.089),(1,.038),(.55,.21)]
    body._rings([[(r*scale*math.sin(a),y,r*scale*math.cos(a)) for r,a in zip(radii,angles)]
                 for scale,y in profile],"skin")
    head=painted_head((0,-.10,.04),(.46,.187,.40),sides=12,levels=6)
    tail.oval((0,.24,-.04),(.27,.15,.24),"skin",sides=7,levels=4)
    hat.sweep([station(-.012,.033,.685,.29,.20),station(-.009,.033,.80,.284,.184),
               station(-.075,.037,.97,.225,.154),station(-.21,.032,1.10,.116,.083),
               station(-.34,.028,1.08,.040,.033)],"cap",sides=8)
    hat.oval((-.36,.022,1.08),(.097,.092,.091),"cream",sides=6,levels=4)
    return [body,head,tail,hat]


def jelly(p):
    body,tail,tentacles,ruff=(Piece(n) for n in ("Body","Tail","Tentacles","Fins"))
    body.sweep([station(0,.075,-.04,.52,.49),station(0,.063,.03,.80,.66),
                station(0,.068,.16,.85,.70),station(0,.08,.37,.78,.66),
                station(0,.085,.57,.61,.53),station(0,.09,.72,.36,.33),
                station(0,.095,.77,.085,.086)],"skin",sides=14)
    ruff.sweep([station(0,.081,-.075,.54,.49),station(0,.079,-.022,.754,.608),
                station(0,.072,.045,.785,.64)],"fin",sides=14)
    head=painted_head((0,-.50,.24),(.503,.313,.308))
    tail.sweep([station(0,.29,-.026,.134,.13),station(-.04,.389,-.28,.109,.10),
                station(-.09,.45,-.51,.086,.08),station(.029,.52,-.73,.064,.057),
                station(.17,.58,-.93,.030,.03)],"tendril",sides=7)
    arms=p.get("arms",5)
    for i in range(arms):
        t=i/max(1,arms-1)-.5
        x=t*1.23
        tentacles.sweep([station(x*.88,-.075,-.055,.100,.10),
                         station(x-.052,-.19,-.28,.087,.085),
                         station(x-.08,-.145,-.46,.078,.070),
                         station(x+.12,-.11,-.74-.16*abs(t),.062,.065),
                         station(x+.15,-.02,-.92,.053,.054),
                         station(x+.07,.04,-1.035+.24*abs(t),.018,.019)],
                        "tendril" if i%2 else "fin",sides=5)
    return [body,head,tail,tentacles,ruff]


def seahorse(p):
    body,tail,dorsal=(Piece(n) for n in ("Body","Tail","Fins"))
    body.sweep([station(0,.26,-.67,.22,.18),station(0,.14,-.50,.29,.25),
                station(0,.071,-.22,.409,.365),station(0,.06,.08,.441,.376),
                station(0,.077,.36,.35,.28),station(0,-.09,.62,.28,.23),
                station(0,-.23,.79,.27,.22),station(0,-.36,.91,.22,.19)],
               "skin",sides=12)
    head=painted_head((0,-.46,.89),(.43,.41,.347),sides=12,levels=5)
    head.sweep([station(0,-.666,.79,.177,.121),station(0,-.831,.745,.146,.103),
                station(0,-1.01,.747,.109,.078),station(0,-1.051,.759,.085,.063)],
               "cream",sides=8)
    for s in (-1,0,1):
        head.sweep([station(s*.13,-.322,1.12,.065,.069),
                    station(s*.23,-.27,1.33-abs(s)*.057,.018,.027)],"cap",sides=5)
    tail.sweep([station(0,.21,-.53,.18,.15),station(.11,.29,-.81,.185,.17),
                station(.38,.38,-.98,.149,.16),station(.68,.48,-.85,.117,.13),
                station(.78,.55,-.60,.099,.093),station(.63,.57,-.45,.071,.068),
                station(.45,.60,-.53,.029,.030)],"tail",sides=9,steps=2)
    dorsal.sweep([station(0,.217,.09,.069,.32),station(0,.41,.20,.060,.36),
                  station(0,.55,.37,.051,.28),station(0,.62,.62,.019,.068)],"fin",sides=9)
    return [body,head,tail,dorsal,*fins((.27,-.048,.21),.33)]


def turtle(p):
    body,tail,shell,legs,bloom=(Piece(n) for n in ("Body","Tail","Shell","Legs","Extra"))
    body.oval((0,.15,-.12),(.655,.76,.25),"cream",sides=11,levels=6)
    shell.sweep([station(0,.14,-.13,.58,.70),station(0,.14,-.035,.72,.83),
                 station(0,.14,.126,.76,.86),station(0,.15,.31,.675,.76),
                 station(0,.18,.50,.49,.59),station(0,.24,.63,.26,.35),
                 station(0,.27,.67,.073,.087)],"shell",sides=11)
    bloom.sweep([station(-.15,-.11,.545,.049,.049),
                 station(-.15,-.11,.751,.043,.043)],"shell",sides=4)
    for i in range(4):
        a=math.tau*i/4
        bloom.oval((-.15+.179*math.sin(a),-.110+.153*math.cos(a),.748),
                   (.201,.190,.113),"petal",sides=6,levels=4,tilt=.38*math.sin(a))
    bloom.oval((-.15,-.110,.807),(.107,.098,.087),"cream",sides=4,levels=3)
    head=painted_head((0,-.706,.055),(.430,.445,.403),sides=14,levels=7)
    tail.sweep([station(0,.72,-.12,.157,.14),station(0,.96,-.075,.108,.107),
                station(0,1.13,-.05,.034,.036)],"skin",sides=7)
    for s in (-1,1):
        legs.sweep([station(s*.43,.49,-.108,.16,.105),station(s*.61,.57,-.15,.20,.097),
                    station(s*.72,.73,-.174,.177,.083),station(s*.81,.87,-.12,.041,.034)],
                   "fin",sides=6,reference=(0,1,0))
    flippers=[]
    for name,s in (("FinL",1),("FinR",-1)):
        flipper=Piece(name)
        flipper.sweep([station(s*.48,-.39,-.09,.150,.104),station(s*.64,-.47,-.204,.214,.126),
                       station(s*.82,-.49,-.35,.206,.104),station(s*.98,-.43,-.43,.073,.037)],
                      "fin",sides=6,reference=(0,1,0))
        flippers.append(flipper)
    return [body,head,tail,shell,legs,bloom,*flippers]


BUILDERS = {"fish":fish,"shrimp":shrimp,"star":star,"jelly":jelly,
            "seahorse":seahorse,"turtle":turtle}
