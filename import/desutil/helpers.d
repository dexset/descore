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

module desutil.helpers;

pure nothrow string toDString( const(char*) c_str )
{
    string buf;
    char *ch = cast(char*)c_str;
    while( *ch != '\0' ) buf ~= *(ch++);
    return buf;
}

pure nothrow string toDStringFix(size_t S)( const(char[S]) c_buf )
{
    string buf;
    foreach( c; c_buf ) buf ~= c;
    return buf;
}

import core.runtime, std.file, std.path;

string appPath( string[] elems... ) 
{ return buildNormalizedPath( dirName( thisExePath ) ~ elems ); }
string bnPath( string[] elems... ) 
{ return buildNormalizedPath( elems ); }

import std.traits;

struct lim_t(T) if( isNumeric!T )
{
    T minimum=0, maximum=T.max;
    bool fix = false;

    pure nothrow this( T Min, T Max )
    {
        minimum = Min;
        maximum = Max;
    }

    T opCall( T old, T nval ) const
    {
        if( fix ) return old;
        return nval >= minimum ? ( nval < maximum ? nval : maximum ) : minimum;
    }
}

struct ValueHandler(size_t CNT,T=float) 
if( CNT > 0 && isFloatingPoint!T )
{
protected:
    T min_limit;
    T max_limit;

    T[CNT] values;

public:
    @property
    {
        T minLimit() const { return min_limit; }

        T minLimit( T v )
        {
            min_limit = v > max_limit ? max_limit : v;
            correctValuesMinMax();
            return min_limit;
        }

        T maxLimit() const { return max_limit; }

        T maxLimit( T v )
        {
            max_limit = v < min_limit ? min_limit : v;
            correctValuesMinMax();
            return max_limit;
        }
    }

    T set( size_t i, T v )
    in{ assert( i < CNT ); }
    body
    {
        import std.algorithm;
        values[i] = min( max( min_limit, v ), max_limit );
        moveValues(i);
        return values[i];
    }

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

    T get( size_t i )
    in{ assert( i < CNT ); }
    body { return values[i]; }

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

unittest
{
    auto vh = ValueHandler!(2,float);

    vh.minLimit = 0;
    vh.maxLimit = 10;

    vh.set( 0, 5 );
    vh.set( 1, 7 );

    assert( vh.get(0) == 5 );
    assert( vh.get(1) == 7 );

    vh.set(1,3);

    assert( vh.get(0) == 3 );
    assert( vh.get(1) == 3 );
}

unittest
{
    auto vh = ValueHandler!2;

    vh.minLimit = 0;
    vh.maxLimit = 10;

    vh.setNorm( 0, 0.5 );
    vh.setNorm( 1, 0.7 );

    assert( vh.get(0) == 5 );
    assert( vh.get(1) == 7 );

    vh.setNorm( 0, 0.8 );

    assert( vh.get(0) == 8 );
    assert( vh.get(1) == 8 );

    assert( vh.getNorm(0) == .8 );
    assert( vh.getNorm(1) == .8 );
}

interface ExternalMemoryManager
{
    protected @property final static string getMixinChildEMM()
    {
        return `private ExternalMemoryManager[] chemm;
                protected final ref ExternalMemoryManager[] childEMM() { return chemm; }`;
    }

    protected @property final static string getMixinAllEMMFuncs()
    {
        return getMixinChildEMM ~ `
            protected void selfDestroy() {}`;
    }

    protected
    {
        @property ref ExternalMemoryManager[] childEMM();
        void selfDestroy();
    }

    final
    {
        T registerChildEMM(T)( T obj )
            if( is( T == class ) || is( T == interface ) )
        {
            auto cemm = cast(ExternalMemoryManager)obj;
            if( cemm ) childEMM ~= cemm; 
            return obj;
        }

        void destroy()
        {
            foreach( cemm; childEMM )
                cemm.destroy();
            selfDestroy();
        }
    }
}
