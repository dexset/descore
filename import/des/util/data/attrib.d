module des.util.data.attrib;

import des.util.data.type;

/// data array description
interface Attribute
{
    const @property
    {
        string desc(); ///
        ref const(ElemInfo) info(); ///
        protected size_t manual_stride(); ///
        size_t offset(); ///
        const(void[]) data(); ///

        ///
        final size_t stride()
        { return manual_stride ? manual_stride : info.bpe; }

        ///
        final size_t count()
        { return ( data.length - offset ) / stride; }
    }
}

/++
    simple realisation of Attribute interface
 +/
class SimpleAttribute : Attribute
{
protected:
    string _desc; ///
    ElemInfo _info; ///
    void[] _data; ///

public:

    ///
    this( string Desc, ElemInfo Info, in void[] Data )
    {
        _desc = Desc;
        _info = Info;
        _data = Data.dup;
    }

    ///
    this(T)( string Desc, in T[] Data )
    {
        _desc = Desc;
        _info = ElemInfo.fromType!T;
        _data = Data.dup;
    }

    const @property
    {
        string desc() { return _desc; }
        ref const(ElemInfo) info() { return _info; }
        protected size_t manual_stride() { return 0; }
        size_t offset() { return 0; }
        const(void[]) data() { return _data; }
    }
}

///
unittest
{
    import des.math.linear;
    vec2[] data = [ vec2(1,2), vec2(3,4) ];
    auto a = new SimpleAttribute( "test", data );

    assert( a.stride == vec2.sizeof );
    assert( a.info.type == DataType.FLOAT );
    assert( a.info.comp == 2 );
    assert( a.data == cast(void[])data );
}
