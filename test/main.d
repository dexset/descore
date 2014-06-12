import std.stdio;

import desutil;
import desmath;
import desil;

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
}
