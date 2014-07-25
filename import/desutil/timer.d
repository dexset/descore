module desutil.timer;

import std.datetime;

struct TimerCallback
{
    double time=0;
    double tick=0;
    void delegate() func;

    void reset() { time = 0; }
    void update( double dt )
    {  
        time += dt;
        if( time > tick )
        {
            time = 0;
            if( func ) func();
        }
    }
}

class Timer
{
    StopWatch sw;
    double time=0;
    double all_time=0;
    size_t cbindex=0;

    TimerCallback[string] callback;

    this() { sw.start(); }

    string every( double dt, void delegate() fnc )
    { 
        import std.string;
        auto key = format( "__auto_gen_callback_%04d", cbindex++ );
        callback[key] = TimerCallback( 0, dt, fnc ); 
        return key;
    }

    void every( double dt, string key, void delegate() fnc )
    { callback[key] = TimerCallback( 0, dt, fnc ); }

    void removeCallback( string key )
    { callback.remove(key); }

    double reset()
    {
        auto r = time;
        time = 0;
        foreach( cb; callback ) cb.reset();
        return r;
    }

    double hard_reset()
    {
        auto r = all_time;
        all_time = 0;
        reset();
        return r;
    }

    double cycle()
    {
        sw.stop();
        auto dt = sw.peek().to!("seconds",double);
        sw.reset();
        sw.start();
        time += dt;
        all_time += dt;
        foreach( cb; callback ) cb.update( dt );
        return dt;
    }
}
