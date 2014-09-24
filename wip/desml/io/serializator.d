module desml.io.serializator;

import std.string;
import std.stdio;
import std.exception;

import desml.value;
import desml.io.rules;

class Serializator
{
    Rules rules;

    this( Rules rules = null )
    {
        if( rules is null )
            rules = new Rules();

        this.rules = rules;
    }

    string serialize( in Value obj )
    {
        return "";
    }
}
