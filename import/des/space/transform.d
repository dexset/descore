module des.space.transform;

public import des.math.linear.vector;
public import des.math.linear.matrix;

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
