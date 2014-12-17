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

module des.util.stdext.traits;

public
{
    import std.traits;
    import std.typecons;
    import std.typetuple;
}

template hasAttrib(alias S,alias f)
{
    enum hasAttrib = impl!(__traits(getAttributes,f));

    template impl(Attr...)
    {
        static if( Attr.length == 0 )
        {
            version(tracehasattribimpl) pragma(msg, "empty: ",S,"->",Attr );
            enum impl=false;
        }
        else static if( Attr.length == 1 )
        {
            version(tracehasattribimpl) pragma(msg, "single: ",S,"->",Attr );
            static if( __traits(compiles,typeof(S)) &&
                       __traits(compiles,typeof(Attr[0])) )
            {
                version(tracehasattribimpl) pragma(msg, "  check as values: ",S,"==",Attr[0] );
                enum impl = Attr[0] == S;
            }
            else static if( __traits(compiles,is(Attr[0]==S)) )
            {
                version(tracehasattribimpl) pragma(msg, "  check as types: is(",S,"==",Attr[0],")" );
                enum impl = is( Attr[0] == S );
            }
            else
            {
                version(tracehasattribimpl) pragma(msg, "  no check: false" );
                enum impl = false;
            }
        }
        else
        {
            version(tracehasattribimpl)
            {
                pragma(msg, "many: ",S,"->",Attr );
                pragma(msg, "  p1: ",Attr[0..$/2] );
                pragma(msg, "  p2: ",Attr[$/2..$] );
            }
            enum impl = impl!(Attr[0..$/2]) || impl!(Attr[$/2..$]);
        }
    }
}

unittest
{
    enum clot;
    size_t zlot(string s){ return s.length; }

    void fnc1() @clot {}
    void fnc2() @clot @zlot("ok") {}
    void fnc3() @zlot("abc") {}

    static assert(  hasAttrib!(clot,fnc1) );
    static assert(  hasAttrib!(clot,fnc2) );
    static assert(  hasAttrib!(2,fnc2) );
    static assert( !hasAttrib!(clot,fnc3) );
    static assert(  hasAttrib!(3,fnc3) );
}

template isString(alias s) { enum isString = is( typeof(s) == string ); }

unittest
{
    static assert( isString!"hello" );
}

template staticFilter(alias F, T...)
{
    static if (T.length == 0)
    {
        alias staticFilter = TypeTuple!();
    }
    else static if (T.length == 1)
    {
        static if( F!(T[0]) )
            alias staticFilter = TypeTuple!(T[0]);
        else alias staticFilter = TypeTuple!();
    }
    else
    {
        alias staticFilter =
            TypeTuple!(
                staticFilter!(F, T[ 0  .. $/2]),
                staticFilter!(F, T[$/2 ..  $ ]));
    }
}

template filterMembers(alias F,T,List...)
if( ( is( T == class ) || is( T == struct ) ) && ( List.length == 0 || ( allSatisfy!(isString,List) ) ) )
{
    static if( List.length > 0 ) alias list = List;
    else alias list = TypeTuple!(__traits(allMembers,T));

    template trueMember(string n)
    {
        static if( __traits(compiles,__traits(getMember,T,n)) &&
                    F!(__traits(getMember,T,n)) )
            enum trueMember = true;
        else enum trueMember = false;
    }

    alias filterMembers = staticFilter!( trueMember, list );
}

template hasVoidReturnType(alias f)
{ enum hasVoidReturnType = is( ReturnType!f == void ); }

unittest
{
    enum mark;

    template isMarkedFunc(alias f)
    {
        enum isMarkedFunc = isCallable!f &&
             hasAttrib!(mark,f);
    }

    static class OC { }
    static struct OS { }

    static assert( [filterMembers!(isMarkedFunc,OC)] == [] );
    static assert( [filterMembers!(isMarkedFunc,OS)] == [] );

    static class A
    {
        void s1() @mark {}
        void f2() {}
        @mark
        {
            float s3() { return 3.14; }
            void s4( float x ) {}
        }
        void f5() {}
        @mark void s6() {}
    }

    enum A_exp = ["s1","s3","s4","s6"];

    static assert( [filterMembers!(isMarkedFunc,A)] == A_exp );

    static class B : A { void s7( string x ) @mark {} }

    enum B_rr = filterMembers!(isMarkedFunc,B);

    static assert( [B_rr] == ["s7"] ~ A_exp );

    enum B_void_rr = filterMembers!(hasVoidReturnType,B,B_rr);
    enum B_non_void_rr = filterMembers!(templateNot!hasVoidReturnType,B,B_rr);

    static assert( [B_void_rr] == ["s7", "s1", "s4", "s6"] );
    static assert( [B_non_void_rr] == ["s3"] );
}

struct TemplateVarDef( alias string N, Args... )
{
    alias name = N;
    alias Types = Args;
}

template isTemplateVarDef(T)
{
    enum isTemplateVarDef = is( typeof( impl(T.init) ) );
    void impl(alias string N, Args...)( TemplateVarDef!(N,Args) x ){}
}

unittest
{
    static assert( !isTemplateVarDef!float );
    static assert(  isTemplateVarDef!(TemplateVarDef!("hello", string, int)) );
}

mixin template DefineTemplateVars( alias Trg, List... )
{
    static if( List.length == 0 ) {}
    else static if( List.length == 1 )
    {
        static assert( isTemplateVarDef!(List[0]) );
        mixin( "Trg!(List[0].Types) " ~ List[0].name ~ ";" );
    }
    else
    {
        mixin DefineTemplateVars!(Trg,List[0..$/2]);
        mixin DefineTemplateVars!(Trg,List[$/2..$]);
    }
}

unittest
{
    import std.string;

    static struct X(Args...)
    {
        void func( Args args )
        {
            static if( Args.length == 1 && is( Args[0] == string ) )
                assert( args[0] == "hello" );
            else static if( Args.length == 2 && is( Args[0] == float ) && is( Args[1] == int ) )
            {
                import std.math;
                assert( abs(args[0] - 3.14) < float.epsilon );
                assert( args[1] == 12 );
            }
            else static assert(0,"undefined for this unittest");
        }
    }

    static class ZZ
    {
        mixin DefineTemplateVars!( X, TemplateVarDef!("ok",string),
                                      TemplateVarDef!("da",float,int),
                );
    }

    auto zz = new ZZ;
    static assert( is( typeof(zz.ok) == X!string ) );
    static assert( is( typeof(zz.da) == X!(float,int) ) );
    zz.ok.func( "hello" );
    zz.da.func( 3.14, 12 );
}

unittest
{
    enum mark;

    static class A
    {
        void s1() @mark {}
        void f2() {}
        @mark
        {
            void s3( int, string ) {}
            void s4( float x ) {}
        }
    }
    
    template isVoidMarkedFunc(alias f)
    {
        enum isVoidMarkedFunc = isCallable!f && is( ReturnType!f == void ) && hasAttrib!(mark,f);
    }

    template TemplateVarDefFromMethod(T)
    {
        template TemplateVarDefFromMethod(string name)
        {
            alias TemplateVarDefFromMethod = TemplateVarDef!(name,ParameterTypeTuple!(__traits(getMember,T,name)));
        }
    }

    alias tvd = staticMap!( TemplateVarDefFromMethod!A, filterMembers!(isVoidMarkedFunc,A) );
    static assert( tvd.length == 3 );
    alias exp = TypeTuple!( TemplateVarDef!("s1"), TemplateVarDef!("s3",int,string), TemplateVarDef!("s4",float) );
    static assert( is(tvd[0] == exp[0]) );
    static assert( is(tvd[1] == exp[1]) );
    static assert( is(tvd[2] == exp[2]) );
}

/++
using:

void func(T)( T v )
    if( isPseudoInterface(Interface,T) )
{
}
 +/
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
            static if( is( typeof( __traits(getMember, I, mem ) ) ) )
            {
                alias typeof( __traits(getMember, I, mem ) ) i;

                static if( !isCallable!i ) return true;

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

    assert( !isPseudoInterface!( B, C,false ) );
    assert(  isPseudoInterface!( iB, C,false ) );
}