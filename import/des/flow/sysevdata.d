module des.flow.sysevdata;

/++ System event data

    passed to work element then before change thread state

    creation propertyes like `SysEvData.pause` and checking propertyes like
    `SysEvData.isPause` generates from mixin with `slist`
 +/
struct SysEvData
{
    /// store name of system event
    string msg;

    /// events names `[ "pause", "work", "stop" ]`
    enum slist = [ "pause", "work", "stop" ];

    mixin( getStateListString(slist) );

    private static string getStateListString( in string[] list ) pure
    {
        import std.string;
        string[] buf;

        foreach( state; list )
        {
            buf ~= format( `static @property SysEvData %1$s() { return SysEvData("%1$s"); }`, state );
            buf ~= format( `@property bool is%s() { return msg == "%s"; }`, state.capitalize, state );
        }

        return buf.join("\n");
    }
}

///
unittest
{
    auto ep = SysEvData.pause;
    assert( ep.isPause );
    auto ew = SysEvData.work;
    assert( ew.isWork );
}
