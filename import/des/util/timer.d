module des.util.timer;

import std.datetime;
import core.thread;

import des.util.arch;

///
class TimeSignal : Signal!(double)
{
protected:
    double el=0, tr=0;

public:

    this( double tr )
    in { assert( tr > 0 ); }
    body { this.tr = tr; }

    @property
    {
        ///
        double trigger() const { return tr; }
        ///
        double trigger( double v )
        in { assert( v > 0 ); }
        body { tr = v; return v; }

        ///
        double elapsed() const { return el; }
    }

    ///
    void reset( double initial=0 ) { el = initial; }

    ///
    void update( double dt )
    {  
        el += dt;
        if( el < tr ) return;
        opCall( el );
        reset( el - tr );
    }
}

///
class Timer : DesObject
{
    mixin DES;

    ///
    StopWatch sw;
    ///
    double time=0;
    ///
    double all_time=0;
    ///
    size_t cbindex=0;

    TimeSignal[] signals;

    ///
    this() { sw.start(); }

    ///
    TimeSignal signalEvery( double trigger )
    {
        auto s = newEMM!TimeSignal( trigger );
        signals ~= s;
        return s;
    }

    ///
    double reset()
    {
        auto r = time;
        time = 0;
        return r;
    }

    ///
    void restart( double s=0 )
    {
        cycle();
        Thread.sleep( dur!"usecs"(cast(ulong)(s*1e6)) );
    }

    ///
    double hardReset()
    {
        auto r = all_time;
        all_time = 0;
        reset();
        foreach( s; signals ) s.reset();
        return r;
    }

    ///
    double cycle()
    {
        sw.stop();
        auto dt = sw.peek().to!("seconds",double);
        sw.reset();
        sw.start();
        time += dt;
        all_time += dt;
        foreach( s; signals )
            s.update( dt );
        return dt;
    }
}
