module des.util.helpers;

import core.runtime, std.file, std.path;

/++
code:
    return buildNormalizedPath( dirName( thisExePath ) ~ elems );
 +/
string appPath( string[] elems... ) 
{ return buildNormalizedPath( dirName( thisExePath ) ~ elems ); }

/// buildNormalizedPath
string bnPath( string[] elems... ) 
{ return buildNormalizedPath( elems ); }
