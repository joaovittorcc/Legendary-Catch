"""Light rigid creature families. Blender faces -Y and uses Z as up."""

import math

from creature_mesh import Piece


def station(x, y, z, width, depth):
    return ((x, y, z), width, depth)


def face(center, radii, detail=False, eye_scale=1.0, sleepy=False, compact=False):
    x, y, z = center
    width, depth, height = radii
    head = Piece("Head")
    head.oval(center, radii, "main", sides=10 if detail else 8, levels=4 if compact else 5)
    for side in (-1, 1):
        ex = x + side * width * 0.42
        ez = z + height * 0.12
        ey = y - depth * 0.85
        ew, eh = width * 0.225 * eye_scale, height * 0.32 * eye_scale
        if sleepy:
            head.sweep([station(ex-ew,ey,ez,.015,.014),
                        station(ex,ey-.036,ez-.033,.026,.020),
                        station(ex+ew,ey,ez,.015,.014)],"ink",sides=5,reference=(0,1,0))
            continue
        head.sweep([station(ex, ey + .025, ez, ew, eh),
                    station(ex, ey - .048, ez, ew * .86, eh * .87)], "cream", sides=6 if compact else 8)
        px = ex - side * ew * .18
        head.sweep([station(px, ey - .043, ez, ew * .55, eh * .70),
                    station(px, ey - .064, ez, ew * .43, eh * .58)], "ink", sides=6 if compact else 7)
        if detail:
            head.sweep([station(px - .018, ey - .063, ez + .022, ew * .15, eh * .20),
                        station(px - .018, ey - .073, ez + .022, ew * .12, eh * .16)], "cream", sides=4)
    mouth_y = y - depth * .96
    start, finish = x - width*.18, x + width*.18
    mouth_z = z - height*.30
    head.sweep([station(start,mouth_y,mouth_z,.013,.013),
                station(x,mouth_y-.028,mouth_z-.040,.024,.021),
                station(finish,mouth_y,mouth_z,.013,.013)], "ink", sides=4, reference=(0,1,0))
    return head


def painted_head(center, radii, sides=14, levels=6):
    head = Piece("Head")
    head.oval(center,radii,"face",sides=sides,levels=levels,caps="skin",face_front=True)
    return head


def flippers(x, y, z, reach, swatch="accent"):
    result = []
    for name, sign in (("FinL", 1), ("FinR", -1)):
        part = Piece(name)
        part.sweep([station(sign*x,y,z,.082,.21),
                    station(sign*(x+reach*.52),y+.06,z-.09,.097,.24),
                    station(sign*(x+reach),y+.28,z-.15,.018,.05)],
                   swatch,sides=7,reference=(0,0,1))
        result.append(part)
    return result


def fish(p, detail):
    width, height = p.get("width", .50), p.get("height", .52)
    body, tail, fins = (Piece(n) for n in ("Body","Tail","Fins"))
    body.sweep([station(0,-.48,0,width*.82,height*.80),
                station(0,-.06,0,width,height),station(0,.41,0,width*.88,height*.90),
                station(0,.78,.02,width*.49,height*.54),station(0,1.02,.04,.13,.16)],
               "main",sides=10)
    head = face((0,-.55,.015),(width*.94,.48,height*.86),detail)
    for sign in (-1,1):
        tail.sweep([station(0,.84,.03,.135,.15),station(0,1.11,sign*.14,.10,.19),
                    station(0,1.34,sign*.30,.067,.20),station(0,1.50,sign*.45,.022,.032)],
                   "accent",sides=6)
    fins.sweep([station(0,.05,height*.76,.095,.27),station(0,.24,height*1.16,.068,.18),
                station(0,.59,height*1.27,.023,.044)],"accent",sides=6)
    return [body,head,tail,fins,*flippers(width*.78,.01,-height*.26,.37)]


def puffer(p, detail):
    body, tail = Piece("Body"), Piece("Tail")
    body.oval((0,.13,.02),(.76,.73,.71),"main",sides=12,levels=6)
    head=face((0,-.44,.04),(.61,.55,.55),detail)
    tail.sweep([station(0,.58,.03,.18,.19),station(0,.91,.07,.12,.31),
                station(0,1.13,.09,.026,.36)],"accent",sides=7)
    return [body,head,tail,*flippers(.57,.05,-.15,.40)]


def shrimp(p, detail):
    body, tail, legs, claws = (Piece(n) for n in ("Body","Tail","Legs","Claws"))
    body.sweep([station(0,-.43,.40,.32,.35),station(0,-.10,.36,.41,.41),
                station(0,.27,.27,.37,.38),station(0,.61,.07,.27,.29),
                station(0,.76,-.18,.18,.20)],"main",sides=10)
    head=face((0,-.58,.39),(.38,.36,.33),detail)
    mane = Piece("Fins")
    for side in (-1,1):
        tail.sweep([station(0,.68,-.15,.17,.17),station(side*.14,.84,-.35,.13,.18),
                    station(side*.34,.83,-.57,.023,.098)],"accent",sides=6)
        for i in range(3):
            legs.sweep([station(side*.19,.38-i*.20,-.07,.049,.055),station(side*.35,.32-i*.20,-.35,.035,.035),
                        station(side*.46,.28-i*.20,-.41,.018,.018)],"accent",sides=4)
        claws.sweep([station(side*.28,-.32,.15,.07,.065),
                     station(side*.45,-.53,-.04,.105,.12),
                     station(side*.53,-.74,.03,.033,.051)],"accent",sides=6)
        mane.sweep([station(side*.17,-.48,.64,.033,.041),station(side*.30,-.61,.88,.023,.024),
                    station(side*.50,-.67,1.01,.013,.013)],"accent",sides=5)
    return [body,head,tail,legs,claws,mane]


def star(p, detail):
    body, tail = Piece("Body"), Piece("Tail")
    for i in range(5):
        a = math.tau * i / 5
        x, z = math.sin(a), math.cos(a)
        body.sweep([station(x*.14,.00,z*.15,.38,.29),
                    station(x*.52,.06,z*.52,.25,.22),
                    station(x*.88,.11,z*.91,.13,.12),
                    station(x*1.06,.09,z*1.10,.025,.048)],"main",
                   sides=5,reference=(0,1,0))
    head=face((0,-.21,.025),(.43,.26,.38),detail,sleepy=p.get("sleepy",False))
    tail.oval((0,.24,-.09),(.27,.20,.25),"accent",sides=7,levels=4)
    return [body,head,tail]


def jelly(p, detail):
    body, tail, legs = (Piece(n) for n in ("Body","Tail","Tentacles"))
    body.sweep([station(0,.08,-.09,.66,.54),station(0,.06,.09,.84,.72),
                station(0,.06,.37,.78,.66),station(0,.06,.64,.52,.48),
                station(0,.06,.76,.13,.13)],"main",sides=12)
    head=face((0,-.48,.195),(.49,.34,.30),detail)
    tail.sweep([station(0,.29,-.07,.12,.12),station(-.08,.40,-.44,.10,.09),
                station(.13,.51,-.80,.067,.055),station(.20,.62,-1.00,.026,.022)],
               "accent",sides=7)
    arms = p.get("arms", 5)
    for index in range(arms):
        t=index/max(arms-1,1)-.5
        x = t*1.18
        legs.sweep([station(x*.85,-.04,-.12,.098,.115),
                    station(x-.07,-.085,-.51,.087,.091),
                    station(x+.11,-.05,-.80-abs(t)*.15,.065,.064),
                    station(x+.07,.07,-1.10+abs(t)*.24,.024,.026)],
                   "accent" if index%2 else "main",sides=5)
    return [body,head,tail,legs]


def octopus(p, detail):
    body, tail, arms = (Piece(n) for n in ("Body","Tail","Tentacles"))
    body.oval((0,.14,.30),(.67,.64,.65),"main",sides=10,levels=5)
    head=face((0,-.38,.23),(.49,.37,.35),detail)
    tail.oval((0,.52,-.12),(.34,.29,.27),"accent",sides=7,levels=4)
    for i in range(8):
        a = (i+.5)*math.tau/8
        x, y = math.cos(a), math.sin(a)
        path = [station(x*.32,y*.30,-.12,.14,.14), station(x*.67,y*.65,-.27,.12,.105),
                station(x*1.02,y*.98,-.37,.075,.076), station(x*1.17,y*1.16,-.21,.021,.025)]
        arms.sweep(path if detail else path[:1]+path[2:], "accent" if i%2 else "main",
                   sides=5 if detail else 4,reference=(0,0,1))
    return [body,head,tail,arms]


def seahorse(p, detail):
    body, tail, fins = (Piece(n) for n in ("Body","Tail","Fins"))
    body.sweep([station(0,.25,-.62,.24,.19),station(0,.10,-.30,.34,.32),
                station(0,.10,.05,.44,.37),station(0,.07,.42,.37,.32),
                station(0,-.13,.76,.29,.27),station(0,-.30,.96,.25,.21)],"main",sides=10)
    head=face((0,-.46,.98),(.42,.47,.36),detail,eye_scale=.93,compact=not detail)
    head.sweep([station(0,-.63,.91,.19,.14),station(0,-.91,.80,.125,.097),
                station(0,-1.00,.80,.095,.066)],"accent",sides=7 if detail else 6)
    tail.sweep([station(0,.22,-.49,.19,.16),station(.11,.31,-.82,.19,.19),
                station(.39,.41,-.99,.15,.17),station(.69,.50,-.87,.125,.13),
                station(.79,.56,-.61,.097,.10),station(.64,.57,-.46,.075,.074),
                station(.46,.59,-.53,.034,.032)],"main",sides=8 if detail else 7,steps=2)
    fins.sweep([station(0,.32,.13,.105,.39),station(0,.56,.29,.067,.36),
                station(0,.76,.55,.020,.11)],"accent",sides=8 if detail else 7)
    return [body,head,tail,fins,*flippers(.28,-.01,.23,.35)]


def turtle(p, detail):
    body, shell, tail = (Piece(n) for n in ("Body","Shell","Tail"))
    body.oval((0,.16,-.13),(.65,.77,.27),"main",sides=10,levels=5)
    shell.sweep([station(0,.13,-.10,.62,.76),station(0,.13,.10,.75,.84),
                 station(0,.14,.34,.65,.74),station(0,.17,.57,.39,.49),
                 station(0,.19,.66,.09,.11)],"accent",sides=12)
    head=face((0,-.72,.04),(.425,.45,.39),detail)
    tail.sweep([station(0,.73,-.12,.15,.14),station(0,.97,-.095,.11,.095),
                station(0,1.14,-.06,.034,.035)],"main",sides=7)
    legs=Piece("Legs")
    for s in (-1,1):
        legs.sweep([station(s*.43,.49,-.10,.16,.11),station(s*.69,.66,-.19,.23,.085),
                    station(s*.81,.87,-.13,.045,.034)],"main",sides=6,reference=(0,1,0))
    return [body,head,tail,shell,legs,*flippers(.49,-.25,-.13,.58,"main")]


def crab(p, detail):
    body, tail, claws, legs = (Piece(n) for n in ("Body","Tail","Claws","Legs"))
    body.oval((0,.13,.01),(.67,.57,.39),"main",sides=10,levels=5)
    head=face((0,-.30,.20),(.46,.36,.32),detail)
    tail.oval((0,.543,-.09),(.28,.16,.16),"accent",sides=6,levels=3)
    for side in (-1,1):
        for i in range(3):
            y=.43-i*.24
            legs.sweep([station(side*.43,y,-.08,.078,.080),station(side*.81,y+.12,-.24,.063,.074),
                        station(side*1.13,y+.08,-.46,.021,.022)],"main",sides=5 if detail else 4)
        for finger in (-1,1):
            claws.sweep([station(side*.60,-.38,-.13,.13,.13),
                         station(side*.84,-.58,.02,.14,.13),
                         station(side*(.94+finger*.11),-.73,.19,.037,.03)],
                        "accent",sides=6)
    return [body,head,tail,claws,legs]


FAMILIES = {"fish": fish, "puffer": puffer, "shrimp": shrimp, "star": star, "jelly": jelly,
            "octopus": octopus, "seahorse": seahorse, "turtle": turtle, "crab": crab}


def recipe(spec):
    family = FAMILIES[spec["family"]]
    rarity = spec["rarity"]
    if rarity not in {"Common", "Uncommon"}:
        raise ValueError(f"Unsupported small creature rarity: {rarity}")
    if "finish" in spec:
        from polished_creatures import BUILDERS
        palette = {name: (value[0], value[1]) for name,value in spec["finish"].items()}
        return lambda: BUILDERS[spec["family"]](spec), palette
    palette = {k: (v, spec.get("pattern", "plain") if k == "main" else "plain")
               for k, v in spec["colors"].items()}
    palette.update({"ink": ("15203B/252E44", "plain"), "cream": ("EFF5EE/FFFFFF", "plain")})
    return lambda: family(spec, rarity == "Uncommon"), palette
