import std.stdio;

import des.util;
import des.math;
import des.il;

void main() 
{ 
    version(unittest)
    {
        writeln( "\n------------------------" ); 
        writeln( "DESCore unittesting complite" ); 
        writeln( "------------------------\n" ); 
    }
    else
    {
        stderr.writeln( "build with -unittest flag to test DES" );
    }

    setTranslatePath( "data" );
    Translator.setLocalization( "ru" );

    writeln( _!"hello" );
}
