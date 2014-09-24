module desflow.sysevdata;

struct SysEvData
{
    string msg;

    enum slist =
    [
        "pause",
        "work",
        "stop"
    ];

    mixin( getStateListString(slist) );
}

import std.string;

string getStateListString( in string[] list )
{
    string[] buf;

    foreach( state; list )
    {
        buf ~= format( `static @property SysEvData %1$s() { return SysEvData("%1$s"); }`, state );
        buf ~= format( `@property bool is%s() { return msg == "%s"; }`, state.capitalize, state );
    }

    return buf.join("\n");
}

unittest
{
    auto ep = SysEvData.pause;
    assert( ep.isPause );
    auto ew = SysEvData.work;
    assert( ew.isWork );
}
