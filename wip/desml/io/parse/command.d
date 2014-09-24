module desml.io.parse.command;

import std.exception;

import desml.value;
import desml.io.rules;
import desml.io.parse.node;
import desml.io.parse.address;

struct Command
{
    enum Action
    {
        APPEND,
        REPLACE,
        UPDATE
    }

    static struct Subject
    {
        enum Type
        {
            VALUE,
            BLOCK,
            FUNCTION
        }

        Type type;

        string str;

        Subject[] args;

        BlockAddress[] addr;
    }

    Action action;
    Subject subject;
}

class ActionExecutor
{
    ParseNode node;
    Rules rules;

    this( ParseNode node, Rules rules )
    in
    {
        assert( node !is null );
        assert( rules !is null );
    }
    body
    {
        this.node = node;
        this.rules = rules;
    }

    void exec( Command.Action act, Value val )
    {
        final switch( act )
        {
            case Command.Action.APPEND:  this.append(val); break;
            case Command.Action.REPLACE: this.replace(val); break;
            case Command.Action.UPDATE:  this.update(val); break;
        }
    }

    void append( Value data )
    {
        appendValue( data.value );
        appendArray( data.array );
        appendDict( data.dict );
    }

    void replace( Value data )
    {
        node.value = data.value;

        node.array.length = 0;
        appendArray( data.array );

        node.dict.destroy();
        replaceDict( data.dict );
    }

    void update( Value data )
    {
        node.value = data.value;
        updateArray( data.array );
        replaceDict( data.dict );
    }

    void appendValue( string str )
    { node.value = rules.appendValue( node.value, str ); }

    void appendArray( Value[] arr )
    {
        foreach( bl; arr )
        {
            auto n = node.createChild();
            n.action.replace(bl);
            node.array ~= n;
        }
    }

    void appendDict( Value[string] dct )
    {
        foreach( key, bl; dct )
        {
            if( key in node.dict ) continue;
            auto n = node.createChild();
            n.action.replace(bl);
            node.dict[key] = n;
        }
    }

    void replaceDict( Value[string] dct )
    {
        foreach( key, bl; dct )
        {
            auto n = node.createChild();
            n.action.replace(bl);
            node.dict[key] = n;
        }
    }

    void updateArray( Value[] arr )
    {
        if( node.array.length < arr.length )
            node.array.length = arr.length;
        foreach( i, v; arr )
            node.array[i].action.update(v);
    }
}

