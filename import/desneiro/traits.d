module desneiro.traits;

public import std.traits;

pure nothrow
{
    bool canSummate(T)()
    { return is( typeof( T.init + T.init ) == T ); }

    bool canMultiplicate(T,N)()
    { return is( typeof( T.init * N.init ) == T ); }

    bool canFindMean(T)()
    { return is( typeof( (T.init + T.init) / 2.0 ) : T ); }

    bool canComparison(T)()
    { return is( typeof( T.init > T.init ) == bool ) &&
             is( typeof( T.init == T.init ) == bool ); }
}

unittest
{
    assert( canSummate!int );
    assert( canSummate!float );
    assert( canMultiplicate!(float,int) );
}

unittest
{
    assert( !canFindMean!int );
    assert( canFindMean!float );
}

unittest
{
    assert( canComparison!int );
    assert( canComparison!float );
}
