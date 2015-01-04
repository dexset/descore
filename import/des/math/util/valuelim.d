module des.math.util.valuelim;

import std.traits;
import std.algorithm;

///
struct ValueLimiter(size_t CNT,T=float)
if( CNT > 0 && isFloatingPoint!T )
{
protected:
    T min_limit;
    T max_limit;

    ///
    T[CNT] values;

public:
    @property
    {
        ///
        T minLimit() const { return min_limit; }

        ///
        T minLimit( T v )
        {
            min_limit = v > max_limit ? max_limit : v;
            correctValuesMinMax();
            return min_limit;
        }

        ///
        T maxLimit() const { return max_limit; }

        ///
        T maxLimit( T v )
        {
            max_limit = v < min_limit ? min_limit : v;
            correctValuesMinMax();
            return max_limit;
        }
    }

    ///
    T set( size_t i, T v )
    in{ assert( i < CNT ); }
    body
    {
        values[i] = min( max( min_limit, v ), max_limit );
        moveValues(i);
        return values[i];
    }

    ///
    T setNorm( size_t i, T nv )
    in
    {
        assert( i < CNT );
        assert( nv <= 1.0 );
    }
    body
    {
        auto v = full(nv);
        set(i,v);
        return getNorm(i);
    }

    ///
    T get( size_t i )
    in{ assert( i < CNT ); }
    body { return values[i]; }

    ///
    T getNorm( size_t i )
    in{ assert( i < CNT ); }
    body { return norm( get(i) ); }

protected:

    void correctValuesMinMax() { foreach( ref v; values ) correctMinMax( v ); }

    void correctMinMax( ref T v )
    { v = ( v >= min_limit ? ( v <= max_limit ? v : max_limit ) : min_limit ); }

    void moveValues( size_t k )
    {
        foreach( i, ref v; values )
        {
            if( i == k ) continue;
            if( i < k && v > values[k] )
                v = values[k];
            if( i > k && v < values[k] )
                v = values[k];
        }
    }

    T norm( T v ) const
    { return (v - min_limit) / (max_limit - min_limit); }

    T full( T v ) const
    { return min_limit + v * (max_limit - min_limit); }
}

///
unittest
{
    auto vh = ValueLimiter!(2,float)();

    vh.minLimit = 0;
    vh.maxLimit = 10;

    vh.set( 0, 5 );
    vh.set( 1, 7 );

    assert( vh.get(0) == 5 );
    assert( vh.get(1) == 7 );

    vh.set(1,3);

    assert( vh.get(0) == 3 );
    assert( vh.get(1) == 3 );

    vh.set(1,20);
    assert( vh.get(0) == 3 );
    assert( vh.get(1) == 10 );
}

unittest
{
    auto vh = ValueLimiter!2();

    vh.minLimit = 0;
    vh.maxLimit = 10;

    vh.setNorm( 0, 0.5 );
    vh.setNorm( 1, 0.7 );

    assert( vh.get(0) == 5 );
    assert( vh.get(1) == 7 );

    vh.setNorm( 0, 0.8 );

    assert( vh.get(0) == 8 );
    assert( vh.get(1) == 8 );

    import std.math;

    assert( abs( vh.getNorm(0) - .8 ) < float.epsilon * 2 );
    assert( abs( vh.getNorm(1) - .8 ) < float.epsilon * 2 );
}
