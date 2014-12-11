module des.util.logsys.output;

import std.stdio : stdout, stderr;
import std.string : toStringz;
import std.datetime;

import des.util.logsys.base;

synchronized abstract class LogOutput
{
    final void opCall( in LogMessage lm ) { write( lm, formatLogMessage( lm ) ); }

protected:

    void write( in LogMessage, string );

    string formatLogMessage( in LogMessage lm ) const
    out(ret){ assert( ret.length ); }
    body { return defaultFormatLogMessage( lm ); }
}

synchronized class NullLogOutput : LogOutput
{
protected:
    override
    {
        void write( in LogMessage, string ){}
        string formatLogMessage( in LogMessage lm ) const { return "null"; }
    }
}

synchronized class FileLogOutput : LogOutput
{
    import core.stdc.stdio;
    import std.datetime;
    FILE* file;

    this( string filename )
    {
        file = fopen( filename.toStringz, "a" );
        if( file is null )
            throw new LogSysException( "unable to open file '" ~ filename ~ "' at write mode" );
        fprintf( file, "%s\n", firstLine().toStringz );
    }

    ~this() { if( file ) fclose( file ); }

protected:

    override void write( in LogMessage, string msg )
    { fprintf( file, "%s\n", msg.toStringz ); }

    string firstLine() const
    {
        auto dt = Clock.currTime;
        return format( "%02d.%02d.%4d %02d:%02d:%02d",
                dt.day, dt.month, dt.year, dt.hour, dt.minute, dt.second );
    }
}

synchronized class ConsoleLogOutput : LogOutput
{
    protected override void write( in LogMessage lm, string str )
    {
        if( lm.level > LogMessage.Level.ERROR )
            stdout.writeln( str );
        else
            stderr.writeln( str );
    }
}

synchronized class ColorConsoleLogOutput : ConsoleLogOutput
{
    enum 
    {
        // Reset
        COLOR_OFF = "\x1b[0m",

        // Regular Colors
        FG_BLACK  = "\x1b[0;30m",
        FG_RED    = "\x1b[0;31m",
        FG_GREEN  = "\x1b[0;32m",
        FG_YELLOW = "\x1b[0;33m",
        FG_BLUE   = "\x1b[0;34m",
        FG_PURPLE = "\x1b[0;35m",
        FG_CYAN   = "\x1b[0;36m",
        FG_WHITE  = "\x1b[0;37m",

        // Bold
        FG_B_BLACK  = "\x1b[1;30m",
        FG_B_RED    = "\x1b[1;31m",
        FG_B_GREEN  = "\x1b[1;32m",
        FG_B_YELLOW = "\x1b[1;33m",
        FG_B_BLUE   = "\x1b[1;34m",
        FG_B_PURPLE = "\x1b[1;35m",
        FG_B_CYAN   = "\x1b[1;36m",
        FG_B_WHITE  = "\x1b[1;37m",

        // Underline
        FG_U_BLACK  = "\x1b[4;30m",
        FG_U_RED    = "\x1b[4;31m",
        FG_U_GREEN  = "\x1b[4;32m",
        FG_U_YELLOW = "\x1b[4;33m",
        FG_U_BLUE   = "\x1b[4;34m",
        FG_U_PURPLE = "\x1b[4;35m",
        FG_U_CYAN   = "\x1b[4;36m",
        FG_U_WHITE  = "\x1b[4;37m",

        // Background
        BG_BLACK  = "\x1b[40m",
        BG_RED    = "\x1b[41m",
        BG_GREEN  = "\x1b[42m",
        BG_YELLOW = "\x1b[43m",
        BG_BLUE   = "\x1b[44m",
        BG_PURPLE = "\x1b[45m",
        BG_CYAN   = "\x1b[46m",
        BG_WHITE  = "\x1b[47m",

        // High Intensity
        FG_I_BLACK  = "\x1b[0;90m",
        FG_I_RED    = "\x1b[0;91m",
        FG_I_GREEN  = "\x1b[0;92m",
        FG_I_YELLOW = "\x1b[0;93m",
        FG_I_BLUE   = "\x1b[0;94m",
        FG_I_PURPLE = "\x1b[0;95m",
        FG_I_CYAN   = "\x1b[0;96m",
        FG_I_WHITE  = "\x1b[0;97m",

        // Bold High Intensity
        FG_BI_BLACK  = "\x1b[1;90m",
        FG_BI_RED    = "\x1b[1;91m",
        FG_BI_GREEN  = "\x1b[1;92m",
        FG_BI_YELLOW = "\x1b[1;93m",
        FG_BI_BLUE   = "\x1b[1;94m",
        FG_BI_PURPLE = "\x1b[1;95m",
        FG_BI_CYAN   = "\x1b[1;96m",
        FG_BI_WHITE  = "\x1b[1;97m",

        // High Intensity backgrounds
        BG_I_BLACK  = "\x1b[0;100m",
        BG_I_RED    = "\x1b[0;101m",
        BG_I_GREEN  = "\x1b[0;102m",
        BG_I_YELLOW = "\x1b[0;103m",
        BG_I_BLUE   = "\x1b[0;104m",
        BG_I_PURPLE = "\x1b[0;105m",
        BG_I_CYAN   = "\x1b[0;106m",
        BG_I_WHITE  = "\x1b[0;107m",
    };

protected:

    override string formatLogMessage( in LogMessage lm ) const
    {
        auto color = chooseColors( lm );
        return format( "[%6$s%1$016.9f%5$s][%7$s%2$5s%5$s][%8$s%3$s%5$s]: %9$s%4$s%5$s",
                       lm.ts / 1e9f, lm.level, lm.emitter, lm.message,
                       COLOR_OFF, color[0], color[1], color[2], color[3] );
    }

    string[4] chooseColors( in LogMessage lm ) const
    {
        string ts, type, emitter, msg;

        final switch( lm.level )
        {
            case LogMessage.Level.FATAL: type = FG_BLACK ~ BG_RED; break;
            case LogMessage.Level.ERROR: type = FG_RED; break;
            case LogMessage.Level.WARN: type = FG_PURPLE; break;
            case LogMessage.Level.INFO: type = FG_CYAN; break;
            case LogMessage.Level.DEBUG: type = FG_YELLOW; break;
            case LogMessage.Level.TRACE: break;
        }

        ts = type;
        emitter = type;
        msg = type;

        return [ts, type, emitter, msg];
    }
}

synchronized final class LogOutputHandler
{
package:
    LogOutput[string] list;
    bool[string] enabled;

    this( bool console_color=true )
    {
        version(linux)
        {
            if( console_color )
                list[console_name] = new shared ColorConsoleLogOutput;
            else
                list[console_name] = new shared ConsoleLogOutput;
        }
        else
        {
            list[console_name] = new shared ConsoleLogOutput;
        }
        list[null_name] = new shared NullLogOutput;

        enabled[console_name] = true;
        enabled[null_name] = false;
    }

    void opCall( string trg_name, in LogMessage lm )
    {
        if( broadcast )
        {
            foreach( name, e; enabled )
                if( name in list && e )
                    list[name](lm);
        }
        else
        {
            if( trg_name in list )
                list[trg_name](lm);
        }
    }

    bool _broadcast = true;

public:

    enum console_name = "console";
    enum null_name = "null";

    bool broadcast() const @property { return _broadcast; }
    bool broadcast( bool b ) @property { _broadcast = b; return b; }

    void enable( string name ) { enabled[name] = true; }
    void disable( string name ) { enabled[name] = false; }

    void append( string name, shared LogOutput output )
    in{ assert( output !is null ); }
    body
    {
        list[name] = output;
        enable( name );
    }

    void remove( string name )
    {
        if( name == console_name || name == null_name )
            throw new LogSysException( "can not unregister '" ~ name ~ "' log output" );
        list.remove( name );
    }
}
