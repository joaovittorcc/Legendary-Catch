"""Sculpt and export the revised C145–C156 rigid Epic creature meshes."""

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

PROJECT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT / "tools" / "blender"))
from check_creature import bounds
from creature_mesh import Piece, atlas
import preview_creature


def xyz(x, y, z):
    return (x, -z, y)


def tube(piece, stations, paint, sides=10, ref=(1, 0, 0), steps=2):
    piece.sweep([(xyz(x, y, z), w, h) for x, y, z, w, h in stations],
                paint, sides=sides, reference=xyz(*ref), steps=steps)


def oval(piece, center, radii, paint, sides=14, levels=7):
    x, y, z = radii
    piece.oval(xyz(*center), (x, z, y), paint, sides=sides, levels=levels)


def gem(piece, a, b, width, paint):
    piece.gem(xyz(*a), xyz(*b), width, paint)


def eyes(piece, x, y, z, size, paint="iris"):
    for side in (-1, 1):
        sx = side * x
        oval(piece, (sx, y, z), (size * 1.12, size * 1.32, size * .56), "dark", 10, 5)
        oval(piece, (sx, y + .006, z + size * .31), (size * .96, size * 1.11, size * .41), paint, 10, 5)
        oval(piece, (sx + .014, y + .012, z + size * .60), (size * .63, size * .77, size * .24), "dark", 8, 4)
        oval(piece, (sx - size * .28, y + size * .40, z + size * .77), (size * .28, size * .29, size * .14), "white", 7, 4)


def mouth(piece, y, z, width, curve=.047):
    tube(piece, [(-width, y + curve, z - .027, .009, .009),
                 (-width * .52, y, z, .014, .010),
                 (0, y - curve * .24, z + .013, .015, .010),
                 (width * .52, y, z, .014, .010),
                 (width, y + curve, z - .027, .009, .009)],
         "dark", 5, (0, 1, 0))


def wings(attach, reach, rise, swept, chord, paint="fin", names=("FinL", "FinR")):
    result = []
    x, y, z = attach
    for sign, name in zip((1, -1), names, strict=True):
        piece = Piece(name)
        tube(piece, [(sign * x, y, z, chord * .39, .076),
                     (sign * (x + reach * .27), y + rise * .15, z - swept * .13, chord * .51, .085),
                     (sign * (x + reach * .60), y + rise * .54, z - swept * .54, chord * .42, .056),
                     (sign * (x + reach * .86), y + rise * .92, z - swept * .85, chord * .23, .027),
                     (sign * (x + reach), y + rise, z - swept, .013, .008)],
             paint, 10, (0, 0, 1))
        result.append(piece)
    return result


def combine(name, pieces):
    result = Piece(name)
    for piece in pieces:
        start = len(result.vertices)
        result.vertices.extend(piece.vertices)
        result.faces.extend(tuple(i + start for i in face) for face in piece.faces)
        result.paint.extend(piece.paint)
    return result


def tail_fan(stem, span, rise, length, paint="fin"):
    tail = Piece("Tail")
    x, y, z = stem
    tube(tail, [(x, y, z + .25, .23, .21), (x, y, z, .17, .14),
                (x, y + .018, z - length * .43, .095, .105)], "skin", 12)
    for sign in (-1, 1):
        tube(tail, [(x, y, z - length * .23, length * .23, .084),
                    (x + sign * span * .43, y + rise * .45, z - length * .52, length * .37, .085),
                    (x + sign * span * .78, y + rise * .81, z - length * .83, length * .23, .047),
                    (x + sign * span, y + rise, z - length, .012, .012)],
             paint, 9, (0, 0, 1))
    return tail


def palettes(skin, fin, light, iris, magic, skin_pattern="none", fin_pattern="fin"):
    return {
        "skin": (skin, skin_pattern), "fin": (fin, fin_pattern),
        "light": (light, "none"), "iris": (iris, "none"), "magic": (magic, "vein"),
        "dark": ("101020/27243e", "none"), "white": ("bce0f5/fff7ec", "none"),
        "gold": ("7c391f/f29b42/fff0a0", "none"),
        "rose": ("82365e/de5485/ffa6bc", "none"), "leaf": ("0b564c/2d9d75/87d77c", "fin"),
    }


def manatee():
    body, head, tail = (Piece(n) for n in ("Body", "Head", "Tail"))
    tube(body, [(0, .01, .68, .40, .40), (0, -.035, .40, .61, .52),
                (0, -.01, -.04, .66, .55), (0, .02, -.49, .52, .47),
                (0, -.025, -.85, .35, .29), (0, -.11, -1.09, .193, .152)], "skin", 20)
    tube(body, [(0, -.30, .49, .32, .16), (0, -.338, .11, .46, .192),
                (0, -.315, -.34, .42, .175), (0, -.22, -.70, .24, .125)], "light", 14)
    tube(head, [(0, .02, .46, .435, .404), (0, .03, .69, .507, .418),
                (0, .03, .90, .445, .352), (0, -.016, 1.13, .305, .248)], "skin", 18)
    for sign in (-1, 1):
        oval(head, (sign * .166, -.13, 1.116), (.266, .178, .218), "light")
        oval(head, (sign * .107, -.043, 1.295), (.067, .041, .035), "dark", 9, 5)
        for i in range(3):
            oval(head, (sign * (.21 + i * .055), -.101 - i * .037, 1.29 - i * .021),
                 (.023, .023, .011), "gold", 7, 4)
    mouth(head, -.246, 1.303, .19)
    tube(tail, [(0, -.11, -.93, .21, .14), (0, -.125, -1.12, .25, .117),
                (0, -.12, -1.34, .45, .105), (0, -.086, -1.57, .45, .087),
                (0, -.057, -1.74, .285, .047), (0, -.049, -1.80, .071, .016)], "fin", 16)
    fins = wings((.48, -.22, .26), .57, -.19, .35, .43)
    keel = combine("Fins", wings((.32, -.27, -.60), .25, -.075, .23, .285))
    bloom, gaze, leaves = (Piece("Extra") for _ in range(3))
    eyes(gaze, .295, .128, 1.048, .092)
    for x, y, z, span, petals in ((-.27, .43, .08, .205, 6), (.22, .43, -.29, .155, 5), (-.06, .33, -.66, .125, 5)):
        oval(bloom, (x, y + .07, z), (span * .31, .070, span * .31), "gold", 9, 5)
        for j in range(petals):
            a = math.tau * j / petals
            dx, dz = math.cos(a), math.sin(a)
            tube(bloom, [(x + dx * span * .14, y + .016, z + dz * span * .14, .033, .022),
                         (x + dx * span * .58, y + .065, z + dz * span * .58, span * .31, .037),
                         (x + dx * span, y + .103, z + dz * span, span * .13, .013)],
                 "magic", 7, (0, 1, 0))
        for dx, dz in ((-1, .5), (.75, -.7)):
            tube(leaves, [(x, y - .03, z, .029, .016), (x + dx * .16, y + .012, z + dz * .17, .066, .028),
                          (x + dx * .25, y + .02, z + dz * .28, .008, .008)],
                 "leaf", 8, (0, 1, 0))
    p = palettes("203655/456c98/90aabe", "355071/5995a9/a6dde0", "758aa6/c2d7dc/f7dfd2",
                 "41283a/b08770", "c74989/f67bac/ffd3ae", "none")
    return [body, head, tail, *fins, keel, bloom, gaze, leaves], p


def spine(name, stations, color="skin", sides=16, ref=(1, 0, 0)):
    part = Piece(name)
    tube(part, stations, color, sides, ref)
    return part


def mirror(sign, stations):
    return [(sign * x, y, z, w, h) for x, y, z, w, h in stations]


def swordfish():
    body = spine("Body", [(0, .02, .59, .25, .26), (0, .01, .29, .36, .38),
                         (0, .01, -.12, .33, .34), (0, -.017, -.51, .23, .24),
                         (0, -.036, -.78, .123, .143)], sides=18)
    tube(body, [(0, -.182, .54, .18, .09), (0, -.233, .22, .253, .15),
                (0, -.224, -.19, .211, .119), (0, -.171, -.61, .117, .06)], "light", 14)
    head = spine("Head", [(0, .018, .43, .283, .305), (0, -.005, .65, .265, .235),
                         (0, -.043, .85, .195, .159), (0, -.065, .95, .102, .076)])
    mouth(head, -.128, .892, .134, .021)
    tail = Piece("Tail")
    for sign in (-1, 1):
        tube(tail, [(0, -.02, -.68, .14, .132), (0, -.01, -.94, .106, .12),
                    (0, .23 * sign, -1.122, .105, .171),
                    (0, .46 * sign, -1.31, .073, .099),
                    (0, .57 * sign, -1.48, .014, .024)], "fin", 12)
    sail = spine("Fins", [(0, .26, .23, .068, .30), (0, .44, .08, .058, .43),
                          (0, .64, -.13, .046, .43), (0, .61, -.39, .025, .27),
                          (0, .47, -.55, .008, .095)], "fin", 12, (1, 0, 0))
    bill, ember, gaze = (Piece("Extra") for _ in range(3))
    tube(bill, [(0, -.047, .79, .134, .063), (0, -.045, 1.07, .109, .045),
                (.006, -.024, 1.39, .064, .029), (.016, .02, 1.72, .008, .011)], "magic", 10)
    for x in (-.027, .027):
        tube(ember, [(x, .425, .164, .027, .063), (x, .61, .012, .025, .109),
                     (x, .686, -.277, .013, .091), (x, .571, -.55, .008, .024)], "magic", 7)
    eyes(gaze, .174, .07, .748, .071, "gold")
    p = palettes("53132c/a72d3c/f46a52", "40172c/bf3c47/fd9249", "af3e39/e7914d/ffe0a4",
                 "6d251d/eda44b", "af301e/ff852e/ffde69", "scale", "vein")
    return [body, head, tail, sail, *wings((.236, -.13, .175), .515, -.12, .58, .24), bill, ember, gaze], p


def crocodile():
    body = spine("Body", [(0, -.012, .63, .31, .25), (0, .013, .37, .453, .299),
                         (0, -.019, -.13, .439, .29), (0, -.043, -.55, .341, .224),
                         (0, -.076, -.77, .212, .169)], sides=20)
    tube(body, [(0, -.186, .58, .28, .096), (0, -.218, .24, .374, .121),
                (0, -.228, -.228, .322, .105), (0, -.192, -.62, .19, .073)], "light", 14)
    head = spine("Head", [(0, .053, .447, .32, .243), (0, .092, .675, .363, .235),
                         (0, .037, .865, .344, .189), (0, .01, 1.11, .317, .148),
                         (0, .008, 1.37, .264, .116), (0, .052, 1.467, .155, .075)], sides=20)
    tube(head, [(0, -.106, .7, .302, .101), (0, -.13, .93, .344, .091),
                (0, -.12, 1.23, .292, .072), (0, -.086, 1.426, .161, .041)], "light", 16)
    tail = spine("Tail", [(0, -.04, -.53, .32, .211), (.031, -.075, -.824, .267, .201),
                          (.16, -.102, -1.07, .203, .149), (.29, -.11, -1.32, .124, .101),
                          (.35, -.074, -1.52, .049, .043), (.32, -.02, -1.65, .010, .012)])
    legs, claws, plate = (Piece(n) for n in ("Legs", "Claws", "Shell"))
    gaze, teeth, gold = (Piece("Extra") for _ in range(3))
    for sign in (-1, 1):
        for z in (.415, -.465):
            tube(legs, mirror(sign, [(.314, -.062, z, .16, .123), (.503, -.15, z + .03, .12, .086),
                                    (.583, -.269, z + .124, .091, .07), (.675, -.268, z + .179, .065, .048)]),
                 "skin", 10, (0, 0, 1))
            for k in range(3):
                gem(claws, (sign * (.597 + k * .052), -.267, z + .167),
                    (sign * (.639 + k * .059), -.276, z + .253), .023, "light")
        for i in range(5):
            z = .47 - i * .27
            gem(plate, (sign * .146, .245 - i * .008, z - .062),
                (sign * .17, .394 - i * .018, z - .17), .133 - .011 * i, "fin")
            tube(gold, [(sign * .16, .287-i*.011, z+.001, .013, .012),
                         (sign * .226, .283-i*.01, z-.10, .016, .012),
                         (sign * .161, .281-i*.012, z-.172, .009, .009)], "gold", 6, steps=1)
        for i in range(5):
            z = .91 + i * .104
            x = (.338-i*.016) * sign
            gem(teeth, (x,-.072,z), (x,-.145 + i*.005,z+.017), .028 - i*.003, "white")
        oval(head, (sign * .235, .232, .676), (.15,.113,.151), "fin", 12, 6)
        oval(head, (sign * .135,.103,1.405),(.039,.021,.04),"dark",8,4)
    eyes(gaze,.222,.229,.797,.075,"gold")
    return [body, head, tail, legs, claws, plate, gaze, teeth, gold], palettes(
        "155044/208269/6bc38b","143f48/247265/6edeb1","8a8753/d8cd88/f7e7a9",
        "ae5722/f3bd4c","50a76a/b2ea82","scale","armor")


def claw_pair(claws, sign, base, z, paint="fin"):
    tube(claws, mirror(sign, [(base, -.03, z-.31, .143,.123),
                              (base+.27,.003,z-.095,.199,.133),
                              (base+.35,.018,z+.138,.204,.126),
                              (base+.45,.042,z+.25,.092,.087),
                              (base+.38,.037,z+.372,.067,.062), (base+.25,.015,z+.434,.015,.014)]),
         paint, 12, (1,0,0))
    tube(claws, mirror(sign, [(base+.22,-.042,z+.094,.13,.088),
                              (base+.145,-.052,z+.249,.127,.074),
                              (base+.189,-.034,z+.40,.054,.047),
                              (base+.254,-.027,z+.447,.011,.011)]),
         "light", 10, (1,0,0))


def crab_legs(legs, count, spacing):
    for sign in (-1,1):
        for j in range(count):
            z=.41 - j*spacing
            tube(legs, mirror(sign, [(.56,-.097,z,.11,.106),
                                     (.84,-.142,z+.11-j*.07,.099,.085),
                                     (1.04,-.29,z+.245-j*.109,.082,.074),
                                     (1.21,-.403,z+.22-j*.13,.044,.042),
                                     (1.25,-.419,z+.17-j*.14,.014,.014)]),
                 "skin" if j%2 else "fin", 8, (0,0,1), steps=1)


def comet_crab():
    body, head, legs, claws, shell, tail = (Piece(n) for n in ("Body","Head","Legs","Claws","Shell","Tail"))
    tube(body, [(0,-.198,-.015,.63,.51),(0,-.074,-.075,.795,.619),(0,.172,-.13,.717,.589),
                (-.042,.411,-.202,.558,.453),(-.101,.519,-.267,.34,.29)],"skin",20)
    for sign in (-1,1):
        tube(head, mirror(sign,[(.205,.05,.45,.09,.08),(.259,.25,.56,.08,.077),
                                (.29,.368,.65,.095,.091)]), "fin",9,steps=1)
        claw_pair(claws,sign,.565,.665)
    crab_legs(legs,4,.292)
    for i,(x,y,z) in enumerate(((-.28,.449,-.21),(.234,.382,.18),(.17,.46,-.421),(-.46,.248,.216))):
        tube(shell, [(x,y-.024,z,.15,.13),(x,y+.015,z,.21,.185),(x+.023,y+.087,z+.013,.219,.194),
                     (x+.027,y+.126,z+.012,.145,.12),(x+.026,y+.10,z+.012,.095,.08)],
             "fin" if i%2 else "light", 10,steps=1)
    tube(tail,[(0,.04,-.61,.22,.169),(-.06,.096,-.83,.224,.168),
               (-.13,.167,-1.02,.147,.12),(-.21,.263,-1.22,.066,.069)],"rose",12)
    flame,gaze,star=(Piece("Extra") for _ in range(3))
    for offset in (-.11,0,.12):
        tube(flame,[(-.15+offset,.14,-.932,.12,.104),(-.207+offset,.233,-1.075,.117,.103),
                    (-.279+offset,.384,-1.289,.061,.063),(-.42+offset,.552,-1.492,.01,.009)],"magic",9)
    eyes(gaze,.29,.377,.681,.076)
    for xyz_center in ((.40,.367,-.261),(-.464,.382,.04),(-.125,.558,-.29),(.12,.465,.095)):
        x,y,z=xyz_center
        gem(star,(x,y-.026,z),(x+.029,y+.082,z-.042),.048,"gold")
    return [body,head,legs,claws,shell,tail,flame,gaze,star],palettes(
        "212945/4e5870/8793b0","223757/467ba4/82c9d4","567490/a3b9ca/d9e3df",
        "313a53/81b3c4","aa423f/f1813c/ffda84","star","vein")


def seahorse():
    body=spine("Body",[(0,-.71,-.12,.167,.169),(0,-.47,-.043,.266,.319),
                       (0,-.113,-.003,.344,.367),(0,.23,.046,.31,.315),
                       (0,.552,.145,.233,.23),(0,.752,.235,.237,.235)],sides=18)
    tube(body,[(0,-.554,.148,.154,.073),(0,-.275,.282,.243,.11),(0,.053,.327,.248,.124),
               (0,.363,.32,.197,.101),(0,.567,.328,.131,.06)],"light",14)
    head=spine("Head",[(0,.680,.18,.225,.23),(0,.791,.385,.302,.254),
                       (0,.751,.59,.235,.159),(0,.691,.781,.158,.106),
                       (0,.686,.885,.111,.076)],sides=18)
    mouth(head,.647,.941,.10,.02)
    tail=spine("Tail",[(0,-.642,-.14,.19,.158),(.066,-.947,-.225,.195,.153),
                       (.259,-1.19,-.268,.161,.132),(.556,-1.31,-.269,.132,.119),
                       (.777,-1.15,-.289,.105,.097),(.739,-.925,-.298,.077,.069),
                       (.552,-.837,-.316,.05,.049),(.428,-.96,-.33,.024,.024)],"skin",12)
    wingset=combine("Wings",wings((.192,.241,-.188),.67,.374,.411,.44))
    small=combine("Fins",wings((.234,.04,.14),.369,-.04,.25,.211))
    eyeset, flame, horns, whiskers=(Piece("Extra") for _ in range(4))
    eyes(eyeset,.197,.823,.64,.084,"gold")
    for sign in (-1,1):
        tube(horns,mirror(sign,[(.165,.913,.28,.104,.086),(.225,1.094,.241,.069,.065),
                               (.278,1.239,.161,.042,.037),(.287,1.311,.087,.009,.010)]),"gold",9)
        tube(whiskers,mirror(sign,[(.156,.709,.755,.027,.024),(.274,.675,.789,.023,.018),
                                  (.386,.605,.742,.016,.013),(.424,.621,.659,.007,.006)]),"light",7)
    tube(flame,[(.465,-.94,-.338,.051,.048),(.416,-1.044,-.364,.086,.068),
                (.366,-1.03,-.417,.091,.067),(.323,-.89,-.493,.04,.031),(.307,-.798,-.52,.009,.008)],"magic",11)
    return [body,head,tail,wingset,small,eyeset,flame,horns,whiskers],palettes(
        "114b4e/247e70/6abb87","317058/c69e4f/f5ad83","c1a361/e8ca90/fff1bd",
        "6e3620/cb9e41","96344d/f0717d/ffd890","scale","vein")


def ice_seal():
    body=spine("Body",[(0,.059,.48,.382,.344),(0,.01,.22,.551,.487),
                       (0,-.031,-.24,.537,.438),(0,-.118,-.71,.389,.31),
                       (0,-.147,-1.12,.226,.181)],sides=20)
    tube(body,[(0,-.24,.409,.296,.139),(0,-.327,.02,.433,.177),
               (0,-.346,-.421,.374,.132),(0,-.29,-.766,.217,.099)],"light",14)
    head=spine("Head",[(0,.134,.423,.377,.364),(0,.198,.645,.443,.406),
                       (0,.147,.894,.386,.352),(0,.087,1.101,.264,.209)],sides=18)
    oval(head,(0,.011,1.154),(.295,.18,.19),"light")
    oval(head,(0,.090,1.301),(.095,.061,.043),"dark",10,5)
    mouth(head,-.061,1.276,.147)
    tail=tail_fan((0,-.159,-1.02),.56,.17,.63,"fin")
    fins=wings((.376,-.16,.26),.562,-.18,.49,.35)
    shell,runes,whiskers,gaze=(Piece(n) for n in ("Shell","Extra","Extra","Extra"))
    for i in range(5):
        z=.268-i*.223
        for sign in (-1,1):
            gem(shell,(sign*(.203-.017*i),.398-.034*i,z),
                (sign*(.225-.021*i),.663-.075*i,z-.14),.107-.01*i,"fin")
            tube(runes,[(sign*.397,.25-i*.022,z,.019,.016),
                       (sign*.431,.204-i*.027,z-.072,.020,.017),
                       (sign*.449,.173-i*.027,z+.034,.012,.011)],"magic",6,steps=1)
    for sign in (-1,1):
        for i in range(3):
            tube(whiskers,mirror(sign,[(.164,-.037-i*.045,1.268,.013,.011),
                                      (.292,-.028-i*.046,1.298,.019,.015),
                                      (.447,-.006-i*.049,1.236-.036*i,.007,.006)]),"white",7)
    eyes(gaze,.259,.269,1.008,.105)
    return [body,head,tail,*fins,shell,runes,whiskers,gaze],palettes(
        "44649a/79addc/b4ddf1","42679f/87cbea/d3fbff","9db6df/d4e8f1/fffaf0",
        "254d7c/78cbed","379cda/74d9fe/ebf9ff","none","vein")


def thunder_turtle():
    body=spine("Body",[(0,-.107,.69,.406,.169),(0,-.166,.44,.64,.204),
                       (0,-.169,-.095,.727,.221),(0,-.185,-.495,.524,.164),
                       (0,-.136,-.78,.343,.132)],"light",20)
    head=spine("Head",[(0,-.057,.469,.241,.187),(0,-.002,.682,.251,.218),
                       (0,.067,.881,.335,.259),(0,.038,1.106,.351,.236),
                       (0,-.013,1.29,.241,.151)],sides=18)
    mouth(head,-.051,1.292,.178,.046)
    tail=spine("Tail",[(0,-.128,-.566,.206,.122),(.04,-.16,-.797,.109,.114),
                       (.061,-.151,-1.036,.051,.046),(.019,-.106,-1.187,.01,.01)])
    front=wings((.45,-.118,.458),1.02,-.08,.69,.45)
    legs=combine("Legs",wings((.426,-.153,-.448),.643,-.10,.49,.33))
    shell,rays,gaze=(Piece(n) for n in ("Shell","Extra","Extra"))
    tube(shell,[(0,.004,-.049,.753,.895),(0,.247,-.045,.703,.822),
                (0,.478,-.059,.585,.706),(0,.648,-.071,.405,.504),
                (0,.738,-.087,.206,.259),(0,.776,-.097,.077,.09)],"gold",24)
    for angle in [i*math.tau/9 for i in range(9)]:
        x,z=math.sin(angle),math.cos(angle)
        tube(shell,[(x*.30,.538,z*.37,.103,.034),(x*.447,.425,z*.569,.13,.052),
                    (x*.608,.222,z*.718,.121,.050),(x*.69,.087,z*.785,.070,.030)],"light",8)
    for sign in (-1,1):
        tube(rays,[(sign*.103,.762,.227,.028,.019),(sign*.187,.754,.067,.028,.018),
                   (sign*.17,.757,-.067,.029,.019),(sign*.321,.697,-.105,.024,.018),
                   (sign*.337,.61,-.301,.025,.018),(sign*.471,.49,-.322,.016,.013)],"magic",7,steps=1)
    eyes(gaze,.255,.152,1.102,.087,"dark")
    return [body,head,tail,*front,legs,shell,rays,gaze],palettes(
        "106750/39a17d/a2dda1","146264/37a6a8/a2e6d5","83632c/ddaf56/f7dfab",
        "125058/b3e0ac","578afb/c5eaff/fff6aa","scale","fin")


def emperor():
    body=spine("Body",[(0,-1.026,-.079,.39,.389),(0,-.795,-.026,.558,.458),
                       (0,-.382,-.04,.594,.478),(0,.053,-.04,.507,.407),
                       (0,.404,-.039,.385,.32),(0,.599,-.032,.327,.309)],sides=22,ref=(1,0,0))
    oval(body,(0,-.251,.325),(.445,.732,.193),"light",20,11)
    head=Piece("Head")
    oval(head,(0,.664,.008),(.474,.406,.401),"skin",20,10)
    oval(head,(0,.571,.303),(.369,.278,.16),"light",18,8)
    eyes(head,.220,.694,.365,.088)
    flippers=[]
    for sign,name in ((1,"FinL"),(-1,"FinR")):
        part=spine(name,mirror(sign,[(.396,.276,-.05,.149,.192),
                                     (.519,.105,-.157,.153,.238),
                                     (.629,-.206,-.184,.143,.205),
                                     (.704,-.496,-.254,.089,.128),
                                     (.713,-.619,-.378,.015,.021)]),"fin",12,(0,0,1))
        flippers.append(part)
    toes=Piece("Legs")
    for sign in (-1,1):
        tube(toes,mirror(sign,[(.194,-.934,.025,.128,.115),(.234,-1.077,.16,.144,.072),
                               (.247,-1.098,.306,.184,.071),(.25,-1.092,.455,.058,.026)]),"gold",12)
    tail=spine("Tail",[(0,-.707,-.352,.259,.172),(0,-.732,-.484,.222,.137),
                       (0,-.71,-.711,.123,.07),(0,-.646,-.859,.01,.02)],"skin",12)
    crown,bill,breast,shoulders=(Piece("Extra") for _ in range(4))
    for i in range(5):
        x=(i-2)*.112
        gem(crown,(x,.985,.12-abs(x)*.22),(x*1.40,1.31-abs(x)*.70,.102-abs(x)*.27),.092,"magic")
    tube(bill,[(0,.531,.384,.136,.091),(0,.532,.488,.129,.069),(0,.497,.609,.059,.037),
               (0,.465,.648,.012,.011)],"gold",12)
    oval(breast,(0,-.222,.439),(.325,.516,.105),"white",16,9)
    for sign in (-1,1):
        for j in range(3):
            gem(shoulders,(sign*(.397+j*.034),.238-j*.092,-.09+j*.014),
                (sign*(.551+j*.038),.457-j*.087,-.11-j*.051),.08-j*.009,"fin")
    return [body,head,*flippers,toes,tail,crown,bill,breast,shoulders],palettes(
        "192545/3d548d/679ac5","203765/4d87b6/8bd5ef","9fc2d5/dcf0ed/fff7e0",
        "23365a/7aa6bc","5da3db/98ecff/e4f9ff","none","vein")


def solar_manta():
    body=spine("Body",[(0,.02,.55,.343,.114),(0,.05,.32,.542,.176),
                       (0,.067,.032,.53,.188),(0,.046,-.301,.373,.139),
                       (0,.022,-.542,.197,.089)],sides=22)
    tube(body,[(0,-.087,.495,.311,.053),(0,-.084,.266,.455,.099),
               (0,-.064,-.087,.405,.102),(0,-.063,-.416,.235,.055)],"light",16)
    head=spine("Head",[(0,.007,.391,.341,.118),(0,.024,.63,.314,.126),
                       (0,.026,.808,.269,.098),(0,.009,.907,.187,.061)])
    for sign in (-1,1):
        tube(head,mirror(sign,[(.179,.033,.661,.098,.079),(.267,.021,.827,.08,.069),
                               (.338,.027,.95,.061,.052),(.383,.079,.988,.017,.016)]),"gold",10)
    tail=spine("Tail",[(0,.02,-.398,.106,.088),(.034,.052,-.699,.078,.061),
                       (.121,.069,-.991,.052,.048),(.245,.124,-1.26,.034,.034),
                       (.373,.194,-1.487,.024,.023),(.53,.247,-1.73,.009,.009)],"skin",10)
    fins=wings((.373,.037,.305),1.37,.435,1.04,.85)
    frill=combine("Fins",wings((.33,-.045,-.239),.782,-.049,.395,.29))
    spots,thread,gaze=(Piece("Extra") for _ in range(3))
    for sign in (-1,1):
        for i in range(4):
            x=sign*(.404 + i*.162)
            oval(spots,(x,.185+i*.031,.245-i*.115),(.073-i*.01,.018,.105-i*.013),"magic",8,4)
    tube(thread,[(0,.071,-.499,.056,.027),(.067,.112,-.77,.044,.025),
                 (.156,.132,-1.08,.031,.027),(.321,.206,-1.385,.023,.018),
                 (.53,.248,-1.733,.009,.009)],"magic",8)
    eyes(gaze,.236,.099,.795,.066,"gold")
    return [body,head,tail,*fins,frill,spots,thread,gaze],palettes(
        "a04926/d99436/ffd571","9a3827/d67c31/ffcf57","b58042/eeb869/fff6b8",
        "673819/c6883f","e69a54/ffdd80/fffbda","star","vein")


def mamba():
    path=[(-.18,.10,.89,.224,.222),(-.32,.078,.624,.275,.255),
          (-.321,.02,.26,.259,.225),(-.07,-.022,-.10,.236,.197),
          (.232,.015,-.431,.211,.194),(.254,-.002,-.733,.174,.15),
          (.119,-.053,-.995,.135,.116)]
    body=spine("Body",path,sides=22)
    tube(body,[(-.31,-.139,.61,.224,.058),(-.30,-.193,.251,.219,.068),
               (-.056,-.21,-.105,.193,.066),(.222,-.157,-.462,.161,.049),
               (.22,-.117,-.743,.121,.042)],"light",16)
    head=spine("Head",[(-.215,.10,.743,.234,.232),(-.16,.151,.97,.351,.225),
                       (-.094,.113,1.167,.322,.159),(-.06,.081,1.358,.235,.104),
                       (-.055,.089,1.453,.137,.067)],sides=20)
    tube(head,[(-.18,-.006,.839,.219,.095),(-.113,-.028,1.088,.287,.105),
               (-.060,-.027,1.337,.211,.058)],"light",16)
    tail=spine("Tail",[(.245,-.01,-.719,.179,.151),(.114,-.052,-.989,.128,.114),
                       (-.128,-.049,-1.221,.092,.087),(-.325,-.052,-1.418,.069,.061),
                       (-.401,-.01,-1.63,.026,.033)],sides=16)
    paddle=spine("Fins",[(-.245,-.034,-1.318,.072,.071),(-.364,-.019,-1.452,.066,.17),
                        (-.443,.018,-1.566,.048,.235),(-.491,.073,-1.701,.015,.065)],"fin",13)
    shell,stripes,gaze,tongue=(Piece(n) for n in ("Shell","Extra","Extra","Extra"))
    for i,(x,y,z,w,h) in enumerate(path[:-1]):
        gem(shell,(x,y+h*.86,z+.021),(x-.034,y+h+.12,z-.11),.075+.008*(i%2),"fin")
        for sign in (-1,1):
            tube(stripes,[(x+sign*w*.56,y+h*.70,z+.071,.022,.022),
                          (x+sign*w*.89,y+h*.41,z+.014,.024,.022),
                          (x+sign*w*.99,y+h*.022,z+.045,.013,.015)],"magic",7,steps=1)
    for sign in (-1,1):
        oval(gaze,(-.135+sign*.227,.236,1.176),(.077,.098,.059),"gold",11,6)
        oval(head,(-.135+sign*.227,.238,1.218),(.031,.068,.031),"dark",8,5)
        oval(head,(-.153+sign*.227,.28,1.235),(.018,.023,.011),"white",6,4)
        tube(tongue,[(-.052,.019,1.345,.057,.017),(-.035,.017,1.474,.049,.019),
                     (-.025+sign*.024,.019,1.586,.021,.009),
                     (-.024+sign*.065,.041,1.641,.008,.006)],"rose",8)
    return [body,head,tail,paddle,shell,stripes,gaze,tongue],palettes(
        "0f1d33/24434c/508057","16203d/365d58/74a66a","235544/71a36a/bbdc87",
        "51411c/bbc765","2ea163/75e884/d0fc88","scale","vein")


def samurai_crab():
    body,head,legs,claws,shell=(Piece(n) for n in ("Body","Head","Legs","Claws","Shell"))
    tube(body,[(0,-.179,-.026,.67,.571),(0,-.04,-.053,.864,.648),
               (0,.149,-.096,.823,.592),(0,.334,-.141,.727,.507),
               (0,.485,-.187,.492,.292)],"skin",22)
    tube(head,[(0,.123,.376,.491,.22),(0,.138,.561,.493,.219),
               (0,.149,.744,.392,.142)],"fin",18)
    eyes(head,.239,.252,.777,.084,"gold")
    mouth(head,.119,.759,.146,.031)
    crab_legs(legs,3,.361)
    for sign in (-1,1):
        claw_pair(claws,sign,.60,.606)
        for i in range(3):
            x=sign*(.558+i*.106)
            tube(shell,[(x,.265-i*.031,.388-i*.087,.173,.127),
                        (x+sign*.075,.335-i*.03,.226-i*.092,.178,.14),
                        (x+sign*.131,.297-i*.034,.007-i*.083,.097,.107)],"rose",11)
            tube(shell,[(x-sign*.036,.333-i*.03,.452-i*.088,.023,.032),
                        (x+sign*.085,.433-i*.039,.23-i*.096,.029,.028),
                        (x+sign*.139,.361-i*.035,.012-i*.086,.022,.024)],"gold",7)
    blade,helmet,banner,scabbard=(Piece("Extra") for _ in range(4))
    tube(blade,[(1.195,.151,.739,.099,.077),(1.233,.165,.916,.08,.05),
                (1.224,.194,1.108,.061,.038),(1.187,.258,1.395,.046,.029),
                (1.121,.344,1.613,.007,.005)],"magic",8)
    tube(helmet,[(0,.295,.455,.478,.27),(0,.44,.441,.472,.27),
                (0,.588,.435,.369,.216),(0,.655,.414,.231,.169)],"skin",18)
    for sign in (-1,1):
        tube(helmet,mirror(sign,[(.092,.498,.653,.074,.072),(.238,.59,.633,.073,.059),
                                (.379,.727,.571,.052,.053),(.492,.839,.504,.009,.01)]),"gold",9)
        tube(banner,mirror(sign,[(0,-.014,.559,.062,.044),(.299,-.022,.561,.055,.04),
                                (.559,-.031,.485,.055,.04),(.71,-.051,.406,.04,.028)]),"rose",8)
    tube(scabbard,[(-.479,.041,-.15,.108,.113),(-.595,.018,-.482,.106,.105),
                   (-.811,.014,-.811,.087,.087),(-.971,.033,-.929,.064,.062)],"dark",10)
    tube(scabbard,[(-.971,.033,-.929,.073,.066),(-.999,.036,-.967,.077,.068)],"gold",10,steps=1)
    return [body,head,legs,claws,shell,blade,helmet,banner,scabbard],palettes(
        "16274d/274f96/5da6d6","172652/3e61ae/89d2ee","344f84/76a0ce/b5dadf",
        "5e3c2c/d5a176","50a7bf/a6e5ec/fff3db","armor","vein")


def albatross():
    body=spine("Body",[(0,-.02,.565,.264,.225),(0,.014,.305,.386,.31),
                       (0,-.028,-.084,.364,.29),(0,-.065,-.424,.272,.221),
                       (0,-.066,-.626,.17,.136)],sides=20)
    tube(body,[(0,-.147,.393,.227,.159),(0,-.213,.041,.3,.163),
               (0,-.201,-.296,.242,.116)],"light",14)
    head=spine("Head",[(0,.066,.384,.237,.218),(0,.159,.621,.276,.266),
                       (0,.136,.81,.245,.227),(0,.108,.938,.164,.149)],sides=18)
    eyes(head,.181,.211,.825,.061,"dark")
    tail=tail_fan((0,-.063,-.566),.455,.13,.72,"fin")
    wingset=combine("Wings",wings((.24,.023,.22),1.51,.24,.94,.67))
    for sign in (-1,1):
        for i in range(5):
            x=.62+i*.16
            y=.013+i*.038
            z=.047-i*.155
            tube(wingset,mirror(sign,[(x,y,z,.081,.071),
                                     (x+.261,y+.057,z-.224,.088,.064),
                                     (x+.412,y+.104,z-.39,.044,.039),
                                     (x+.512,y+.155,z-.534,.009,.010)]),
                 "light" if i<2 else "fin",8,(0,1,0),steps=1)
    feet,tips,beak,clouds=(Piece(n) for n in ("Legs","Extra","Extra","Extra"))
    for sign in (-1,1):
        tube(feet,mirror(sign,[(.137,-.248,-.183,.068,.061),(.18,-.351,-.238,.059,.054),
                              (.169,-.406,-.338,.102,.049),(.175,-.418,-.49,.06,.027)]),"gold",9)
        tube(tips,mirror(sign,[(1.32,.212,-.668,.095,.04),(1.57,.252,-.812,.089,.033),
                              (1.756,.268,-.986,.014,.009)]),"magic",8)
    tube(beak,[(0,.082,.841,.151,.113),(0,.075,1.023,.127,.088),
               (0,.059,1.192,.088,.059),(0,.03,1.299,.029,.025),
               (0,-.014,1.315,.011,.013)],"gold",12)
    for x,y,z,r in ((-.179,-.21,-.531,.201),(.091,-.24,-.515,.22),(.24,-.232,-.644,.14),
                    (-.115,-.281,-.716,.163),(.081,-.288,-.760,.162)):
        oval(clouds,(x,y,z),(r,r*.71,r*1.04),"white",10,6)
    return [body,head,tail,wingset,feet,tips,beak,clouds],palettes(
        "7fabc8/c3e2e8/faf4dc","5f8dc1/abcee5/f4f1e1","9cb8ce/dae6ed/fff6d6",
        "283244/859aa8","7cb3e3/d2edf3/fff5db","none","vein")


RECIPES = {
    "C145_Peixe_Espada_Carmesim": (swordfish, [1, 2]),
    "C146_Crocodilo_de_Jade": (crocodile, [1]),
    "C147_Caranguejo_Cometa": (comet_crab, [1]),
    "C148_Cavalo_Marinho_Dragao": (seahorse, [1, 2]),
    "C149_Foca_de_Gelo_Mistico": (ice_seal, [1]),
    "C150_Tartaruga_Relampago": (thunder_turtle, [1]),
    "C151_Pinguim_Imperador_Cristal": (emperor, [1]),
    "C152_Manta_Solar": (solar_manta, [1, 2]),
    "C153_Peixe_Boi_Encantado": (manatee, [1]),
    "C154_Mamba_das_Mares": (mamba, [1, 2]),
    "C155_Siri_Samurai": (samurai_crab, [1]),
    "C156_Albatroz_das_Nuvens": (albatross, [1]),
}


def export(identifier, root, render):
    build, neon = RECIPES[identifier]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    out = root / identifier
    out.mkdir(parents=True, exist_ok=True)
    pieces, palette = build()
    material, cells = atlas(out / "color-atlas.png", palette, 512)
    objects = [piece.make(material, cells) for piece in pieces]
    low, high = bounds(objects)
    center = (low + high) * .5
    scale = 3.14 / max(high - low)
    extras = 0
    parts = {}
    for piece, obj in zip(pieces, objects, strict=True):
        obj.location = (obj.location - center) * scale
        for vertex in obj.data.vertices:
            vertex.co *= scale
        if piece.name == "Extra":
            extras += 1
            obj.name = f"Extra_{extras}"
        obj.data.update()
        obj.data.calc_loop_triangles()
        assert 0 < len(obj.data.loop_triangles) <= 2500, obj.name
        parts[obj.name] = len(obj.data.loop_triangles)
    bpy.context.view_layer.update()
    assert sum(parts.values()) <= 8000
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(out / f"{identifier}.blend"))
    bpy.ops.export_scene.gltf(filepath=str(out / f"{identifier}.glb"), export_format="GLB",
                              export_yup=True, export_animations=False)
    (out / "mesh-report.json").write_text(json.dumps({
        "id": identifier, "triangles": sum(parts.values()), "parts": parts,
        "neon": [f"Extra_{i}" for i in neon], "atlas": "color-atlas.png",
    }, indent=2) + "\n", encoding="utf-8")
    if render:
        preview_creature.ANGLES = {"frente": (0, -1, .12),
                                   "tres-quartos": (1, -1, .42)}
        preview_creature.render(out / "previews", objects, size=600)


def main():
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("--out", type=Path, default=Path(__file__).resolve().parent)
    args.add_argument("--skip-preview", action="store_true")
    args.add_argument("ids", nargs="*", choices=tuple(RECIPES))
    options = args.parse_args(sys.argv[sys.argv.index("--") + 1:])
    for identifier in options.ids or RECIPES:
        export(identifier, options.out, not options.skip_preview)


if __name__ == "__main__":
    main()
