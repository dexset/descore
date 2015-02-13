module des.isys.neiro.func;

import std.math;

import des.isys.neiro.traits;

interface Function(X,Y) { Y opCall( X x ) const; }

class HeavisideFunction(X,Y) : Function!(X,Y)
    if( canComparison!X )
{
    Y a, b;
    X lim;

    this( Y a, Y b, X lim )
    {
        this.a = a;
        this.b = b;
        this.lim = lim;
    }

    Y opCall( X x ) const { return x < lim ? a : b; }
}

class HeavisideMeanFunction(X,Y) : HeavisideFunction!(X,Y)
    if( canFindMean!Y )
{
    this( Y a, Y b, X lim ) { super(a,b,lim); }
    override Y opCall( X x ) const
    {
        if( x == lim ) return ( a + b ) / 2;
        return super.opCall(x);
    }
}

unittest
{
    auto H = new HeavisideFunction!(float,float)(0,1,0);
    assert( H(0) == 1 );
    assert( H(1) == 1 );
    assert( H(-1) == 0 );
    auto HM = new HeavisideMeanFunction!(float,float)(-1,1,0);
    assert( HM(0) == 0 );
    assert( HM(10) == 1 );
    assert( HM(-2) == -1 );
}

interface DerivativeFunction(T) : Function!(T,T)
    if( isFloatingPoint!T )
{ T dx( T x ) const; }

class LinearDependence(T) : DerivativeFunction!T
    if( isFloatingPoint!T )
{
    T k;
    this( T k=1 ) { this.k = k; }
    T opCall( T x ) const { return x * k; }
    T dx( T x ) const { return k; };
}

unittest
{
    auto ld = new LinearDependence!float(2);
    assert( ld(1) == 2 );
    assert( ld(2) == 4 );
}

/+ f -> (0,1) +/
class ExponentialSigmoid(T) : DerivativeFunction!T
    if( isFloatingPoint!T )
{
    T alpha;
    this( T alpha=1.0 ) { this.alpha = alpha; }

    const
    {
        T opCall( T x )
        { return 1.0 / ( 1.0 + pow( E, -alpha * x ) ); }

        T dx( T x )
        {
            auto eax = pow( E, alpha * x );
            return alpha * eax / ( ( eax + 1 )^^2 );
        }
    }
}

unittest
{
    auto fes = new ExponentialSigmoid!float;
    assert( fes(0) == .5 );
}

/+ f -> (-1,1) +/
class RationalSigmoid(T) : DerivativeFunction!T
    if( isFloatingPoint!T )
{
    T alpha;
    this( T alpha=1.0 ) { this.alpha = alpha; }

    const
    {
        T opCall( T x )
        { return x / ( abs(x) + alpha ); }

        T dx( T x )
        {
            auto aax = alpha + abs(x);
            return alpha / ( ( abs(x) + alpha )^^2 );
        }
    }
}

unittest
{
    auto frs = new RationalSigmoid!float;
    assert( frs(0) == 0 );
}

/+ f -> (-pi/2,pi/2) +/
class AtanSigmoid(T) : DerivativeFunction!T
    if( isFloatingPoint!T )
{
    const
    {
        T opCall( T x ) { return atan(x); }
        T dx( T x ) { return 1.0 / ( x*x + 1.0 ); }
    }
}

unittest
{
    auto fas = new AtanSigmoid!float;
    assert( fas(0) == 0 );
}
