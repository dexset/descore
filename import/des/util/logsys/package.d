/++
Package provides static `Logger logger`

Logger functions:

    void logger.error(Args...)( Args args );
    void logger.warn (Args...)( Args args );
    void logger.info (Args...)( Args args );
    void logger.Debug(Args...)( Args args );
    void logger.trace(Args...)( Args args );

    ...
    logger.info( "format %s %f %d", "str", 3.14, 4 );
    logger.Debug( "some info" );
    logger.trace( 12 );
    ...

If program starts as `./program --log trace` output must be like this

    [000000.111427128][ INFO][module.function]: format str 3.14 4
    [000000.111427128][DEBUG][module.function]: some info
    [000000.111938579][TRACE][module.function]: 12

If log function has string as first argument it tries to format other args to this
string, if it failed print converted to string and concatenated args.

If program starts as `./program --log debug` output must be like this (without trace)

    [000000.111427128][ INFO][module.function]: format str 3.14 4

Flag `--log` used for setting max level of logging output.
Default level is `error`. If log function called with greater level it's skipped.
Level has attitudes `off < fatal < error < warn < info < debug < trace`.

Flag `--log` can be used with module name `./program --log draw.point:debug`.
It will set `debug` level for module `draw.point` and default to other.

Flag `--log-use-min` is boolean flag. It forces logging system to skip output from
all child modules if their level greater than parent. Default is `false`.

`./program --log trace --log draw:info --log draw.point:trace --log-use-min=true` 
skips all output from `logger.trace` and `logger.Debug` from whole draw.point,
and doesn't skip from other modules.

`./program --log trace --log draw:info --log draw.point:trace` allow `log_trace`
and `log_debug` only from `draw.point` from module `draw`. For other modules in
`draw` sets level `info`

You can compile program with `version=logonlyerror` for skip all
`trace`, `debug`, `info` and `warn` outputs in logger. It can improve program
release speed.

## Class logging

Module provides some functional for useful logging classes.

Example:

    module x;
    import des.util.logger;
    class A
    {
        mixin ClassLogger;
        void func() { logger.trace( "hello" ); }
    }

    module y;
    import x;
    class B : A { }

    auto b = new B;
    ...
    b.func();

outputs:

    [000000.148628473][TRACE][x.A.func]: hello

If create instance logger 

    class B : A { this(){ logger = new InstanceLogger(this); } }

outputs:

    [000000.148628473][TRACE][y.B.func]: hello

If create instance logger with instance name

    class B : A { this(){ logger = new InstanceLogger(this,"my object"); } }

outputs:

    [000000.148628473][TRACE][y.B.[my object].func]: hello

If create instance full logger

    class B : A { this(){ logger = new InstanceFullLogger(this); } }

outputs:
    [000000.148628473][TRACE][y.B.[x.A.func]]: hello

If create instance full logger with name

    class B : A { this(){ logger = new InstanceFullLogger(this,"name"); } }

outputs:

    [000000.148628473][TRACE][y.B.[name].[x.A.func]]: hello

Flag `--log` can get full emitter string `y.B.[name].[x.A.func]`.

    ./program --log "y.B.[one]:trace" --log "y.B.[two]:debug"
 +/
module des.util.logsys;

public
{
    import des.util.logsys.base;
    import des.util.logsys.logcls;
    import des.util.logsys.output;
}

import des.util.logsys.rule;

/// for simple adding logging to class
mixin template ClassLogger()
{
    static if( !is( typeof( __logger ) ) )
    {
        private Logger __logger;
        protected nothrow final @property
        {
            const(Logger) logger() const
            {
                mixin( "static import " ~ __MODULE__ ~ ";" );
                if( __logger is null )
                    mixin( "return " ~ __MODULE__ ~ ".logger;" );
                else return __logger;
            }
            void logger( Logger lg ) { __logger = lg; }
        }
    }
}

Logger logger; ///

static this() { logger = new Logger; }

shared static this()
{
    if( logrule !is null ) return;

    import core.runtime, std.getopt;
    import std.stdio;
    import std.file;

    logrule = new shared Rule;

    auto args = thisExePath ~ Runtime.args;
    string[] logging;
    bool use_minimal = false;
    bool console_color = true;
    string logfile;
    
    try
    {
        getopt( args,
                std.getopt.config.passThrough,
                "log", &logging,
                "log-use-min", &use_minimal,
                "log-console-color", &console_color,
                "log-file", &logfile,
              );
    }
    catch( Exception e ) stderr.writefln( "bad log arguments: %s", e.msg );

    logoutput = new shared LogOutputHandler( console_color );

    if( logfile.length )
        logoutput.append( "logfile", new shared FileLogOutput(logfile) );

    logrule.use_minimal = use_minimal;

    foreach( ln; logging )
    {
        auto sp = ln.split(":");
        if( sp.length == 1 )
        {
            try logrule.setLevel( toLogLevel( sp[0] ) );
            catch( Exception e )
                stderr.writefln( "log argument '%s' can't conv to LogLevel: %s", ln, e.msg );
        }
        else if( sp.length == 2 )
        {
            try
            {
                auto level = toLogLevel( sp[1] );
                logrule.setLevel( level, sp[0] );
            }
            catch( Exception e )
                stderr.writefln( "log argument '%s' can't conv '%s' to LogLevel: %s", ln, sp[1], e.msg );
        }
        else stderr.writefln( "bad log argument: %s" );
    }

    if( logging.length )
    {
        writeln( "[log use min]: ", use_minimal );
        writeln( "[log rules]:\n", logrule.print() );
    }
}
