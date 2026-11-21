"""Paint small readable creature faces and patterns in atlas coordinates."""

import math

import numpy as np


def layer(base, color, mask):
    amount = np.clip(mask, 0, 1)[..., None]
    base[:] = base * (1 - amount) + np.asarray(color) * amount


def ellipse(u, v, x, y, width, height, angle=0):
    du, dv = u - x, v - y
    cos, sin = math.cos(angle), math.sin(angle)
    radius = np.hypot((du*cos + dv*sin)/width, (dv*cos - du*sin)/height)
    return np.clip((1 - radius) * 8 + 0.5, 0, 1)


def paint_face(base, u, v, style):
    """An oval's front lies at u=.75, with x increasing toward u=1."""
    ink = (0.020, 0.027, 0.053)
    rim = (0.13, 0.055, 0.085)
    smile = .409 + 8.6 * (u - .75)**2
    layer(base, rim, np.clip((.015 - np.abs(v-smile))*125,0,1) *
          np.clip((.054 - np.abs(u-.75))*140,0,1))
    if style == "sleepy":
        for x in (.665,.835):
            lid = .563 + 9.5*(u-x)**2
            layer(base, ink, np.clip((.014-np.abs(v-lid))*138,0,1) *
                  np.clip((.045-np.abs(u-x))*130,0,1))
    else:
        iris = {"sun": (.31,.095,.021), "sea": (.043,.14,.19),
                "coral": (.24,.068,.12)}[style]
        for x in (.663,.837):
            lean = .12 if x < .75 else -.12
            layer(base, rim, ellipse(u,v,x,.593,.046,.123,lean))
            layer(base, (.99,.93,.79), ellipse(u,v,x,.593,.039,.102,lean))
            pupil = x + (.008 if x < .75 else -.008)
            layer(base, iris, ellipse(u,v,pupil,.581,.032,.086,lean))
            layer(base, ink, ellipse(u,v,pupil,.597,.023,.066,lean))
            layer(base, (1,1,.98), ellipse(u,v,pupil-.010,.633,.013,.028))
            layer(base, (.76,.88,.92), ellipse(u,v,pupil+.011,.563,.006,.011))
    for x in (.602,.898):
        layer(base, (.94,.27,.33), .6*ellipse(u,v,x,.44,.036,.063))


def paint_pattern(base, u, v, pattern):
    """Broad hand-painted shapes remain readable on a 256 px atlas."""
    if pattern == "sunstripe":
        layer(base, (.06,.46,.52), .84*ellipse(u,v,.50,.52,.102,.51))
        layer(base, (.06,.46,.52), .84*ellipse(u,v,0,.52,.102,.51))
        layer(base, (.06,.46,.52), .84*ellipse(u,v,1,.52,.102,.51))
    elif pattern == "confetti":
        warm = .34+.10*np.cos(math.tau*u)
        band = np.cos(math.tau*(3.2*v+.08*np.sin(math.tau*u)))
        layer(base, (.90,.48,.27), warm*np.clip(band*2,0,1))
        marks = ((.13,.34,.64),(.27,.49,-.46),(.45,.20,.52),(.58,.65,.6),
                 (.71,.30,-.73),(.84,.53,.4),(.94,.76,-.32))
        for index,(x,y,angle) in enumerate(marks):
            color = ((.17,.76,.72),(.97,.81,.34),(.99,.48,.57))[index%3]
            layer(base,color,.79*ellipse(u,v,x,y,.024,.051,angle))
    elif pattern == "moss":
        for x,y,w,h in ((.15,.39,.12,.11),(.33,.54,.15,.26),(.65,.44,.18,.16),(.87,.69,.17,.17)):
            layer(base, (.30,.62,.18), .61*ellipse(u,v,x,y,w,h))
        for x,y in ((.18,.38),(.36,.53),(.71,.43),(.87,.68),(.92,.55)):
            layer(base, (.67,.80,.24), .50*ellipse(u,v,x,y,.048,.056))
        layer(base, (.88,.60,.19), .8*np.clip((.19-v)*15,0,1))
    elif pattern == "fin":
        grain = np.cos(4 * math.tau * (u + .04 * np.sin(math.tau * v)))
        layer(base,(.52,.93,.91),.16*np.clip(grain,0,1)*v)
    elif pattern == "cap":
        for x,y in ((.22,.38),(.52,.65),(.77,.43)):
            dx,dy=np.abs(u-x),np.abs(v-y)
            spark=np.clip((1-np.sqrt(dx/.044)-np.sqrt(dy/.084))*9,0,1)
            layer(base,(.95,.71,.25),spark)
