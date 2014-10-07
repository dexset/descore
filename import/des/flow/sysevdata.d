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

module des.flow.sysevdata;

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
