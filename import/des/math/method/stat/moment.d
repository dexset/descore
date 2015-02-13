module des.math.method.stat.moment;

/// expected value
T mean(T)( in T[] arr ) pure nothrow @property @nogc
if( is( typeof( T.init + T.init ) == T ) && is( typeof( T.init / 1UL ) == T ) )
in { assert( arr.length > 0 ); } body
{
    if( arr.length == 1 ) return arr[0];
    T res = arr[0];
    foreach( i; 1 .. arr.length )
        res = res + arr[i];
    return res / arr.length;
}

///
unittest
{
    auto a = [ 1.0f, 2, 3 ];
    assert( a.mean == 2.0f );

    static assert( !__traits(compiles,[1,2,3].mean) );
    static assert(  __traits(compiles,[1.0f,2,3].mean) );
}

///
unittest
{
    import des.math.linear.vector;

    auto a = [ vec3(1,2,3), vec3(2,3,4), vec3(3,4,5) ];
    assert( a.mean == vec3(2,3,4) );
}

///
T variance(T)( in T[] arr ) pure nothrow @property @nogc
if( is( typeof( T.init + T.init ) == T ) &&
    is( typeof( T.init - T.init ) == T ) &&
    is( typeof( T.init * T.init ) == T ) &&
    is( typeof( T.init / 1UL ) == T ) )
in { assert( arr.length > 1 ); } body
{
    T res = arr[0] - arr[0];
    auto m = arr.mean;
    foreach( val; arr )
        res = res + ( m - val ) * ( m - val );
    return res / ( arr.length - 1 );
}

///
unittest
{
    auto a = [ 1.0f, 1, 1 ];
    assert( a.variance == 0.0f );

    auto b = [ 1.0f, 2, 3 ];
    assert( b.variance == 1.0f );
}

///
unittest
{
    import des.math.linear.vector;

    auto a = [ vec3(1,2,3), vec3(2,3,4), vec3(3,4,5) ];
    assert( a.variance == vec3(1,1,1) );
}

/++ returns:
    mean (0 element), variance (1 element)
+/
T[2] mean_variance(T)( in T[] arr ) pure nothrow @property @nogc
if( is( typeof( T.init + T.init ) == T ) &&
    is( typeof( T.init - T.init ) == T ) &&
    is( typeof( T.init * T.init ) == T ) &&
    is( typeof( T.init / 1UL ) == T ) )
in { assert( arr.length > 1 ); } body
{
    T res = arr[0] - arr[0];
    auto m = arr.mean;
    foreach( val; arr )
        res = res + ( m - val ) * ( m - val );
    return [ m, res / ( arr.length - 1 ) ];
}

///
unittest
{
    auto a = [ 1.0f, 1, 1 ];
    assert( a.mean_variance == [ 1.0f, 0.0f ] );

    auto b = [ 1.0f, 2, 3 ];
    assert( b.mean_variance == [ 2.0f, 1.0f ] );
}

///
unittest
{
    import des.math.linear.vector;

    auto a = [ vec3(1,2,3), vec3(2,3,4), vec3(3,4,5) ];
    assert( a.mean_variance == [ vec3(2,3,4), vec3(1,1,1) ] );
}

///
T rawMoment(T)( in T[] arr, size_t k=1 ) pure nothrow @property @nogc
if( is( typeof( T.init + T.init ) == T ) &&
    is( typeof( T.init * T.init ) == T ) &&
    is( typeof( T.init / T.init ) == T ) &&
    is( typeof( T.init / 1UL ) == T ) )
in { assert( arr.length > 0 ); } body
{
    if( arr.length == 1 ) return spow( arr[0], k );
    T res = arr[0];
    foreach( i; 1 .. arr.length )
        res = res + spow( arr[i], k );
    return res / arr.length;
}

///
unittest
{
    auto a = [ 1.0f, 2 ];
    assert( a.rawMoment == 1.5 );
    assert( a.rawMoment(2) == 2.5 );
}

///
T spow(T)( in T val, size_t k ) pure nothrow @nogc
if( is( typeof( T.init / T.init ) == T ) && is( typeof( T.init * T.init ) == T ) )
{
    //TODO: optimize
    T ret = val / val;
    if( k == 0 ) return ret;
    if( k == 1 ) return val;
    if( k == 2 ) return val * val;
    foreach( i; 0 .. k ) ret = ret * val;
    return ret;
}

///
unittest
{
    import des.math.linear.vector;
    assert( spow( vec3( 1, 2, 3 ), 3 ) == vec3( 1, 8, 27 ) );
    assert( spow( 10, 0 ) == 1 );
    assert( spow( 10, 1 ) == 10 );
    assert( spow( 10, 2 ) == 100 );
    assert( spow( 10, 3 ) == 1000 );
    assert( spow( 10, 4 ) == 10000 );
}

///
T centralMoment(T)( in T[] arr, size_t k=1 ) pure nothrow @property @nogc
if( is( typeof( T.init + T.init ) == T ) &&
    is( typeof( T.init * T.init ) == T ) &&
    is( typeof( T.init / T.init ) == T ) &&
    is( typeof( T.init / 1UL ) == T ) )
in { assert( arr.length > 0 ); } body
{
    T res = arr[0] - arr[0];
    auto m = arr.mean;
    foreach( val; arr )
        res = res + spow( val - m, k );
    return res / arr.length;
}

///
unittest
{
    auto a = [ 1.0f, 2, 3, 4 ];
    assert( a.centralMoment(1) == 0 );
    assert( a.centralMoment(2) == 1.25 );
    assert( a.centralMoment(3) == 0 );
}
