module des.space.transform;

public import des.math.linear.vector;
public import des.math.linear.matrix;

import des.util.logsys;

import std.math;

///
interface Transform
{
    ///
    mat4 matrix() @property const;

    ///
    protected final static mat4 getMatrix( const(Transform) tr )
    {
        if( tr !is null )
            return tr.matrix;
        return mat4.diag(1);
    }
}

///
class SimpleTransform : Transform
{
protected:
    mat4 mtr; ///

public:
    @property
    {
        ///
        mat4 matrix() const { return mtr; }
        ///
        void matrix( in mat4 m ) { mtr = m; }
    }
}

///
class TransformList : Transform
{
    Transform[] list; ///
    enum Order { DIRECT, REVERSE }
    Order order = Order.DIRECT; ///

    ///
    @property mat4 matrix() const
    {
        mat4 buf;
        if( order == Order.DIRECT )
            foreach( tr; list )
                buf *= tr.matrix;
        else
            foreach_reverse( tr; list )
                buf *= tr.matrix;
        return buf;
    }
}

///
class CachedTransform : Transform
{
protected:
    mat4 mtr; ///
    Transform transform_source; ///

public:

    ///
    this( Transform ntr ) { setTransform( ntr ); }

    ///
    void setTransform( Transform ntr )
    {
        transform_source = ntr;
        recalc();
    }

    ///
    void recalc()
    {
        if( transform_source !is null )
            mtr = transform_source.matrix;
        else mtr = mat4.diag(1);
    }

    ///
    @property mat4 matrix() const { return mtr; }
}

///
class LookAtTransform : Transform
{
    ///
    vec3 pos=vec3(0), target=vec3(0), up=vec3(0,0,1);

    ///
    @property mat4 matrix() const
    { return calcLookAt( pos, target, up ); }
}

///
class ViewTransform : Transform
{
protected:

    float _ratio = 4.0f / 3.0f;
    float _near = 1e-1;
    float _far = 1e5;

    float nflim = 1e-5;

    mat4 self_mtr;

    ///
    abstract void recalc();

    invariant()
    {
        assert( _ratio > 0 );
        assert( _near > 0 && _near < _far );
        assert( _far > 0 );
        assert( nflim > 0 );
        assert( !!self_mtr );
    }

public:

    @property
    {
        ///
        float ratio() const { return _ratio; }
        ///
        float ratio( float v )
        in { assert( v !is float.nan ); } body
        {
            enum lim = 1000000.0f;
            if( v <= 0 )
            {
                v = 1 / lim;
                logger.warn( "value <= 0, set to: ", 1 / lim );
            }
            if( v > lim )
            {
                v = lim;
                logger.warn( "value > %s, set to: %s", lim, lim );
            }
            _ratio = v;
            recalc();
            return v;
        }

        ///
        float near() const { return _near; }
        ///
        float near( float v )
        in { assert( v !is float.nan ); } body
        {
            if( v > _far )
            {
                _far = v + nflim;
                logger.warn( "value > far, far set to 'value + nflim': ", v + nflim );
            }
            if( v < 0 )
            {
                v = 0;
                logger.warn( "value < 0, set to: 0" );
            }
            _near = v;
            recalc();
            return v;
        }

        ///
        float far() const { return _far; }
        ///
        float far( float v )
        in { assert( v !is float.nan ); } body
        {
            if( v < nflim * 2 )
            {
                v = nflim * 2;
                logger.warn( "value < nflim * 2, set to: ", nflim * 2 );
            }
            if( v < _near )
            {
                _near = v - nflim;
                logger.warn( "value < near, near set to 'value - nflim': ", v - nflim );
            }
            _far = v;
            recalc();
            return v;
        }

        ///
        mat4 matrix() const { return self_mtr; }
    }
}

///
class PerspectiveTransform : ViewTransform
{
protected:
    float _fov = 70;

    override void recalc() { self_mtr = calcPerspective( _fov, _ratio, _near, _far ); }

    invariant() { assert( _fov > 0 ); }

public:

    @property
    {
        ///
        float fov() const { return _fov; }
        ///
        float fov( float v )
        in { assert( v !is float.nan ); } body
        {
            enum minfov = 1e-5;
            enum maxfov = 180 - minfov;
            if( v < minfov )
            {
                v = minfov;
                logger.warn( "value < minfov, set to minfov: ", minfov );
            }
            if( v > maxfov )
            {
                v = maxfov;
                logger.warn( "value > maxfov, set to maxfov: ", maxfov );
            }
            _fov = v;
            recalc();
            return v;
        }
    }
}

///
class OrthoTransform : ViewTransform
{
protected:

    float _scale = 1;

    invariant()
    {
        assert( _scale > 0 );
    }

    override void recalc()
    {
        self_mtr = mat4.init;
        self_mtr[0][0] = _scale;
        self_mtr[1][1] = _scale * _ratio;
        self_mtr[2][2] = -2.0f / ( _far - _near );
        self_mtr[3][2] = -( _far + _near ) / ( _far - _near );
    }

public:

    @property
    {
        ///
        float scale() const { return _scale; }
        ///
        float scale( float v )
        in { assert( v !is float.nan ); } body
        {
            if( v < 1e-8 )
            {
                v = 1e-8;
                logger.warn( "value < 1e-8, set to 1e-8" );
            }
            _scale = v;
            recalc();
            return v;
        }
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
