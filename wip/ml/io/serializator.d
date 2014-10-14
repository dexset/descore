module des.ml.io.serializator;

import std.string;
import std.stdio;
import std.exception;

import des.ml.value;
import des.ml.io.rules;

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
