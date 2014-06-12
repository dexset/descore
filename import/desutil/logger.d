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

module desutil.logger;

enum : ubyte { DEBUG=1, UTEST=2, VERBOSE=4 };
enum logLevel { ERROR=1, INFO=3, TRACE=5 };

struct logAccess
{
    ubyte mask = VERBOSE;
    logLevel level = logLevel.TRACE;

    nothrow
    {
        pure
        {
            void set( ubyte m, logLevel l ) { mask = m; level = l; }

            this( ubyte m, logLevel l ) { set( m, l ); }
            this( in logAccess b ) { set( b.mask, b.level ); }
            auto opAssign( in logAccess b ) { set( b.mask, b.level ); return this; }
        }
        bool check( in logAccess b ) const
        { return ( b.mask & mask ) && b.level <= level; }

        bool check( in logMessage m ) const
        { return check( m.access ); }
    }
}

struct logMessage
{
    logAccess access;
    string emitter;
    string msg;

    nothrow
    {
        pure
        {
            void set( in logAccess ac, string message, string em )
            {
                access = ac;
                msg = message;
                emitter = em;
            }

            this( ubyte mask, logLevel level, string message, string em="" )
            { set( logAccess(mask,level), message, em ); }
            this( in logAccess ac, string message, string em="" ) { set( ac, message, em ); }
            this( in logMessage lm ) { set( lm.access, lm.msg, lm.emitter ); }
            this( in logMessage lm, string emadd ) 
            { set( lm.access, lm.msg, emadd ~ '.' ~ lm.emitter ); }
            auto opAssign( in logMessage lm )
            { set( lm.access, lm.msg, lm.emitter ); return this; }
        }
    }
}

unittest
{
    logAccess[3] test;
    test[0] = logAccess( DEBUG | VERBOSE, logLevel.INFO );
    test[1] = logAccess( VERBOSE, logLevel.ERROR );
    test[2] = logAccess( DEBUG | UTEST, logLevel.TRACE );

    bool[3][9] res;
    logAccess[9] var;

    var[0] = logAccess( DEBUG, logLevel.ERROR );   res[0] = [ 1, 0, 1 ];
    var[1] = logAccess( DEBUG, logLevel.INFO );    res[1] = [ 1, 0, 1 ];
    var[2] = logAccess( DEBUG, logLevel.TRACE );   res[2] = [ 0, 0, 1 ];

    var[3] = logAccess( UTEST, logLevel.ERROR );   res[3] = [ 0, 0, 1 ];
    var[4] = logAccess( UTEST, logLevel.INFO );    res[4] = [ 0, 0, 1 ];
    var[5] = logAccess( UTEST, logLevel.TRACE );   res[5] = [ 0, 0, 1 ];

    var[6] = logAccess( VERBOSE, logLevel.ERROR ); res[6] = [ 1, 1, 0 ];
    var[7] = logAccess( VERBOSE, logLevel.INFO );  res[7] = [ 1, 0, 0 ];
    var[8] = logAccess( VERBOSE, logLevel.TRACE ); res[8] = [ 0, 0, 0 ];

    foreach( i, v; var )
        foreach( j, t; test )
            assert( t.check(v) == res[i][j] );
}

unittest
{
    auto msg = logMessage( DEBUG, logLevel.ERROR, "hello.emitter", "Hello world!" );
    auto test = logAccess( DEBUG | VERBOSE, logLevel.INFO );
    assert( test.check(msg) );
}

import std.string;

abstract class Logger
{
protected:

    string name;
    logAccess filter;

    logAccess[string] named_filter;

    Logger[string] childs;
    Logger[] output;

public:

    void setFilter( in logAccess flt, string chname = "" )
    {
        if( chname.length )
        {
            auto namepath = chname.split(".");

            if( namepath[0] in childs )
                childs[namepath[0]].setFilter( flt, namepath[1 .. $].join(".") );
            else
                named_filter[chname] = flt;
        }
        else filter = flt;
    }

    bool log( in logMessage msg )
    {
        if( !filter.check(msg) ) return false;

        if( msg.emitter in named_filter )
        {
            auto nfilter = named_filter[msg.emitter];

            auto namepath = msg.emitter.split("."); 
            if( namepath[0] in childs )
            {
                childs[namepath[0]].setFilter( nfilter, namepath[1 .. $].join(".") );
                named_filter.remove( msg.emitter );
            }

            if( !nfilter.check(msg) ) return false;
        }

        foreach( ol; output )
            ol.log( logMessage( msg, name ) );

        return true;
    }
}

final class StdErrLogger: Logger
{
    this() { name = "stderr"; }

    this( in logAccess la )
    {
        this();
        filter = la;
    }

    override bool log( in logMessage msg )
    {
        import std.stdio;
        if( super.log( msg ) )
        {
            try stderr.writefln( "[ %5s ] [ %25s ] %s", msg.access.level, msg.emitter, msg.msg );
            catch( Exception e ){}
            return true;
        }
        return false;
    }
}

//mixin template PrivateLogger()
pure @property string PrivateLoggerMixin()
{
    return `
    private
    {
        StdErrLogger __logger;
        immutable string __emitter;
        static this()
        {
            import core.runtime, std.getopt;
            import std.stdio;
            import std.file;

            auto args = thisExePath ~ Runtime.args;
            logLevel lv = logLevel.ERROR;
            string[] without;
            string[] withonly;
            
            try
            {
            getopt( args, 
                "log-level", &lv,
                "log-without", &without,
                "log-withonly", &withonly
                );
            }
            catch( Exception e ) stderr.writefln( "bad log arguments: %s", e.msg );

            logLevel ctlv = logLevel.ERROR;

            debug(1) ctlv = logLevel.ERROR;
            debug(3) ctlv = logLevel.INFO;
            debug(5) ctlv = logLevel.TRACE;

            if( ctlv < lv )
                stderr.writefln( "WARNING: log level %s is greather that debug level %s", lv, ctlv );

            ubyte mask = DEBUG | UTEST | VERBOSE;

            import std.traits, std.algorithm, std.string;
            __emitter = fullyQualifiedName!__emitter;
            __emitter = __emitter.split(".")[0 .. $-1].join(".");
            foreach( wo; without )
                if( __emitter.startsWith(wo) )
                {
                    mask = 0;
                    break;
                }

            if( withonly.length )
            {
                mask = 0;
                foreach( wo; withonly )
                    if( __emitter == wo )
                    {
                        mask = DEBUG | UTEST | VERBOSE;
                        break;
                    }
            }

            __logger = new StdErrLogger( logAccess( mask, lv ) );
        }

        nothrow void __log(T...)( logLevel level, string fmt, T args )
        {
            import std.string : format;
            try __logger.log( logMessage( VERBOSE, level, format( fmt, args ), __emitter ) );
            catch( Exception e ) {}
        }

        nothrow void log(T...)( string fmt, T args ) { __log( logLevel.TRACE, fmt, args ); }
        nothrow void log_info(T...)( string fmt, T args ) { __log( logLevel.INFO, fmt, args ); }
        nothrow void log_error(T...)( string fmt, T args ) { __log( logLevel.ERROR, fmt, args ); }
    }`;
}
