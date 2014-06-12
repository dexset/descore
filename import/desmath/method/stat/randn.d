/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

module desmath.method.stat.randn;

import std.math;
public import std.random;

double normal( double mu=0.0, double sigma=1.0 )
{
    static bool deviate = false;
    static float stored;

    if( !deviate )
    {
        double max = cast(double)(ulong.max - 1);
        double dist = sqrt( -2.0 * log( uniform( 0, max ) / max ) );
        double angle = 2.0 * 3.14159265358979323846 * ( uniform( 0, max ) / max );

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
