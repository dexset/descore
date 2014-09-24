module desml.io.parse.address;

import std.exception;

import desml.value;
import desml.io.parse.node;

struct BlockAddress
{
    enum Type
    {
        ROOT,    // /
        CURRENT, // ./
        PARENT,  // ../
        ARRAY,   // @0/
        DICT     // name/
    }
    Type type;

    this( Type t ) { type = t; }

    size_t index;
    string name;

static:
    auto root() { return BlockAddress( Type.ROOT ); }
    auto current() { return BlockAddress( Type.CURRENT ); }
    auto parent() { return BlockAddress( Type.PARENT ); }
    auto array( size_t i )
    {
        auto ret = BlockAddress( Type.ARRAY );
        ret.index = i;
        return ret;
    }
    auto dict( string n )
    {
        auto ret = BlockAddress( Type.DICT );
        ret.name = n;
        return ret;
    }
}

ParseNode resolveAddress( ParseNode cur, BlockAddress[] addr )
{
    ParseNode node = cur;
    foreach( move; addr )
        final switch(move.type)
        {
            case BlockAddress.Type.ROOT:
                node = getRoot( node );
                break;
            case BlockAddress.Type.CURRENT:
                break;
            case BlockAddress.Type.PARENT:
                node = getParent( node );
                break;
            case BlockAddress.Type.ARRAY:
                node = getArray( node, move.index );
                break;
            case BlockAddress.Type.DICT:
                node = getDict( node, move.name );
                break;
        }
    return node;
}

ParseNode getRoot( ParseNode cur )
in{ assert( cur !is null ); } body
{
    ParseNode tt = cur;
    while( tt.parent !is null )
        tt = tt.parent;
    return tt;
}

ParseNode getParent( ParseNode cur )
in{ assert( cur !is null ); } body
{
    // TODO: readable exception
    enforce( cur.parent !is null );
    return cur.parent;
}

ParseNode getArray( ParseNode cur, size_t index )
in{ assert( cur !is null ); } body
{
    // TODO: readable exception
    enforce( index < cur.array.length );
    return cur.array[index];
}

ParseNode getDict( ParseNode cur, string name )
in{ assert( cur !is null ); } body
{
    // TODO: readable exception
    import std.string;
    enforce( name in cur.dict,
            format( "no name '%s'", name ) );
    return cur.dict[name];
}

Value callFunction( ParseNode cur, string name, Value[] args )
{
    /+ TODO: readable exception +/ 
    if( name in cur.flist ) return cur.flist[name](args);

    if( cur.parent !is null )
        return callFunction( cur.parent, name, args );

    assert(0,"TODO: readable exception");
}
