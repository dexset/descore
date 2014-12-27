module des.math.combin;

/++ factorial +/
long fact( long a ) pure nothrow
in { assert( a >= 0 ); }
out(res) { assert( res >= 0 ); }
body
{
    if( a <= 2 ) return a;
    return a * fact(a-1);
}

unittest
{
    assert( fact(0) == 0 );
    assert( fact(1) == 1 );
    assert( fact(2) == 2 );
    assert( fact(3) == 6 );
    assert( fact(4) == 24 );
    assert( fact(5) == 120 );
}

/++ equals to fact(n) / ( fact(k) * fact( n-k ) ) +/
long combination( long n, long k ) pure nothrow
in
{
    assert( k > 0 );
    assert( n >= 0 );
}
out(res) { assert( res >= 0 ); }
body
{
    if( k == 1 || k == n-1 ) return n;
    long a = n * (n-1);
    long b = k;

    foreach( i; 2 .. k )
    {
        a *= (n-i);
        b *= i;
    }

    return a / b;
}

unittest
{
    static pure nothrow long comb2( long n, long k )
    { return fact(n) / ( fact(k) * fact( n-k ) ); }

    foreach( k; 1 .. 10 )
        assert( combination(10,k) == comb2(10,k) );
}

/++ equals to fact(n) / fact(n-k) +/
pure nothrow long partial_permutation( long n, long k )
in
{
    assert( k > 0 );
    assert( n >= k );
}
out(res) { assert( res >= 0 ); }
body
{
    if( k == 1 ) return n;

    long res = n * (n-1);

    foreach( i; 2 .. k )
        res *= (n-i);

    return res;
}

unittest
{
    static pure nothrow long perm2( long n, long k )
    { return fact(n) / fact( n-k ); }

    foreach( k; 1 .. 10 )
        assert( partial_permutation(10,k) == perm2(10,k) );
}
