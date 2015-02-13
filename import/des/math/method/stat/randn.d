module des.math.method.stat.randn;

import std.math;
public import std.random;

///
double normal( double mu=0.0, double sigma=1.0 )
{
    static bool deviate = false;
    static float stored;

    if( !deviate )
    {
        double max = cast(double)(ulong.max - 1);
        double dist = sqrt( -2.0 * log( uniform( 0, max ) / max ) );
        double angle = 2.0 * PI * ( uniform( 0, max ) / max );

        stored = dist * cos( angle );
        deviate = true;

        return dist * sin( angle ) * sigma + mu;
    }
    else
    {
        deviate = false;
        return stored * sigma + mu;
    }
}
