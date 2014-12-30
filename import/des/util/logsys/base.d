module des.util.logsys.base;

import std.conv : to;
import std.datetime : Clock;
import std.string : toUpper, format;

import des.util.logsys.output;
import des.util.logsys.rule;

///
class LogSysException : Exception { this( string msg ) { super(msg); } }

///
enum LogLevel
{
    OFF,   /// no output
    FATAL, /// not recoverible error
    ERROR, /// recoverible error (exceptions)
    WARN,  /// warning (only if something wrong but not critical)
    INFO,  /// info message (one-call functions messages)
    DEBUG, /// debug message (detalied one-call functions messages)
    TRACE  /// trace message (idle, foreach, etc)
};

///
struct LogMessage
{
    string emitter; /// name of log message emmiter
    ulong ts; /// timestamp

    /// log message level (without LogLevel.OFF)
    enum Level : LogLevel 
    {
        FATAL = LogLevel.FATAL, ///
        ERROR, ///
        WARN, ///
        INFO, ///
        DEBUG, ///
        TRACE ///
    };

    Level level; /// log level
    string message; ///

    ///
    @disable this();

    ///
    this( string emitter, ulong ts, Level level, string message ) pure nothrow @safe
    {
        this.emitter = emitter;
        this.ts = ts;
        this.level = level;
        this.message = message;
    }
}

/++
 nothrow format function, if first is string it try call string.format,
 if it's failed return all args converted to string
 +/
string ntFormat(Args...)( Args args ) nothrow
{
    try
    {
        static if( is( Args[0] == string ) )
        { try return format(args); catch{} }

        string res;
        foreach( arg; args )
            res ~= to!string(arg);
        return res;
    }
    catch( Exception e )
        return "[MESSAGE CTOR EXCEPTION]: " ~ e.msg;
}

///
LogLevel toLogLevel( string s ) { return to!LogLevel( s.toUpper ); }

/++
    Returns:
    format( "[%016.9f][%5s][%s]: %s", lm.ts / 1e9f, lm.level, lm.emitter, lm.message );
 +/
string defaultFormatLogMessage( in LogMessage lm )
{
    return format( "[%016.9f][%5s][%s]: %s",
                    lm.ts / 1e9f, lm.level, lm.emitter, lm.message );
}

///
static shared LogOutputHandler logoutput;

///
static shared Rule logrule;

package:

ulong __ts() nothrow @property
{
    try return Clock.currAppTick().length;
    catch(Exception e) return 0;
}

string checkReservedName( string name ) nothrow
{
    if( name == "debug" ) return "Debug";
    return name;
}
