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

module desutil.information;

/++ еденица информации +/
struct Information(Type)
{
    /++ сама информация +/
    Type val;
    
    /++ актуальность +/
    float topicality = 0; 
    /++ достоверность +/
    float reliability = 0; 
    /++ полнота +/
    float completeness = 0; 

    /++ возможность доступа +/
    bool access_ability = true;

    alias val this;

    this(E)( E b ) if( is( E : Type ) ) { val = b; }

    pure this( Type b, float t, float r, float c, bool aa = true )
    {
        val = b;
        topicality = t;
        reliability = r;
        completeness = c;
        access_ability = aa;
    }

    auto opAssign(E)( E b ) 
        if( is( E : Type ) && !( is( typeof( E.init.val ) ) ) )
    { 
        val = b; 
        return b;
    }

    auto opAssign(E)( Information!E b )
        if( is( E : Type ) )
    {
        access_ability = b.access_ability;
        topicality = b.topicality;
        reliability = b.reliability;
        completeness = b.completeness;

        val = b.val;
        return this;
    }
}

unittest
{
    alias Information!float float_info;
    auto a = float_info( 5 );
    auto b = float_info( 10 );
    auto c = a + b;
    assert( is( typeof(c) == float ) );
    assert( c == 15 );

    a = 12;
    assert( a.val == 12 );
    b.topicality = 1;
    b.reliability = .5;
    b.completeness = .25;
    a = b;
    assert( a.val == 10 );
    assert( a.topicality == 1 );
    assert( a.reliability == .5 );
    assert( a.completeness == .25 );
}
