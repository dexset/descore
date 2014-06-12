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

module desutil.langpack;

import std.string : toLower, toUpper;
import std.conv : to;

final class LangPack
{
private:
    wstring[string][string] data;

public:
    string cur = "en";
    enum Reg { NOREG, LOWER, UPPER };
    Reg reg = Reg.NOREG;

    this( in wstring[string][string] pack = null ) 
    { if( pack !is null ) setData(pack); }

    void setData( in wstring[string][string] pack )
    { 
        foreach( key, tr; pack )
        {
            foreach( lang, word; tr )
                data[key][lang] = word;
            data[key].rehash;
        }
        data.rehash;
    }

    wstring opIndex( string key ) const { return this[cur,key]; }

    wstring opIndex( string lang, string key ) const
    {
        auto tr = key in data;
        if( tr !is null ) 
        {
            auto word = lang in (*tr);
            if( word !is null ) 
            {
                final switch(this.reg)
                {
                    case Reg.NOREG: return *word;
                    case Reg.LOWER: return (*word).toLower();
                    case Reg.UPPER: return (*word).toUpper();
                }
            }
            else return to!wstring( "# no tr [" ~ lang ~ "]:[" ~ key ~ "]" );
        }
        else return to!wstring( "# no key [" ~ key ~ "]" );
    }
}

unittest
{
    auto lp = new LangPack( 
              [ "start"    : [ "en": "start",    "ru": "старт"     ],
                "stop"     : [ "en": "stop",     "ru": "стоп"      ],
                "settings" : [ "en": "settings", "ru": "настройки" ],
                "exit"     : [ "en": "exit",     "ru": "выход"     ],
                "ololo"    : [ "en": "okda" ],
               ] );

    lp.cur = "ru";
    assert( lp["settings"] == "настройки" );
    assert( lp["fr","hello"] == "# no key [hello]" );
    assert( lp["exit"] == "выход" );
    assert( lp["en","exit"] == "exit" );
    assert( lp["ololo"] == "# no tr [ru]:[ololo]" );
    assert( lp["en","ololo"] == "okda" );
}
