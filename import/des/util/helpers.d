module des.util.helpers;

import core.runtime;
import std.file;
import std.path;
import std.algorithm;


/// `buildNormalizedPath`
string bnPath( string[] path... ) 
{ return buildNormalizedPath( path ); }

/++
normalized path from executable dir,
no matter where the program was launched, result stable

code:
    return bnPath( dirName( thisExePath ) ~ path );
 +/
string appPath( string[] path... ) 
{ return bnPath( dirName( thisExePath ) ~ path ); }

/// read text from app path file
string readAPF( string[] path... )
{ return readText( appPath( path ) ); }

/// convert array of values to bitmask
auto buildFlags(T)( T[] list... )
{ return reduce!((a,b)=>a|=b)(list); }

