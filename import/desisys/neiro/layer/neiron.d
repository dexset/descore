module desisys.neiro.layer.neiron;

import std.math;
import std.algorithm;
import std.traits;
import std.conv;

import desisys.neiro.neiron;
import desisys.neiro.func;

abstract class BPLink(T) : WeightLink!(T,T)
    if( isFloatingPoint!T )
{
    @property T deltaWeight() const;

    void propagateError(T);
    void correct(T,T);
}

interface BPNeiron(T) : Neiron!T
    if( isFloatingPoint!T )
{
    void addError(T);
    void correct(T,T);
    void setLinks( BPLink!T[] lnks );
    @property BPLink!T[] bpLinks();
}

abstract class FakeBPNeiron(T) : BPNeiron!T
    if( isFloatingPoint!T )
{
    void process() {}
    void addError(T) {}
    void correct(T,T) {}
    void setLinks( BPLink!T[] lnks ) {}
    @property BPLink!T[] bpLinks() { return []; }
}

class ReferenceBPNeiron(T) : FakeBPNeiron!T
    if( isFloatingPoint!T )
{
    Neiron!T neiron;
    this( Neiron!T neiron )
    in{ assert( neiron !is null ); } body
    { this.neiron = neiron; }
    @property T output() const { return neiron.output; }
}

class BaseBPLink(T) : BPLink!(T)
    if( isFloatingPoint!T )
{
protected:
    BPNeiron!T neiron;

    override @property T source() const { return neiron.output; }

    T lw, dw;

public:

    this( BPNeiron!T input, T w=1 )
    {
        neiron = input;
        lw = w;
        dw = 0;
    }

    override @property
    {
        T weight() const { return lw; }

        void weight( T nlw )
        {
            lw = nlw;
            dw = 0;
        }

        T deltaWeight() const { return dw; }
    }

    override void propagateError( T beta )
    { neiron.addError( beta * weight ); }

    // k1 = alpha; k2 = (1-alpha) * nu * beta
    override void correct( T k1, T k2 ) 
    {
        dw = dw * k1 + k2 * source;
        lw += dw;
    }
}

class BaseBPNeiron(T) : BaseNeiron!T, BPNeiron!T
    if( isFloatingPoint!T )
{
protected:

    T error = 0;

    T link_scale = 1;

    DerivativeFunction!T func;
    BPLink!T[] bp_links;

    override T activate( T x ) { return func( x * link_scale ); }

    override @property Link!T[] links()
    { return to!(Link!T[])(bp_links); }

public:

    this( DerivativeFunction!T func )
    in { assert( func !is null ); } body
    {
        super(0);
        this.func = func;
    }

    void setLinks( BPLink!T[] lnks )
    {
        bp_links = lnks;
        link_scale = 1.0 / cast(T)bp_links.length;
    }

    void addError( T err ) { error += err; }

    void correct( T nu, T alpha )
    {
        backpropagation( nu, alpha );
        eliminateStagnation();
        resetError();
    }

    @property BPLink!T[] bpLinks() { return bp_links; }

protected:
    void backpropagation( T nu, T alpha )
    {
        T beta = func.dx( value ) * error;
        T k2 = ( 1.0 - alpha ) * nu * beta;

        foreach( link; bp_links )
        {
            link.propagateError( beta * link_scale );
            link.correct( alpha, k2 );
        }
    }

    void eliminateStagnation() { }

    void resetError() { error = 0; }
}

unittest
{
    import std.typecons;

    auto input = new ValueNeiron!float(1);
    auto link = new BaseBPLink!float( new ReferenceBPNeiron!float(input), 0.25 );
    auto neiron = new BaseBPNeiron!float( new LinearDependence!float(2) );
    neiron.setLinks( [ cast(BPLink!float)link ] );
    neiron.process();
    assert( neiron.output == 0.5 );
}
