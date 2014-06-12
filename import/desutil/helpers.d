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

module desutil.helpers;

pure nothrow string toDString( const(char*) c_str )
{
    string buf;
    char *ch = cast(char*)c_str;
    while( *ch != '\0' ) buf ~= *(ch++);
    return buf;
}

pure nothrow string toDStringFix(size_t S)( const(char[S]) c_buf )
{
    string buf;
    foreach( c; c_buf ) buf ~= c;
    return buf;
}

import core.runtime, std.file, std.path;

string appPath( string[] elems... ) 
{ return buildNormalizedPath( dirName( thisExePath ) ~ elems ); }
string bnPath( string[] elems... ) 
{ return buildNormalizedPath( elems ); }

import std.traits : isNumeric;

struct lim_t(T) if( isNumeric!T )
{
    T minimum=0, maximum=T.max;
    bool fix = false;

    pure nothrow this( T Min, T Max )
    {
        minimum = Min;
        maximum = Max;
    }

    T opCall( T old, T nval ) const
    {
        if( fix ) return old;
        return nval >= minimum ? ( nval < maximum ? nval : maximum ) : minimum;
    }
}

interface ExternalMemoryManager
{
    protected @property final static string getMixinChildEMM()
    {
        return `private ExternalMemoryManager[] chemm;
                protected final ref ExternalMemoryManager[] childEMM() { return chemm; }`;
    }

    protected
    {
        @property ref ExternalMemoryManager[] childEMM();
        void selfDestroy();
    }

    final
    {
        T registerChildEMM(T)( T obj )
            if( is( T == class ) || is( T == interface ) )
        {
            auto cemm = cast(ExternalMemoryManager)obj;
            if( cemm ) childEMM ~= cemm; 
            return obj;
        }

        void destroy()
        {
            foreach( cemm; childEMM )
                cemm.destroy();
            selfDestroy();
        }
    }
}
