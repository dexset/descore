module desneiro.layer.rand;

public import std.random;
import std.traits;
import std.math;

T symmetry_uniform(T)( T lim ) 
    if( isNumeric!T )
{ return uniform( -lim, lim ); }

auto gap_symmetry_uniform(T,G)( T lim, G gap )
    if( isNumeric!T && isNumeric!G )
{
    auto u = symmetry_uniform( lim );
    return u + gap * sgn(u);
}

import desneiro.layer.neiron;
import desneiro.layer.structure;

void rndLayers(T)( BPLayer!T[] layers )
{ foreach( layer; layers ) rndLayer(layer); }

void rndLayer(T)( BPLayer!T layer )
{
    foreach( neiron; layer.neirons )
        rndLinkedNeiron( neiron );
}

void rndLinkedNeiron(T)( BPNeiron!T neiron )
{
    foreach( link; neiron.bpLinks )
        rndLink( link );
}

void rndLink(T,L=float,G=float)( BPLink!T link, L lim=0.2, G gap=0.1 )
    if( isFloatingPoint!L && isFloatingPoint!G )
{ link.weight = gap_symmetry_uniform( lim, gap ); }
