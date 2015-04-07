module des.util.arch.tree;

import std.traits;
import std.string;
import std.algorithm;
import std.exception;

import des.util.testsuite;

///
class TNodeException : Exception
{
    this( string msg, string file=__FILE__, size_t line=__LINE__ )
    { super( msg, file, line ); }
}

///
class TNodeCycleException : TNodeException
{
    this( string file=__FILE__, size_t lien=__LINE__ )
    { super( "cycle detect", file, line ); }
}

///
class TNodeNullChildException : TNodeException
{
    this( string file=__FILE__, size_t lien=__LINE__ )
    { super( "can't append null child", file, line ); }
}

///
template TNode(T,string prefix="",string suffix="")
{
interface TNode
{
    mixin( replaceWords!(wordWrapFunc!(prefix,suffix))(q{
    public
    {
        alias T %NodeType;

        @property
        {
            %NodeType %parent();
            const(%NodeType) %parent() const;
            %NodeType %parent( %NodeType p );

            %NodeType[] %childs();
            const(%NodeType[]) %childs() const;
        }

        final bool %findInChilds( const(%NodeType) obj ) const
        {
            foreach( ch; %childs )
            {
                if( obj == ch ) return true;
                if( ch.%findInChilds(obj) ) return true;
            }
            return false;
        }

        void %attachChilds( %NodeType[] att... );
        void %detachChilds( %NodeType[] att... );
    }

    protected
    {
        void %attachCallback( %NodeType[] att );
        void %detachCallback( %NodeType[] det );
    }

    void __%simpleSetParent( %NodeType p );

    mixin template %TNodeHelper(bool __%release_cycle_check=false,
                                bool __%release_nullchild_check=false )
    {
        protected
        {
            import std.traits;
            override
            {
                static if( isAbstractFunction!%attachCallback )
                    void %attachCallback( %NodeType[] att ){}
                static if( isAbstractFunction!%detachCallback )
                    void %detachCallback( %NodeType[] det ){}
            }

            %NodeType __%parent_node;
            %NodeType[] __%childs_list;
        }

        void __%simpleSetParent( %NodeType p ) { __%parent_node = p; }

        public @property
        {
            %NodeType %parent() { return __%parent_node; }
            const(%NodeType) %parent() const { return __%parent_node; }

            %NodeType %parent( %NodeType p )
            {
                if( __%parent_node !is null )
                    __%parent_node.%detachChilds( this );
                __%parent_node = p;
                if( __%parent_node !is null )
                    __%parent_node.%attachChilds( this );
                return p;
            }

            %NodeType[] %childs() { return __%childs_list; }
            const(%NodeType[]) %childs() const { return __%childs_list; }

            %NodeType[] %childs( %NodeType[] nch )
            {
                __%childs_list = nch;
                return nch;
            }
        }

        final
        {
            public void %attachChilds( %NodeType[] att... )
            in { assert( att.length > 0 ); } body
            {
                import std.exception;
                import des.util.arch.tree;
                debug enum DEBUG = true; else enum DEBUG = false;

                static if( __%release_nullchild_check || DEBUG )
                    foreach( el; att )
                        enforce( el !is null, new TNodeNullChildException );

                static if( __%release_cycle_check || DEBUG )
                    enforce( %cycleCheck( att ), new TNodeCycleException );

                foreach( el; att )
                {
                    if( %findInChilds( el ) ) continue;
                    if( el.%parent !is null )
                        el.%parent.%detachChilds( el );
                    __%childs_list ~= el;
                    el.__%simpleSetParent( this );
                }
                %attachCallback( att );
            }

            public void %detachChilds( %NodeType[] det... )
            {
                %NodeType[] buf;
                foreach( ch; %childs )
                    foreach( d; det )
                        if( ch != d )
                            buf ~= ch;
                foreach( d; det )
                    d.__%simpleSetParent( null );
                %childs = buf;
                %detachCallback( det );
            }

            protected bool %cycleCheck( const(%NodeType)[] list... ) const
            {
                const(%NodeType)[] plist = [this];

                while( plist[$-1].%parent )
                    plist ~= plist[$-1].%parent;

                foreach( p; plist )
                    foreach( elem; list )
                        if( elem.%findInChilds(p) )
                            return false;

                return true;
            }
        }
    }
}));
}
}

///
unittest
{
    static class Test : TNode!(Test,"","XX")
    {
        mixin TNodeHelperXX!(true,true);

        string name;
        this( string name ) { this.name = name; }

        void append( string kk )
        {
            name ~= kk;
            foreach( ch; childsXX )
                ch.append( kk );
        }
    }

    auto e0 = new Test("a");
    auto e1 = new Test("b");
    auto e2 = new Test("c");
    auto e3 = new Test("d");

    e1.parentXX = e0;
    e2.parentXX = e1;

    e0.append( "ok" );

    e1.attachChildsXX( e3 );

    assertEq( e0.childsXX, [ e1 ] );
    assertEq( e0.name, "aok" );
    assertEq( e1.name, "bok" );
    assertEq( e3.name, "d" );
    assertEq( e3.parentXX, e1 );
}

///
unittest
{
    static class Test : TNode!(Test,"a_"), TNode!(Test,"b_")
    {
        mixin a_TNodeHelper!(true,true);
        mixin b_TNodeHelper!(true,true);

        string name;
        this( string name ) { this.name = name; }

        void append( string kk )
        {
            name ~= kk;
            foreach( ch; b_childs )
                ch.append( kk );
        }
    }

    auto e0 = new Test("e0");
    auto e1 = new Test("e1");
    auto e2 = new Test("e2");
    auto e3 = new Test("e3");

    e2.a_parent = e0;
    e2.b_parent = e1;

    e0.append( "ok" );

    assert( e0.name == "e0ok" );
    assert( e2.name == "e2" );
}

///
unittest
{
    static interface Node : TNode!Node
    {
        mixin template NodeHelper() { mixin TNodeHelper!true; }
        void inc_self();

        final void inc()
        {
            inc_self();
            foreach( ch; childs )
                ch.inc();
        }
    }

    static class Test : Node
    {
        mixin NodeHelper;

        int i;
        this( int i ) { this.i = i; }
        void inc_self() { i++; }
    }

    auto a0 = new Test(10);
    auto a1 = new Test(15);
    a0.attachChilds( a1 );

    a0.inc();

    assert( a0.i == 11 );
    assert( a1.i == 16 );
}

///
unittest
{
    static class Test : TNode!Test { mixin TNodeHelper!(true, true); }

    auto a0 = new Test;
    auto a1 = new Test;
    auto a2 = new Test;

    assert( a0.parent is null );
    assert( a1.parent is null );
    assert( a2.parent is null );

    a0.attachChilds( a1 );
    a1.attachChilds( a2 );

    assert( a0.childs.length == 1 );
    assert( a1.childs.length == 1 );

    assert( mustExcept!TNodeCycleException({ a2.attachChilds(a0); }) );
    assert( mustExcept!TNodeNullChildException({ a2.attachChilds(null); }) );
}

unittest
{
    static class Test : TNode!(Test,"a") { mixin aTNodeHelper!(true, true); }
    auto a0 = new Test;
    assert( a0.aParent is null );
}

private
{
    string replaceWords(alias fun)( string s ) pure
    {
        string ret;
        string buf;
        size_t p0 = 0, p1 = 0;
        while( p1 < s.length )
        {
            if( s[p1] == '%' )
            {
                ret ~= s[p0..p1];
                p0 = ++p1;
                while( p1 < s.length && identitySymbol(s[p1]) )
                    p1++;
                ret ~= fun(s[p0..p1]);
                p0 = p1;
            }
            else if( p1 == s.length - 1 )
                ret ~= s[p0..p1];
            p1++;
        }
        return ret;
    }

    pure bool identitySymbol( char c )
    {
        switch(c)
        {
            case 'a': .. case 'z': case 'A': .. case 'Z':
            case '_': case '0': .. case '9': return true;
            default: return false;
        }
    }

    pure bool identityString( string s )
    {
        foreach( c; s )
            if( !identitySymbol(c) ) return false;
        return true;
    }

    template wordWrapFunc(string pre, string suf)
    {
        import std.exception;
        static assert( identityString(pre) );
        static assert( identityString(suf) );
        string wordWrapFunc( string a )
        {
            enforce( a.length );
            if( pre.length && pre[$-1] != '_' )
                a = (""~a[0]).toUpper ~ a[1..$];
            return pre ~ a ~ suf;
        }
    }
}
