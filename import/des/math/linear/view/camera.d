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

module des.math.linear.view.camera;

public import des.math.linear.view.node;
public import des.math.linear.view.resolver;

import std.math;

class Camera: Node
{
protected:
    Node _parent;

public:

    Resolver resolver;
    Transform projection, transform;

    this( Node par=null )
    {
        _parent = par;
        resolver = new Resolver;
    }

    const
    {
        mat4 resolve( const(Node) obj ) { return resolver(obj, this); }

        mat4 opCall( const(Node) obj )
        { return getMatrix( projection ) * resolve(obj); }

        @property
        {
            mat4 matrix() { return getMatrix( transform ); }
            const(Node) parent() { return _parent; }
        }
    }
}

class LookAtTransform : Transform
{
    vec3 pos=vec3(0), target=vec3(0), up=vec3(0,0,1);
    @property mat4 matrix() const
    { return calcLookAt( pos, target, up ); }
}

class ResolveTransform : Transform
{
protected:
    Resolver resolver;
public:
    void setResolver( Resolver rsl ) { resolver = rsl; }
    abstract @property mat4 matrix() const;
}

class LookAtNodeTransform : ResolveTransform
{
    Node center, target, up;

    override @property mat4 matrix() const
    in
    {
        assert( center !is null );
        assert( target !is null );
        assert( up !is null );
        assert( resolver !is null );
    }
    body
    {
        return calcLookAt( center.offset,
                           resolveOffset(target),
                           resolveOffset(up) );
    }

protected:

    vec3 resolveOffset( const(Node) node ) const
    { return vec3( resolver(node,center).col(3)[0..3] ); }
}

class PerspectiveTransform : Transform
{
    float fov = 70;
    float ratio = 4.0f / 3.0f;
    float near = 1e-1;
    float far = 1e5;

    @property mat4 matrix() const
    in
    {
        assert( fov > 0 );
        assert( ratio > 0 );
        assert( near > 0 );
        assert( far > 0 );
    }
    body { return calcPerspective( fov, ratio, near, far ); }
}

/+ simple lookAt perspective camera +/
class SimpleCamera : Camera
{
protected:
    LookAtTransform look_tr;
    PerspectiveTransform perspective;

public:

    this( Node p=null )
    {
        super(p);
        look_tr = new LookAtTransform;
        look_tr.up = vec3(0,0,1);
        transform = look_tr;
        perspective = new PerspectiveTransform;
        projection = perspective;
    }

    @property
    {
        void fov( float val ) { perspective.fov = val; }
        float fov() const { return perspective.fov; }

        void ratio( float val ) { perspective.ratio = val; }
        float ratio() const { return perspective.ratio; }

        void near( float val ) { perspective.near = val; }
        float near() const { return perspective.near; }

        void far( float val ) { perspective.far = val; }
        float far() const { return perspective.far; }

        void pos( in vec3 val ) { look_tr.pos = val; }
        vec3 pos() const { return look_tr.pos; }

        void up( in vec3 val ) { look_tr.up = val; }
        vec3 up() const { return look_tr.up; }

        void target( in vec3 val ) { look_tr.target = val; }
        vec3 target() const { return look_tr.target; }
    }
}

private:

mat4 calcLookAt( in vec3 pos, in vec3 trg, in vec3 up )
{
    auto z = (pos-trg).e;
    auto x = cross(up,z).e;
    vec3 y;
    if( x ) y = cross(z,x).e;
    else
    {
        y = cross(z,vec3(1,0,0)).e;
        x = cross(y,z).e;
    }
    return mat4( x.x, y.x, z.x, pos.x,
                 x.y, y.y, z.y, pos.y,
                 x.z, y.z, z.z, pos.z,
                   0,   0,   0,     1 );
}

mat4 calcPerspective( float fov_degree, float ratio, float znear, float zfar )
{
                        /+ fov conv to radians and div 2 +/
    float h = 1.0 / tan( fov_degree * PI / 360.0 );
    float w = h / ratio;

    float depth = znear - zfar;
    float q = ( znear + zfar ) / depth;
    float n = ( 2.0f * znear * zfar ) / depth;

    return mat4( w, 0,  0, 0,
                 0, h,  0, 0,
                 0, 0,  q, n,
                 0, 0, -1, 0 );
}

mat4 calcOrtho( float w, float h, float znear, float zfar )
{
    float x = znear - zfar;
    return mat4( 2/w, 0,   0,       0,
                 0,   2/h, 0,       0,
                 0,   0,  -1/x,     0,
                 0,   0,   znear/x, 1 );
}
