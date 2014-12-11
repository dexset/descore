module des.util.logsys;

public
{
    import des.util.logsys.base;
    import des.util.logsys.logcls;
    import des.util.logsys.output;
}

import des.util.logsys.rule;

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

Logger logger;

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
