/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

/+
using:

void func(T)( T v )
    if( isPseudoInterface(Interface,T) )
{
}

 +/
module desutil.pseudointerface;

import std.traits;

bool isPseudoInterface(I,T, bool _assert=true, string FILE=__FILE__, int LINE=__LINE__ )()
{ 
    import std.string;
    import std.conv;
    bool fail(Args...)( string fmt, Args args )
    {
        if( _assert ) assert( 0, FILE ~ "(" ~ to!string(LINE) ~ ") " ~ format( fmt, args ) );
        else return false;
    }
    bool checkMembers( I, T, mem... )()
    {
        static if( is(typeof(mem[0]) == string ) && mem.length > 1 ) 
            return checkMembers!(I,T,mem[0])() && checkMembers!(I,T,mem[1 .. $])();
        else
        {
            // существует ли тип поля mem в I
            static if( is( typeof( __traits(getMember, I, mem ) ) ) )
            {
                alias typeof( __traits(getMember, I, mem ) ) i;

                // если поле "интерфейса" не вызываемое
                static if( !isCallable!i ) return true;

                // найден ли искомый метод в T
                static if( __traits(compiles, __traits(getMember, T, mem) ) )
                {
                    alias typeof(__traits(getMember, T, mem )) t;

                    static if( !isCallable!t ) 
                        return fail( "member %s in class %s is not cllable", mem, T.stringof );
                    else
                    static if( !is( ReturnType!i == ReturnType!t ) ) 
                        return fail( "return type of %s in %s must be %s (not %s)", 
                                        mem, typeid(T), typeid(ReturnType!i), typeid(ReturnType!t) );
                    else
                    static if( !is( ParameterTypeTuple!i == ParameterTypeTuple!t ) ) 
                        return fail( "parameter type tuple of %s in %s must be %s (not %s)",
                                mem, typeid(T), typeid(ParameterTypeTuple!i), typeid(ParameterTypeTuple!t) );
                    else
                    static if( [ParameterStorageClassTuple!i] != [ParameterStorageClassTuple!t] ) 
                        return fail( "parameter storage class tuple of %s in %s must be %s (not %s)", 
                                mem, typeid(T), to!string(ParameterStorageClassTuple!i),
                                to!string(ParameterStorageClassTuple!t) );
                    else
                        return true;
                }
                else return fail( "member %s not found in class %s", mem, typeid(T) );
            }
            else return true;
        }
    }
    return checkMembers!(I,T,__traits(allMembers,I))(); 
}

unittest
{
    interface IFace
    {
        void func1( int );
        size_t func2( string );
    }

    struct Afunc1 { void opCall( int ){} }
    struct Afunc2 { size_t opCall( string ){ return 0; } }

    class A
    {
        Afunc1 func1;
        Afunc2 func2;
    }

    struct B
    {
        void func1( int ) { }
        size_t func2( string str ) { return 0; }
    }

    class C
    {
        void func1( int ) { }
        size_t func2( string str ) { return 0; }
    }

    class D: A
    {
        void func1( int ) { }
        size_t func2( string str ) { return 0; }
    }

    class E
    {
        int func1;
        size_t func2( string str ){ return 0; }
    }

    class F
    {
        void func1() { }
        size_t func2( string str ){ return 0; }
    }

    class G
    {
        void func1( in int ){}
        size_t func2( string str ){ return 0; }
    }

    static assert(  isPseudoInterface!( IFace,A,false ) );
    static assert(  isPseudoInterface!( IFace,B,false ) );
    static assert(  isPseudoInterface!( IFace,C,false ) );
    static assert(  isPseudoInterface!( IFace,D,false ) );

    static assert(  isPseudoInterface!(A,C,false) );

    static assert( !isPseudoInterface!( IFace,E,false ) );
    static assert( !isPseudoInterface!( IFace,F,false ) );
    static assert( !isPseudoInterface!( IFace,G,false ) );
}

unittest
{
    interface A
    {
        void func1( int );
    }

    class B : A
    {
        void func1( int ) {}
        int func2( string ){ return 0; }
    }

    struct Cfunc1 { void opCall( int ) { } }

    interface iB: A
    {
        int func2( string );
    }

    struct C
    {
        Cfunc1 func1;
        int func2( string ){ return 0; }
    }

    // функции базового Object тоже учитываются
    assert( !isPseudoInterface!( B, C,false ) );

    assert( isPseudoInterface!( iB, C,false ) );
}
