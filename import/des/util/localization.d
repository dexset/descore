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

/+

[code]
    mixin( useTranslatorMixin( "translate/dir" ) );

    writeln( _!"hello" );

    Translator.setLocalization( "ru" );

    writeln( _!"hello" );
    writeln( _!"world" );
[code]

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
import std.typecons;

/+ TODO: логирование +/
void info_log(Args...)(Args args)
{ stdout.writefln( args ); }

void error_log(Args...)(Args args)
{ stderr.writefln( args ); }

void debug_log(string file=__FILE__, size_t line=__LINE__, Args...)(Args args)
{ stderr.writefln( "%s:%d %s", file, line, format(args) ); }

interface WordConverter { wstring opIndex( string key ); }

interface Localization : WordConverter
{
    public const @property string name();
    public bool has( string key );
    protected wstring notFound( string key );
}

class DictionaryLoaderException : Exception
{
    @safe pure nothrow this( string msg, string file=__FILE__, int line=__LINE__ ) 
    { super( msg, file, line ); } 
}

interface DictionaryLoader { Localization[string] load(); }

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
        error_log( "no translation for key '%s' in dict '%s'", key, name );
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
            error_log( e.msg );
            return (Localization[string]).init;
        }

        auto ret = loadLocalizations( path );
        checkLocalizations( ret, base );
        return ret;
    }

    static void writeBase( string path, lazy string[] keys )
    {
        if( !path.exists )
        {
            mkdirRecurse( path );
            info_log( "create localization path '%s'", path );
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

        //auto name = splitLine( f.byLine().front.idup )[0];
        auto name = getLabel( fname );

        wstring[string] dict;

        foreach( ln; f.byLine() )
            processLine( dict, strip(ln.idup) );

        return new BaseLocalization( name, dict );
    }

    static auto splitLine( string ln )
    {
        auto bf = ln.split(":");
        return tuple( bf[0], to!wstring(bf[1]) );
    }

    static void processLine( ref wstring[string] d, string line )
    {
        if( line.length == 0 ) return;
        auto ln = splitLine( line );
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
                    error_log( "dict '%s' has no key '%s'", lang, key );
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
        reloadLocalizations();
    }

    void s_reloadLocalizations()
    {
        if( dict_loader is null )
        {
            error_log( "dictionary loader not setted: no reloading" );
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

        info_log( "no current localization: use source string" );

        return to!wstring(str);
    }

    void s_setLocalization( string lang )
    {
        if( lang in localizations )
            currentLocalization = localizations[lang];
        else error_log( "no localization '%s'", lang );
    }

    string[] s_usedKeys() { return used_keys.keys; }

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

string useTranslatorMixin( string dir )
{
    return format(`
    Translator.setDictionaryLoader( new DirDictionaryLoader( "%1$s" ) );
    scope(exit) DirDictionaryLoader.writeBase( "%1$s", Translator.usedKeys );`,
    dir);
}
