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

module des.flow.base;

import std.datetime;
public import des.util.logsys;

///
class FlowException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

/// Control work element commands
enum Command
{
    START, /// 
    PAUSE, ///
    STOP,  ///
    REINIT,/// destroy work element and create it
    CLOSE  /// destroy work element
};

///
@property ulong currentTick()
{ return Clock.currAppTick().length; }

package
{
    import des.util.testsuite;

    version(unittest)
    {
        import std.math;
        import std.traits;
        import std.range;

        bool creationTest(T)( T a )
            if( is( Unqual!T == T ) )
        {
            auto cn_a = const T( a );
            auto im_a = immutable T( a );
            auto sh_a = shared T( a );
            auto sc_a = shared const T( a );
            auto si_a = shared immutable T( a );
            auto a_cn = T( cn_a );
            auto a_im = T( im_a );
            auto a_sh = T( sh_a );
            auto a_sc = T( sc_a );
            auto a_si = T( si_a );
            return a_cn == a &&
                   a_im == a &&
                   a_sh == a &&
                   a_sc == a &&
                   a_si == a;
        }
    }
}
