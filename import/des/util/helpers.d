module des.util.helpers;

import core.runtime, std.file, std.path;

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
