Provides some functions to help unittesting.

`bool eq(A,B)( in A a, in B b );`

```d
unittest
{
    assert( eq(1,1.0) );
    assert( eq("hello","hello"w) );
}
```

for floating points in `eq` uses `bool eq_approx(A,B,E)( in A a, in B b, in E eps );`

`bool mustExcept(E=Exception)( void delegate() fnc, bool throwUnexpected=false )
    if( is( E : Throwable ) )`

```d
unittest
{
    assert( mustExcept!Exception( { throw new Exception("test"); } ) );
    assert( !mustExcept!Exception( { throw new Throwable("test"); } ) );
    assert( !mustExcept!Exception( { auto a = 4; } ) );
}
```
