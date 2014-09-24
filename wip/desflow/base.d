module desflow.base;

import std.datetime;

class FlowException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

enum Command { START, PAUSE, STOP, REINIT, CLOSE };

@property ulong currentTick()
{ return Clock.currAppTick().length; }

package
{

    import std.stdio;
    import std.string;

    nothrow void log_error(string file=__FILE__,
                   string modname=__MODULE__,
                   size_t line=__LINE__, Args...)(Args args)
    {
        try stderr.writeln( "%s:%d %s", file, line, format( args ) );
        catch( Exception e )
        {
            try stderr.writeln( "FATAL LOG: wrong format" );
            catch( Exception e ){}
        }
    }

    version(unittest)
    {
        import std.math;
        import std.traits;
        import std.range;

        pure bool eq(A,B)( in A a, in B b )
        {
            static if( isFloatingPoint!A && isFloatingPoint!B )
                return (abs(a-b) < max( A.epsilon, B.epsilon ));
            else return a == b;
        }

        pure bool eq_arr(A,B)( in A[] a, in B[] b )
        {
            if( a.length != b.length ) return false;
            foreach( i,j; zip(a,b) )
                if( !eq(i,j) ) return false;
            return true;
        }

        bool creationTest(T)( T a )
            if( is( Unqual!T == T ) )
        {
            auto cn_a = const T( a );
            auto im_a = immutable T( a );
            auto sh_a = shared T( a );
            auto sc_a = shared const T( a );
            auto si_a = shared immutable T( a );
            auto a_cn = T( cn_a );
            auto a_im = T( im_a );
            auto a_sh = T( sh_a );
            auto a_sc = T( sc_a );
            auto a_si = T( si_a );
            return a_cn == a &&
                   a_im == a &&
                   a_sh == a &&
                   a_sc == a &&
                   a_si == a;
        }
    }
}

