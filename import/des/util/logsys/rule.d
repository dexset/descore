module des.util.logsys.rule;

import std.algorithm : min;
import std.string : split, join;

import des.util.logsys.base;

/// store rules for logging
package synchronized class Rule
{
package:
    shared Rule parent; ///

    LogLevel level = LogLevel.ERROR; ///
    shared Rule[string] inner; ///

    bool use_minimal = true; ///

public:

    ///
    this( shared Rule parent = null )
    {
        this.parent = parent;
        if( parent )
            this.level = parent.level;
    }

    ///
    @property bool useMinimal() const
    {
        if( parent !is null )
            return parent.useMinimal();
        else return use_minimal;
    }

    /// setting allowed level for emitter (create new inner Rule), if emitter is "" sets self level
    void setLevel( LogLevel lvl, string emitter="" )
    {
        auto addr = splitAddress( emitter );
        if( addr[0].length == 0 ) { level = lvl; return; }
        auto iname = addr[0];
        if( iname !in inner ) inner[iname] = new shared Rule(this);
        inner[iname].setLevel( lvl, addr[1] );
    }

    /// if emitter is "" returns self level
    LogLevel allowedLevel( string emitter="" )
    {
        auto addr = splitAddress( emitter );
        if( addr[0].length == 0 ) return level;
        auto iname = addr[0];
        if( iname !in inner ) return level;
        if( useMinimal )
            return min( level, inner[iname].allowedLevel( addr[1] ) );
        else
            return inner[iname].allowedLevel( addr[1] );
    }

    string print( string offset="" ) const
    {
        string ret = format( "%s", level );
        foreach( key, val; inner )
            ret ~= format( "\n%s%s : %s", offset, key, val.print( offset ~ mlt(" ",key.length) ) );
        return ret;
    }

protected:

    ///
    static string[2] splitAddress( string emitter )
    {
        auto addr = emitter.split(".");
        if( addr.length == 0 ) return ["",""];
        if( addr.length == 1 ) return [addr[0],""];
        
        return [ addr[0], addr[1..$].join(".") ];
    }
}

private T[] mlt(T)( T[] val, size_t cnt ) nothrow
{
    T[] buf;
    foreach( i; 0 .. cnt ) buf ~= val;
    return buf;
}

unittest { assert( "    ", mlt( " ", 4 ) ); }

///
unittest
{
    auto r = new shared Rule;

    r.setLevel( LogLevel.INFO );
    r.setLevel( LogLevel.TRACE, "des.gl" );
    r.setLevel( LogLevel.WARN, "des" );

    assert( r.allowedLevel() == LogLevel.INFO );
    assert( r.allowedLevel("des") == LogLevel.WARN );
    assert( r.allowedLevel("des.gl") == LogLevel.WARN );

    r.use_minimal = false;

    assert( r.allowedLevel() == LogLevel.INFO );
    assert( r.allowedLevel("des") == LogLevel.WARN );
    assert( r.allowedLevel("des.gl") == LogLevel.TRACE );
}
