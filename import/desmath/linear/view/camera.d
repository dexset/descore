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

module desmath.linear.view.camera;

public import desmath.linear.view.node;
public import desmath.linear.view.resolver;

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
        {
            auto prj = projection !is null ? projection.matrix : mat4.init;
            return prj * resolve(obj);
        }

        @property
        {
            mat4 matrix()
            {
                if( transform !is null )
                    return transform.matrix;
                else return mat4.init;
            }

            const(Node) parent() { return _parent; }
        }
    }
}

class LookAtTransform : Transform
{
    vec3 pos, target, up;
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
    { return vec3( resolver(node,center).col!(3).data[0..3] ); }
}

class PerspectiveTransform : Transform
{
    float fov = 70;
    float aspect = 4.0f / 3.0f;
    float near = 1e-5;
    float far = 1e5;

    @property mat4 matrix() const
    in
    {
        assert( fov > 0 );
        assert( aspect > 0 );
        assert( near > 0 );
        assert( far > 0 );
    }
    body { return calcPerspective( fov, aspect, near, far ); }
}

private:

mat4 calcLookAt( in vec3 pos, in vec3 trg, in vec3 up )
{
    auto z = (pos-trg).e;
    auto x = (up * z).e;
    vec3 y;
    if( x ) y = (z * x).e;
    else
    {
        y = (z * vec3(1,0,0)).e;
        x = (y * z).e;
    }
    return mat4( x.x, y.x, z.x, pos.x,
                 x.y, y.y, z.y, pos.y,
                 x.z, y.z, z.z, pos.z,
                   0,   0,   0,     1 );
}

mat4 calcPerspective( float fov_degree, float aspect, float znear, float zfar )
{
                        /+ fov conv to radians and div 2 +/
    float xymax = znear * tan( fov_degree * PI / 360.0 );
    float ymin = -xymax;
    float xmin = -xymax;

    float width = xymax - xmin;
    float height = xymax - ymin;

    float depth = znear - zfar;
    float q = (zfar + znear) / depth;
    float dzn = 2.0 * znear;
    float n = dzn * zfar / depth;

    float w = dzn / ( width * aspect );
    float h = dzn / height;

    return mat4( w, 0,  0, 0,
                 0, h,  0, 0,
                 0, 0,  q, n,
                 0, 0, -1, 0 );
}

//mat4 ortho( sz_vec sz, z_vec z )
//{
//    return ortho( sz.w, sz.h, z.n, z.f );
//}

mat4 calcOrtho( float w, float h, float znear, float zfar )
{
    float x = znear - zfar;
    return mat4( 2/w, 0,   0,       0,
                 0,   2/h, 0,       0,
                 0,   0,  -1/x,     0,
                 0,   0,   znear/x, 1 );
}
