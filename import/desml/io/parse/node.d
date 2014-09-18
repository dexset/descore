module desml.io.parse.node;

import std.exception;
import std.algorithm;
static import std.array;

import desml.value;
import desml.io.rules;
import desml.io.parse.func;
import desml.io.parse.address;
import desml.io.parse.command;

class ParseNode
{
    Rules rules;
    Function[string] flist;

    ParseNode parent;

    string value;

    ParseNode[] array;
    ParseNode[string] dict;

    ActionExecutor action;

    this( ParseNode parent, Rules rules )
    in { assert( rules !is null ); } body
    {
        this.parent = parent;
        this.rules = rules;
        this.action = new ActionExecutor( this, rules );
    }

    ParseNode createChild()
    { return new ParseNode(this,rules); }

    void setFuncs( Function[string] flist )
    { this.flist = flist; }

    Value compile()
    {
        auto ret = Value(value);
        foreach( ae; array )
            ret.array ~= ae.compile();
        foreach( key, de; dict )
            ret.dict[key] = de.compile();
        return ret;
    }

    void parse( BlockSource block )
    {
        auto blocks = rules.splitBlocks( block );
        foreach( i; blocks ) parseBlock(i);
    }

    void parseBlock( BlockSource block )
    {
        auto fline = block.text[0];
        if( rules.isValue( fline ) )
            action.appendValue( rules.extractValue(fline) );
        else if( rules.isBlockDefinitionLine( fline ) )
            openBlock( block );
        else if( rules.isCommand( fline ) )
            processCommand( block );
        else assert( 0, "unknown line type" );
    }

    void openBlock( BlockSource block )
    {
        auto fline = rules.splitBlockDefinition( block.text[0] );

        block.text[0] = fline[1];

        ParseNode node;

        if( rules.isArrayDefinition( fline[0] ) )
        {
            node = createChild();
            array ~= node;
        }
        else
        {
            if( fline[0] in dict )
                node = dict[fline[0]];
            else
            {
                node = createChild();
                dict[fline[0]] = node;
            }
        }

        node.parse( block );
    }

    void processCommand( BlockSource block )
    {
        auto command = rules.parseCommand( block );
        auto val = getValue( command.subject );
        action.exec( command.action, val );
    }

    Value getValue( Command.Subject subject )
    {
        if( subject.type == Command.Subject.Type.FUNCTION )
        {
            auto args = std.array.array( map!(a=>getValue(a))(subject.args) );
            return callFunction( this, subject.name, args );
        }
        else if( subject.type == Command.Subject.Type.BLOCK )
            return resolveAddress( this, subject.addr ).compile();
        else assert( 0, "unexpectable subject type" );
    }
}
