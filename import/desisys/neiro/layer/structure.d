module desisys.neiro.layer.structure;

import std.traits;
import std.conv;

import desisys.neiro.func;
import desisys.neiro.neiron;
import desisys.neiro.layer.neiron;

class BPLayer(T) if( isFloatingPoint!T )
{
package:
    BPNeiron!T[] neirons;
public:
    this( BPNeiron!T[] nn ) { neirons = nn; }

    void process() { foreach( n; neirons ) n.process(); }

    void correct( T nu, T alpha )
    {
        foreach( neiron; neirons )
            neiron.correct( nu, alpha );
    }
}

interface NetStructure(T)
    if( isFloatingPoint!T )
{
    @property
    {
        ValueNeiron!T[] input();
        BPLayer!T[] layers();
    }
}

interface NetWeight(T)
    if( isFloatingPoint!T )
{ T opIndex( size_t layer, size_t left, size_t right ); }

class RandomWeight(T) : NetWeight!T
{
    import desisys.neiro.layer.rand;
    T lim, gap;

    this( T lim=0.2, T gap=0.1 )
    {
        this.lim = lim;
        this.gap = gap;
    }

    T opIndex( size_t layer, size_t input, size_t neiron )
    { return gap_symmetry_uniform(lim,gap); }
}

/++
ConsistentlyAssociatedLayereNetStructure

input neiron set(ins) + unitary neiron(un) -> first layer (L1)
    ins + un + L1 -> L2
    ins + un + L1 + L2 -> L3
    ins + un + L1 + L2 + L3 -> output

+/

class ConsistentlyAssociatedLayereNetStructure(T) : NetStructure!T
    if( isFloatingPoint!T )
{
protected:

    ValueNeiron!T[] in_neirons;
    BPNeiron!T[] neirons;
    BPLayer!T[] net_layers;
    DerivativeFunction!T func;

public:

    this( DerivativeFunction!T func, size_t[] sizes, NetWeight!T weight=null )
    in
    {
        assert( func !is null );
        assert( sizes.length > 1 );
    }
    body
    {
        this.func = func;

        addUnitaryNeiron();
        addInputNeirons( sizes[0] );
        if( weight is null ) weight = new RandomWeight!T;
        addLayers( sizes[1..$], weight );
    }

    @property
    {
        ValueNeiron!T[] input() { return in_neirons; }
        BPLayer!T[] layers() { return net_layers; }
    }

protected:

    void addUnitaryNeiron() { neirons ~= new ReferenceBPNeiron!T( new ValueNeiron!T(1) ); }

    void addInputNeirons( size_t count )
    {
        foreach( i; 0 .. count )
        {
            auto buf = new ValueNeiron!T(0);
            in_neirons ~= buf;
            neirons ~= new ReferenceBPNeiron!T(buf);
        }
    }

    void addLayers( size_t[] net_struct, NetWeight!T weight )
    {
        foreach( i; 0 .. net_struct.length )
            addLayer( net_struct[i], (size_t j, size_t k){ return weight[i,j,k]; } );
    }

    void addLayer( size_t size, T delegate(size_t, size_t) weight )
    {
        auto ln = createNeirons( size );

        linkNeirons( ln, neirons, weight );

        auto nln = to!(BPNeiron!T[])(ln);

        neirons ~= nln;
        net_layers ~= new BPLayer!T( nln );
    }

    auto createNeirons( size_t count )
    {
        auto ret = new BaseBPNeiron!T[](count);
        ret[] = new BaseBPNeiron!T(func);
        return to!(BPNeiron!T[])(ret);
    }

    /+ function weight(a,b) must return weight of link from input neiron lnk[a] to neiron ns[b] +/
    void linkNeirons( BPNeiron!T[] ns, BPNeiron!T[] lnk, T delegate(size_t,size_t) weight )
    in { assert( weight !is null ); } body
    { foreach( i, n; ns ) n.setLinks( createLinks( lnk, (size_t j){ return weight(j,i); } ) ); }

    BPLink!T[] createLinks( BPNeiron!T[] inn, T delegate(size_t) weight )
    in { assert( weight !is null ); } body
    {
        auto links = new BaseBPLink!T[](inn.length);
        foreach( j; 0 .. inn.length )
            links[j] = new BaseBPLink!T( inn[j], weight(j) );
        return to!(BPLink!T[])( links );
    }
}

unittest
{
    auto nw = new class NetWeight!float
    { float opIndex(size_t,size_t,size_t) { return 1; } };

    auto calns = new ConsistentlyAssociatedLayereNetStructure!float(
                         new LinearDependence!float(2), [1,1], nw );

    calns.input[0].value = 1;
    calns.layers[0].process();

    assert( calns.layers[0].neirons[0].output == 2 );
}
