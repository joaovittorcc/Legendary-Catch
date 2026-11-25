"""Export the Epic creature blueprints as textured GLB files without Blender."""

import ast
import argparse
import json
import math
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def mul(a, n):
    return tuple(x * n for x in a)


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0])


def unit(v):
    length = math.sqrt(dot(v, v))
    return mul(v, 1 / length) if length > 1e-9 else (0, 1, 0)


def interpolate(stations, steps):
    for i in range(len(stations)-1):
        a, b, c, d = (stations[max(0,i-1)], stations[i],
                      stations[i+1], stations[min(len(stations)-1,i+2)])
        for j in range(steps):
            t = j/steps
            yield tuple(.5*(2*v+(w-u)*t+(2*u-5*v+4*w-x)*t*t+(-u+3*v-3*w+x)*t*t*t)
                        for u,v,w,x in zip(a,b,c,d))
    yield stations[-1]


class Piece:
    def __init__(self, name):
        self.name, self.vertices, self.faces, self.paint = name, [], [], []

    def rings(self, rings, swatch, smooth=True):
        n, first = len(rings[0]), len(self.vertices)
        self.vertices.extend(v for ring in rings for v in ring)
        for j in range(len(rings)-1):
            h = len(rings)-1
            for k in range(n):
                a, b = k, (k+1)%n
                self.faces.append(tuple(first+i for i in (j*n+a,j*n+b,(j+1)*n+b,(j+1)*n+a)))
                self.paint.append((swatch, ((k/n,j/h),((k+1)/n,j/h),((k+1)/n,(j+1)/h),(k/n,(j+1)/h)), smooth))
        for j, order in ((0, tuple(range(n-1,-1,-1))), (len(rings)-1, tuple(range(n)))):
            self.faces.append(tuple(first+j*n+i for i in order))
            self.paint.append((swatch, tuple((.5+.4*math.cos(math.tau*i/n),.5+.4*math.sin(math.tau*i/n))
                                               for i in order), False))

    def sweep(self, stations, swatch, sides=10, reference=(1,0,0), steps=1, smooth=True):
        flat = [(*p,w,h) for p,w,h in stations]
        samples = list(interpolate(flat,steps)) if steps>1 else flat
        rings = []
        for j, (x,y,z,w,h) in enumerate(samples):
            tangent=unit(sub(samples[min(j+1,len(samples)-1)][:3],samples[max(0,j-1)][:3]))
            right=sub(reference,mul(tangent,dot(reference,tangent)))
            if dot(right,right)<1e-6:
                right=cross(tangent,(0,0,1) if abs(tangent[2])<.85 else (0,1,0))
            right=unit(right)
            up=cross(tangent,right)
            ring=[]
            for k in range(sides):
                angle=math.tau*k/sides
                ring.append(add(add((x,y,z),mul(right,max(.004,w)*math.cos(angle))),
                                mul(up,max(.004,h)*math.sin(angle))))
            rings.append(ring)
        self.rings(rings,swatch,smooth)

    def oval(self, center, radii, swatch, sides=12, levels=7):
        rings=[]
        for i in range(levels):
            angle=math.pi*(.02+.96*i/(levels-1)-.5)
            ring=[]
            for j in range(sides):
                a=math.tau*j/sides
                direction=(math.cos(angle)*math.cos(a),math.cos(angle)*math.sin(a),math.sin(angle))
                ring.append(add(center,tuple(x*y for x,y in zip(radii,direction))))
            rings.append(ring)
        self.rings(rings,swatch)

    def gem(self, a, b, width, swatch):
        self.sweep([(a,width*.6,width*.55),
                    (add(mul(a,.68),mul(b,.32)),width,width*.75),
                    (b,.006,.004)],swatch,sides=6,smooth=False)


def recipes():
    source=ast.parse((ROOT/"build_epics.py").read_text(encoding="utf-8"))
    nodes=[n for n in source.body
           if (isinstance(n,ast.FunctionDef) and n.name not in ("export","main"))
           or (isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=="RECIPES" for t in n.targets))]
    namespace=dict(math=math,Piece=Piece)
    exec(compile(ast.Module(body=nodes,type_ignores=[]),"epic_mesh_blueprints","exec"),namespace)
    return namespace["RECIPES"]


def png_chunk(kind, data):
    return struct.pack(">I",len(data))+kind+data+struct.pack(">I",zlib.crc32(kind+data))


def make_atlas(palette):
    size, cell=512,128
    swatches=list(palette)
    values=[]
    for name in swatches:
        colors,pattern=palette[name]
        stops=[tuple(bytes.fromhex(value)) for value in colors.split("/")]
        values.append((stops,pattern))
    pixels=bytearray()
    for y in range(size):
        pixels.append(0)
        for x in range(size):
            i=(y//cell)*4+x//cell
            if i>=len(values):
                pixels.extend((23,31,55))
                continue
            stops,pattern=values[i]
            u,v=(x%cell)/(cell-1),1-(y%cell)/(cell-1)
            t=max(0,min(1,.18+.66*v+.14*math.cos(math.tau*u)))
            index=min(len(stops)-2,int(t*(len(stops)-1))) if len(stops)>1 else 0
            f=t*(len(stops)-1)-index
            a,b=stops[index],stops[min(len(stops)-1,index+1)]
            grain=1.35*math.sin(x*79.45+y*33.7)
            if pattern=="scale":
                row=v*9
                seam=(row+.20*(1-math.cos(math.tau*(u*9+.5*math.floor(row))))+.5)%1-.5
                grain-=17*math.exp(-(seam/.073)**2)
            elif pattern in ("fin","vein","armor"):
                vein=math.sin(math.tau*((4 if pattern=="vein" else 8)*u+.16*math.sin(math.tau*v)))
                grain+=11*math.exp(-(vein/.23)**2)*(.3+.7*v)
            elif pattern=="star":
                lookup=math.sin(x*1.147+y*.125)*math.sin(y*1.62+x*.373)
                if lookup>.964:
                    grain+=29
            pixels.extend(max(0,min(255,round(a[k]*(1-f)+b[k]*f+grain))) for k in range(3))
    image=b"\x89PNG\r\n\x1a\n"+png_chunk(b"IHDR",struct.pack(">IIBBBBB",size,size,8,2,0,0,0))
    image+=png_chunk(b"IDAT",zlib.compress(bytes(pixels),8))+png_chunk(b"IEND",b"")
    return image,{n:(i%4/4,i//4/4) for i,n in enumerate(swatches)}


def make_glb(identifier, build, neon, destination):
    pieces,palette=build()
    png,cells=make_atlas(palette)
    coordinates=[(x,z,y) for part in pieces for x,y,z in part.vertices]
    low=[min(v[k] for v in coordinates) for k in range(3)]
    high=[max(v[k] for v in coordinates) for k in range(3)]
    scale=.8792/max(h-l for h,l in zip(high,low))
    center=[(h+l)/2 for h,l in zip(high,low)]
    blob=bytearray()
    views,accessors,meshes,nodes=[],[],[],[]
    def buffer(data,target=None):
        blob.extend(b"\0"*((-len(blob))%4))
        item={"buffer":0,"byteOffset":len(blob),"byteLength":len(data)}
        if target:
            item["target"]=target
        views.append(item)
        blob.extend(data)
        return len(views)-1
    def attribute(data,kind):
        shape={"VEC2":2,"VEC3":3}[kind]
        raw=struct.pack("<"+"f"*(len(data)*shape),*(val for v in data for val in v))
        obj={"bufferView":buffer(raw,34962),"componentType":5126,"count":len(data),"type":kind}
        obj["min"]=[min(v[k] for v in data) for k in range(shape)]
        obj["max"]=[max(v[k] for v in data) for k in range(shape)]
        accessors.append(obj)
        return len(accessors)-1
    texture=buffer(png)
    extras=0
    info={}
    for piece in pieces:
        name=piece.name
        if name=="Extra":
            extras+=1
            name=f"Extra_{extras}"
        positions=[mul(sub((x,z,y),center),scale) for x,y,z in piece.vertices]
        middle=tuple((min(v[k] for v in positions)+max(v[k] for v in positions))*.5 for k in range(3))
        positions=[sub(v,middle) for v in positions]
        # Blender-style blueprint axes convert to right handed glTF with the front on -Z.
        normals=[(0,0,0)]*len(positions)
        triangles=[]
        for face,(swatch,uvs,smooth) in zip(piece.faces,piece.paint,strict=True):
            for k in range(1,len(face)-1):
                ids=(face[0],face[k+1],face[k])
                norm=cross(sub(positions[ids[1]],positions[ids[0]]),sub(positions[ids[2]],positions[ids[0]]))
                triangles.append((ids,(uvs[0],uvs[k+1],uvs[k]),swatch,smooth,norm))
                if smooth:
                    for v in ids:
                        normals[v]=add(normals[v],norm)
        pts,ln,tx=[],[],[]
        for ids,uvs,color,smooth,norm in triangles:
            ox,oy=cells[color]
            for index,(u,v) in zip(ids,uvs,strict=True):
                pts.append(positions[index])
                ln.append(unit(normals[index] if smooth else norm))
                tx.append((ox+.017+.215*u,oy+.017+.215*(1-v)))
        info[name]=len(triangles)
        meshes.append({"name":name,"primitives":[{"attributes":{
            "POSITION":attribute(pts,"VEC3"),"NORMAL":attribute(ln,"VEC3"),
            "TEXCOORD_0":attribute(tx,"VEC2")},"material":0}]})
        nodes.append({"name":name,"mesh":len(meshes)-1,"translation":list(middle)})
    assert sum(info.values())<=8000 and all(v<20000 for v in info.values()),info
    data={"asset":{"version":"2.0","generator":"Legendary Catch mesh authoring"},
          "scene":0,"scenes":[{"nodes":list(range(len(nodes)))}],"nodes":nodes,"meshes":meshes,
          "materials":[{"name":"Painted creature","pbrMetallicRoughness":{
              "baseColorTexture":{"index":0},"metallicFactor":0,"roughnessFactor":.42},"doubleSided":True}],
          "textures":[{"source":0}],"images":[{"bufferView":texture,"mimeType":"image/png"}],
          "bufferViews":views,"accessors":accessors,"buffers":[{"byteLength":len(blob)}]}
    doc=json.dumps(data,separators=(",",":")).encode()
    doc+=b" "*((-len(doc))%4)
    blob.extend(b"\0"*((-len(blob))%4))
    result=struct.pack("<III",0x46546C67,2,28+len(doc)+len(blob))
    result+=struct.pack("<II",len(doc),0x4E4F534A)+doc
    result+=struct.pack("<II",len(blob),0x004E4942)+blob
    destination.mkdir(parents=True,exist_ok=True)
    (destination/f"{identifier}.glb").write_bytes(result)
    (destination/f"{identifier}.json").write_text(json.dumps({
        "id":identifier,"parts":info,"total":sum(info.values()),
        "neon":[f"Extra_{i}" for i in neon],"size_studs":3.14,
    },indent=2)+"\n",encoding="utf-8")
    print(identifier,sum(info.values()),len(pieces))


if __name__=="__main__":
    spec=recipes()
    args=argparse.ArgumentParser(description=__doc__)
    args.add_argument("identifiers",nargs="+")
    options=args.parse_args()
    for identifier in options.identifiers:
        make_glb(identifier,*spec[identifier],ROOT)
