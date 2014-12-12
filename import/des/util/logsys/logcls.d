module des.util.logsys.logcls;

import std.traits : EnumMembers;
import std.string : toLower, format, split;
import std.stdio : stderr;

import des.util.logsys.base;
import des.util.logsys.output;

class Logger
{
    mixin( getLogFunctions );

protected:

    final void procMessage( in LogMessage lm ) const nothrow
    {
        try if( logrule.allowedLevel( lm.emitter ) >= lm.level ) writeLog( lm );
        catch( Exception e ) writeLogFailPrint(e);
    }

    void writeLogFailPrint( Exception e ) const nothrow
    {
        try stderr.writefln( "[INTERNAL LOG EXCEPTION]: %s", e );
        catch(Exception){}
    }

    void writeLog( in LogMessage lm ) const
    { __writeLog( chooseOutputName(lm), lm ); }

    string chooseOutputName( in LogMessage lvl ) const
    { return LogOutputHandler.console_name; }

    string procEmitterName( string name ) const nothrow
    in{ assert( name.length ); }
    out(ret){ assert( ret.length ); }
    body { return name; }

    private static string getLogFunctions() @property
    {
        string fnc = `
        void %1$s( string fnc=__FUNCTION__, Args... )( Args args ) const nothrow
        {
            version(logonlyerror)
            {
                static if( LogMessage.Level.%2$s <= LogMessage.Level.ERROR )
                    procMessage( LogMessage( procEmitterName(fnc), __ts, LogMessage.Level.%2$s, toMessage(args) ) );
            }
            else procMessage( LogMessage( procEmitterName(fnc), __ts, LogMessage.Level.%2$s, toMessage(args) ) );
        }
        `;

        string ret;
        foreach( lvl; [EnumMembers!(LogMessage.Level)] )
        {
            auto slvl = to!string(lvl);
            auto fname = fixReservedName( slvl.toLower );
            ret ~= format( fnc, fname, slvl );
        }
        return ret;
    }
}

class InstanceLogger : Logger
{
protected:
    string class_name;
    string inst_name;

public:
    this( Object obj, string inst="" )
    {
        class_name = typeid(obj).name;
        inst_name = inst;
    }

    this( string obj, string inst="" )
    {
        class_name = obj;
        inst_name = inst;
    }

    nothrow @property
    {
        void instance( string i ) { inst_name = i; }
        string instance() const { return inst_name; }
    }

protected:

    override string procEmitterName( string name ) const nothrow
    {
        try return fullEmitterName ~ "." ~ name.split(".")[$-1];
        catch(Exception e) return fullEmitterName;
    }

    string fullEmitterName() const nothrow @property
    { return class_name ~ (inst_name.length?".["~inst_name~"]":""); }
}

class InstanceFullLogger : InstanceLogger
{
    this( Object obj, string inst="" ) { super(obj,inst); }
    this( string obj, string inst="" ) { super(obj,inst); }

protected:
    override string procEmitterName( string name ) const nothrow
    { return fullEmitterName ~ ".[" ~ name ~ "]"; }
}
