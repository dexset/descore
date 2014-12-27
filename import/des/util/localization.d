/+
The MIT License (MIT)

    Copyright (c) <2013> <Oleg Butko (deviator), Anton Akzhigitov (Akzwar)>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
+/

/++

<source>
    mixin( useTranslatorMixin( "translate/dir" ) );

    writeln( _!"hello" );

    Translator.setLocalization( "ru" );

    writeln( _!"hello" );
    writeln( _!"world" );
</source>

1. run program 

2. copy and rename "translate/dir/base" to "translate/dir/lang.lt",
    where <lang> is language to translate

3. in each line in "translate/dir/lang.lt" write translation of line
    example:
    hello : привет

4. profit

 +/

module des.util.localization;

import std.string;
import std.conv;
import std.stdio;
import std.file;
import std.path;
import std.algorithm;
import std.exception;
import std.typecons;

import des.util.logsys;

interface WordConverter { wstring opIndex( string key ); }

interface Localization : WordConverter
{
    public const @property string name();
    public bool has( string key );
    protected wstring notFound( string key );
}

class DictionaryLoaderException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, size_t line=__LINE__ ) 
    { super( msg, file, line ); } 
}

interface DictionaryLoader
{
    Localization[string] load();
    void store( lazy string[] keys );
}

class BaseLocalization : Localization
{
protected:
    string dict_name;
    wstring[string] dict;

public:

    this( string dName, wstring[string] dict )
    {
        dict_name = dName;
        foreach( key, word; dict )
            this.dict[key] = word;
        this.dict.rehash;
    }

    const @property string name() { return dict_name; }

    bool has( string key ) { return !!( key in dict ); }

    wstring opIndex( string key )
    { return dict.get( key, notFound(key) ); }

protected:

    wstring notFound( string key )
    {
        logger.error( "no translation for key '%s' in dict '%s'", key, name );
        return "[no_tr]"w ~ to!wstring(key);
    }
}

class DirDictionaryLoader : DictionaryLoader
{
    string path;
    string ext;

    this( string path, string ext="lt" )
    {
        this.path = path;
        this.ext = ext;
    }

    Localization[string] load()
    {
        baseDictType base;

        try base = loadBase( path );
        catch( DictionaryLoaderException e )
        {
            logger.error( e.msg );
            return (Localization[string]).init;
        }

        auto ret = loadLocalizations( path );
        checkLocalizations( ret, base );
        return ret;
    }

    void store( lazy string[] keys )
    {
        if( !path.exists )
        {
            mkdirRecurse( path );
            logger.info( "create localization path '%s'", path );
        }

        auto base_dict = buildNormalizedPath( path, "base" );
        auto f = File( base_dict, "w" );
        foreach( key; keys ) f.writeln( key );
        f.close();
    }

protected:

    alias ubyte[string] baseDictType;

    baseDictType loadBase( string path )
    {
        auto base_dict = buildNormalizedPath( path, "base" );
        if( !base_dict.exists )
            throw new DictionaryLoaderException( format( "no base list '%s'", base_dict ) );

        auto f = File( base_dict, "r" );
        scope(exit) f.close();

        baseDictType ret;
        foreach( ln; f.byLine() )
            ret[ln.idup] = 1;

        return ret;
    }

    Localization[string] loadLocalizations( string path )
    {
        auto loc_files = dirEntries( path, "*."~ext, SpanMode.shallow );

        Localization[string] ret;

        foreach( lf; loc_files )
        {
            auto label = getLabel( lf.name );
            ret[label] = loadFromFile( lf.name );
        }

        return ret;
    }

    string getLabel( string name ) { return baseName( name, "." ~ ext ); }

    Localization loadFromFile( string fname )
    {
        auto f = File( fname );
        scope(exit) f.close();

        auto name = getLabel( fname );

        wstring[string] dict;

        size_t i = 0;
        foreach( ln; f.byLine() )
            processLine( dict, i++, fname, strip(ln.idup) );

        return new BaseLocalization( name, dict );
    }

    static auto splitLine( size_t no, string fname, string ln )
    {
        auto bf = ln.split(":");
        enforce( bf.length == 2, new DictionaryLoaderException( "bad localization: " ~ ln, fname, no ) );
        return tuple( bf[0], to!wstring(bf[1]) );
    }

    static void processLine( ref wstring[string] d, size_t no, string fname, string line )
    {
        if( line.length == 0 ) return;
        auto ln = splitLine( no, fname, line );
        auto key = strip(ln[0]);
        auto value = strip(ln[1]);
        checkKeyExests( d, key, value );
        d[key] = value;
    }

    static void checkKeyExests( wstring[string] d, string key, wstring value )
    {
        if( key !in d ) return;

        throw new DictionaryLoaderException(
                format( "key '%s' has duplicate values: '%s', '%s'",
                    key, d[key], value ) );
    }

    void checkLocalizations( Localization[string] locs, baseDictType base )
    {
        foreach( lang, loc; locs )
            foreach( key; base.keys )
                if( !loc.has(key) )
                    logger.error( "dict '%s' has no key '%s'", lang, key );
    }
}

final class Translator
{
private:
    static Translator self;

    this(){}

    DictionaryLoader dict_loader;

    Localization[string] localizations;
    Localization currentLocalization;

    @property static Translator singleton()
    {
        if( self is null ) self = new Translator();
        return self;
    }

    void s_setDictionaryLoader( DictionaryLoader dl )
    {
        dict_loader = dl;
        s_reloadLocalizations();
    }

    void s_reloadLocalizations()
    {
        if( dict_loader is null )
        {
            logger.error( "dictionary loader not setted: no reloading" );
            return;
        }

        localizations = dict_loader.load();
    }

    size_t[string] used_keys;

    wstring s_opIndex(string str)
    {
        used_keys[str]++;

        if( currentLocalization !is null )
            return currentLocalization[str];

        logger.info( "no current localization: use source string" );

        return to!wstring(str);
    }

    void s_setLocalization( string lang )
    {
        if( lang in localizations )
            currentLocalization = localizations[lang];
        else
        {
            if( dict_loader is null )
                logger.error( "no dictionary loader -> no localization '%1$s', (copy 'base' to '%1$s')", lang );
            else logger.error( "no localization '%1$s', (copy 'base' to '%1$s.lt')", lang );
        }
    }

    string[] s_usedKeys() { return used_keys.keys; }

    void s_store()
    {
        if( used_keys.length == 0 ) return;

        if( dict_loader is null )
        {
            logger.error( "dictionary loader not setted: no store" );
            return;
        }

        dict_loader.store( used_keys.keys );
    }

public:

    static 
    {
        void setDictionaryLoader( DictionaryLoader dl )
        { singleton.s_setDictionaryLoader( dl ); }

        void reloadLocalizations()
        { singleton.s_reloadLocalizations(); }

        wstring opIndex(string str)
        { return singleton.s_opIndex(str); }

        void setLocalization( string lang )
        { singleton.s_setLocalization( lang ); }

        @property string[] usedKeys()
        { return singleton.s_usedKeys(); }

        void store() { singleton.s_store(); }
    }

    debug static
    {
        private
        {
            struct KeyUsage { string file; size_t line; }

            KeyUsage[][string] keys;

            @property void useKey(string str)(string file, size_t line)
            {
                if( str !in keys ) keys[str] = [];
                keys[str] ~= KeyUsage(file, line);
            }
        }

        const(KeyUsage[][string]) getKeysUsage() { return keys; }
    }
}

@property wstring _(string str, string cfile=__FILE__, size_t cline=__LINE__)(string file=__FILE__, size_t line=__LINE__)
{
    debug(printlocalizationkeys)
        pragma(msg, ct_formatKey(str,cfile,cline) );
    debug Translator.useKey!str(file,line);
    return Translator[str];
}

private string ct_formatKey( string str, string file, size_t line )
{ return format( "localization key '%s' at %s:%d", str, file, line ); }

void setTranslatePath( string dir )
{ Translator.setDictionaryLoader( new DirDictionaryLoader( dir ) ); }

static ~this() { Translator.store(); }
