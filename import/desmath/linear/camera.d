/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desmath.linear.camera;

public import desmath.linear.node;

import std.math;

mat4 _lookAt( in vec3 pos, in vec3 to, in vec3 up )
{
    auto z = (pos-to).e;
    auto x = (up * z).e;
    vec3 y;
    if( x ) y = (z * x).e;
    else
    {
        y = (z * vec3(1,0,0)).e;
        x = (y * z).e;
    }
    return mat4([ x.x, y.x, z.x, pos.x,
                  x.y, y.y, z.y, pos.y,
                  x.z, y.z, z.z, pos.z,
                    0,   0,   0,     1 ]);
}

mat4 _perspective(float fov, float aspect, float znear, float zfar)
{
    float xymax = znear * tan(fov * PI / 360.0);
    float ymin = -xymax;
    float xmin = -xymax;

    float width = xymax - xmin;
    float height = xymax - ymin;

    float depth = znear - zfar;
    float q = (zfar + znear) / depth;
    float dzn = 2.0 * znear;
    float qn = dzn * zfar / depth;

    float w = dzn / ( width * aspect );
    float h = dzn / height;

    return mat4([ w, 0,  0, 0,
                  0, h,  0, 0,
                  0, 0,  q, qn,
                  0, 0, -1, 0 ]);
}

/+ TODO:
mat4 ortho( sz_vec sz, z_vec z )
{
    float x = z.n - z.f;
    return mat4([ 2/sz.w, 0,      0,       0,
                  0,      2/sz.h, 0,       0,
                  0,      0,      -1/x,    0,
                  0,      0,      z.n/x,   1 ]);
}

mat4 ortho( float w, float h, float znear, float zfar )
{
    return ortho( sz_vec( w, h ), z_vec( znear, zfar ) );
}
+/

class Camera: Node
{
protected:
    Node handler = null;
    Resolver rsl;
    mat4 mtr;

public:
    this( Node par=null, Resolver R=null )
    {
        handler = par;
        rsl = R;
        if( rsl is null )
            rsl = new Resolver;
    }

    const
    {
        mat4 resolve( const(Node) obj ) { return rsl(obj, this); }
        mat4 opCall( const(Node) obj ) { return rsl(obj, this); }
        vec3 map( in vec3 pnt, const(Node) obj=null )
        {
            auto r = opCall(obj is null?this:obj).inv * vec4(pnt,1);
            return r.xyz;
        }

        override @property
        {
            mat4 self() { return mtr; }
            const(Node) parent() { return handler; }
        }
    }
}

unittest
{
    auto cam = new Camera;
    auto tt = cam(cam);
    assert( eq( tt, mat4() ) );

    auto vv = vec3( 1,2,3 );
    assert( eq( vv, cam.map(vv) ) );

    static class TObj: Node
    {
        mat4 mtr;
        this() { mtr.col!3 = vec4( 1,2,0,1 ); }
        final override const @property
        {
            mat4 self() { return mtr; }
            const(Node) parent() { return null; }
        }
    }

    auto to = new TObj;

    assert( eq( vec3(0,0,3), cam.map(vv,to) ) );
}

class BaseCamera: Camera
{
public:
    this( Node par=null, Resolver R=null ) { super(par,R); }

    final @property
    {
        override const
        {
            mat4 self() { return mtr; }
            const(Node) parent() { return handler; }
        }

        Node parent( Node par )
        {
            handler = par;
            return par;
        }

        mat4 self( in mat4 nm )
        {
            mtr = nm;
            return nm;
        }
    }
}

class MCamera: BaseCamera
{
protected:
    mat4 prj;

    float aspect = 4.0 / 3.0;
    float pangle = 60; // perspective angle
    float[2] clip = [ 0.1f, 100 ];

    void recalcPerspective()
    { prj = _perspective( pangle, aspect, clip[0], clip[1] ); }

public:

    this( Node par=null, Resolver R=null ) 
    { 
        super( par, R ); 
        recalcPerspective();
    }

    void look( in vec3 pos, in vec3 to, in vec3 up=vec3(0,0,1) )
    { mtr = _lookAt( pos, to, up ); }

    void setPerspective( float AR, float PA, float ZN, float ZF )
    {
        aspect = AR;
        pangle = PA;
        clip = [ ZN, ZF ];
        recalcPerspective();
    }

    /+ TODO
    void setOrtho( ... )
    +/

    override mat4 opCall( const(Node) obj ) const
    { return prj * super.opCall(obj); }

    @property
    {
        float aspectRatio() const { return aspect; }
        void aspectRatio( float ar )
        {
            aspect = ar;
            recalcPerspective();
        }

        float perspAngle() const { return pangle; }
        void perspAngle( float pa )
        {
            pangle = pa;
            recalcPerspective();
        }

        float[2] clipDistance() const { return clip; }
        void clipDistance( float[2] cd )
        {
            clip = cd;
            recalcPerspective();
        }

        mat4 projection() const { return prj; }
        void projection( in mat4 pp ) { prj = pp; }
    }
}
