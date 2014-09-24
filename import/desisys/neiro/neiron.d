module desisys.neiro.neiron;

import std.algorithm;

import desisys.neiro.traits;

interface Neiron(T)
{
    @property T output() const;
    void process();
}

abstract class FakeNeiron(T) : Neiron!T
{ void process(){} }

class ValueNeiron(T) : FakeNeiron!T
{
    T value;
    this( T value ) { this.value = value; }
    @property T output() const { return value; }
}

class ReferenceNeiron(T) : FakeNeiron!T
{
    Neiron!T neiron;
    this( Neiron!T neiron )
    in{ assert( neiron !is null ); } body
    { this.neiron = neiron; }
    @property T output() const { return neiron.output; }
}

unittest
{
    auto vn = new ValueNeiron!float(3.1415);
    auto rn = new ReferenceNeiron!float( vn );
    import std.math;
    assert( abs(rn.output - 3.1415) < float.epsilon*2 );
}

class FunctionNeiron(T) : FakeNeiron!T
{
    T delegate() func;
    this( T delegate() func )
    in{ assert( func !is null ); } body
    { this.func = func; }
    @property T output() const { return func(); }
}

interface Link(T) { @property T value(); }

abstract class BaseNeiron(T) : Neiron!T
    if( canSummate!T )
{
protected:
    T value;

    abstract T activate( T );
    abstract @property Link!T[] links();

public:

    this( T initial = T.init )
    { value = initial; }

    final @property T output() const { return value; }

    void process()
    { value = activate( reduce!((s,v)=>s+v)( map!"a.value"(links) ) ); }
}

version(unittest)
{
    private
    {
        import std.conv;
        class TestNeiron : BaseNeiron!float
        {
        protected:

            override float activate( float x ) { return x * coef; }
            override @property Link!float[] links() { return _links; }
            Link!float[] _links;
            float coef;
        public:
            this( float ac, Link!float[] lnks ) { coef = ac; _links = lnks; }
        }
    }
}

unittest
{
    static class TestLink : Link!float
    { @property float value() { return 1; } }

    TestLink[] buf;
    foreach( i; 0 .. 10 ) buf ~= new TestLink;

    auto tn = new TestNeiron( .25, to!(Link!float[])(buf) );

    tn.process();
    assert( tn.output == 2.5 );
}

abstract class WeightLink(T,N) : Link!T
    if( canMultiplicate!(T,N) )
{
    @property 
    {
        abstract protected T source() const;

        abstract N weight() const;
        abstract void weight( N );

        final T value() { return source * weight; }
    }
}

unittest
{
    static class TestLink : WeightLink!(float,float)
    {
        float w;
        override @property
        {
            protected float source() const { return 1; }

            float weight() const { return w; }
            void weight( float nw ) { w = nw; }
        }

        this( float W ) { w = W; }
    }

    TestLink[] buf;
    foreach( i; 0 .. 10 ) buf ~= new TestLink( 0.25 );

    auto tn = new TestNeiron( 1, to!(Link!float[])(buf) );

    tn.process();
    assert( tn.output == 2.5 );

}
