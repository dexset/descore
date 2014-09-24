module desisys.neiro.layer.net;

import std.math;
import std.conv;
import std.range;
import std.traits;
import std.algorithm;

import desisys.neiro.neiron;
import desisys.neiro.func;

import desisys.neiro.layer.neiron;
import desisys.neiro.layer.structure;

version(unittest) import std.stdio;

interface NetProcessor(T)
    if( isFloatingPoint!T )
{
    void setStructure( NetStructure!T );
    T[] process( in T[] src );
}

class LearnNetProcessor(T) : NetProcessor!T
    if( isFloatingPoint!T )
{
package:

    NetStructure!T structure;

    @property
    {
        ValueNeiron!T[] input() { return structure.input; }
        BPLayer!T[] layers() { return structure.layers; }
        BPNeiron!T[] output() { return layers[$-1].neirons; }
    }

    T[] last_result;

    T _nu, _alpha;
    T last_error, last_delta;

public:

    this( T Nu=1, T Alpha=0.01 )
    in
    {
        assert( Nu > 0 );
        assert( Alpha > 0 );
    }
    body
    {
        _nu = Nu;
        _alpha = Alpha;
    }

    void setStructure( NetStructure!T structure )
    in { assert( structure !is null ); } body
    { this.structure = structure; }

    T[] process( in T[] src )
    {
        prepareInput( src );
        processForEachLayer();
        copyResult();

        return last_result;
    }

    @property
    {
        T nu() const { return _nu; }
        T nu( in T Nu )
        in { assert( Nu > 0 ); } body
        {
            _nu = Nu;
            return _nu;
        }

        T alpha() const { return _alpha; }
        T alpha( in T Alpha )
        in { assert( Alpha > 0 ); } body
        {
            _alpha = Alpha;
            return _alpha;
        }

        const(T)[] lastResult() const { return last_result; }
    }

    T learn( T[] src, T[] standard, uint steps )
    {
        last_delta = 1;

        foreach( k; 0 .. steps )
        {
            process( src );

            auto errors = calcErrors( standard );

            addErrorsToOutput( errors );

            last_error = calcErrorSum( errors );

            backpropagation( nu, alpha );

            last_delta = getMaxLinkDeltaWeight();
        }

        return last_error;
    }

protected:

    void prepareInput( in T[] src )
    {
        foreach( ref n, v; zip(input,src) )
            n.value = v;
    }

    void processForEachLayer() { foreach( l; layers ) l.process(); }

    void copyResult()
    {
        last_result.length = output.length;
        foreach( i; 0 .. output.length )
            last_result[i] = output[i].output;
    }

    auto calcErrors( in T[] standard )
    {
        auto ret = new T[](last_result.length);
        ret[] = standard[] - last_result[];
        return ret;
    }

    void addErrorsToOutput( in T[] errors )
    {
        foreach( n, e; zip(output, errors) )
            n.addError( e );
    }

    auto calcErrorSum( in T[] errors )
    { return reduce!((a,b)=>a+=b*b)(cast(T)0,errors) / 2.0; }

    void backpropagation( T nu, T alpha )
    {
        auto cnu = currentNu;
        foreach_reverse( layer; layers )
            layer.correct( cnu, alpha );
    }

    @property T currentNu() { return last_delta * last_error * nu; }

    T getMaxLinkDeltaWeight()
    {
        T maxd = 0;

        foreach( layer; layers )
            foreach( neiron; layer.neirons )
                foreach( link; neiron.bpLinks )
                    maxd = max( maxd, abs(link.deltaWeight) );

        return maxd;
    }
}

unittest
{
    auto nw = new class NetWeight!float
    { float opIndex(size_t,size_t,size_t) { return 1; } };

    auto calns = new ConsistentlyAssociatedLayereNetStructure!float(
                         new LinearDependence!float(2), [1,1], nw );

    auto lnp = new LearnNetProcessor!float( 1, 0.001 );
    lnp.setStructure( calns );

    assert( lnp.process( [1] ) == [2] );

    lnp.learn( [1], [1], 100 );
    auto r = lnp.process([1])[0];
    assert( r > 1 && r < 2 );
}
