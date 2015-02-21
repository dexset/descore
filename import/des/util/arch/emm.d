module des.util.arch.emm;

import des.util.arch.tree;

import des.util.testsuite;

///
interface ExternalMemoryManager : TNode!(ExternalMemoryManager,"","EMM")
{
    protected
    {
        ///
        @property void isDestroyed( bool d );

        ///
        void selfConstruct();
        ///
        void selfDestroy();
        ///
        void preChildsDestroy();
    }

    ///
    @property bool isDestroyed() const;

    final
    {
        ///
        T registerChildEMM(T)( T obj, bool if_orphan=false )
            if( is( T == class ) || is( T == interface ) )
        {
            if( auto cemm = cast(ExternalMemoryManager)obj )
                if( ( if_orphan && cemm.parentEMM is null ) || !if_orphan )
                    attachChildsEMM( cemm );
            return obj;
        }

        ///
        T[] registerChildEMM(T)( T[] objs, bool if_orphan=false )
            if( is( T == class ) || is( T == interface ) )
        {
            foreach( obj; objs )
                registerChildEMM( obj, if_orphan );
            return objs;
        }

        ///
        T newEMM(T,Args...)( Args args )
        { return registerChildEMM( new T(args) ); }

        ///
        void destroy()
        {
            if( isDestroyed ) return;
            preChildsDestroy();
            foreach( cemm; childsEMM )
                cemm.destroy();
            selfDestroy();
            isDestroyed = true;
        }
    }

    ///
    mixin template EMM(string file=__FILE__,size_t line=__LINE__)
    {
        static if( !is(typeof(__EMM_BASE_IMPLEMENT)) )
        {
            protected enum __EMM_BASE_IMPLEMENT = true;

            mixin TNodeHelperEMM!(true,true);

            private bool is_destroyed = false;
            public final bool isDestroyed() const { return is_destroyed; }
            protected final void isDestroyed( bool d )
            {
                bool change = is_destroyed != d;
                is_destroyed = d;
                if( change && !is_destroyed )
                    selfConstruct();
            }

            import std.traits;

            protected override
            {
                static if( isAbstractFunction!selfConstruct ) void selfConstruct() {}
                static if( isAbstractFunction!selfDestroy ) void selfDestroy() {}
                static if( isAbstractFunction!preChildsDestroy ) void preChildsDestroy() {}
            }
        }
        else
        {
            version(emmcheck)
                pragma(msg, format( "WARNING: duplicate mixin EMM at %s:%d", file, line ) );
        }
    }
}

unittest
{
    string[] log;

    class Test : ExternalMemoryManager
    {
        mixin EMM;
        string name;
        this( string name ) { this.name = name; }
    protected:
        void preChildsDestroy()
        { log ~= name ~ ".preChildsDestroy"; }
        void selfDestroy()
        { log ~= name ~ ".selfDestroy"; }
    }

    auto a = new Test( "a" );
    auto b = new Test( "b" );
    auto c = new Test( "c" );
    auto d = new Test( "d" );

    assertNull( a.parentEMM );
    assertNull( b.parentEMM );
    assertNull( c.parentEMM );
    assertNull( d.parentEMM );

    assertNull( a.childsEMM );
    assertNull( b.childsEMM );
    assertNull( c.childsEMM );
    assertNull( d.childsEMM );

    a.registerChildEMM( b );
    assertEq( a.childsEMM.length, 1 );
    assertEq( a.childsEMM[0], b );
    assertEq( b.parentEMM, a );

    c.registerChildEMM( b );
    assertEq( a.childsEMM.length, 0 );
    assertEq( c.childsEMM.length, 1 );
    assertEq( c.childsEMM[0], b );
    assertEq( b.parentEMM, c );

    a.registerChildEMM( b, true );
    assertEq( a.childsEMM.length, 0 );
    assertEq( c.childsEMM.length, 1 );
    assertEq( c.childsEMM[0], b );
    assertEq( b.parentEMM, c );

    a.registerChildEMM( b );
    assertEq( a.childsEMM.length, 1 );
    assertEq( a.childsEMM[0], b );
    assertEq( b.parentEMM, a );
    assertEq( c.childsEMM.length, 0 );

    mustExcept({ b.registerChildEMM( a ); });

    a.registerChildEMM( d );
    assertEq( a.childsEMM.length, 2 );
    assertEq( a.childsEMM[1], d );

    d.destroy();
    assertEq( a.childsEMM.length, 2 );
    assertEq( log, [ "d.preChildsDestroy", "d.selfDestroy" ] );

    assertNull( c.parentEMM );
    assertNull( c.childsEMM );

    a.destroy();
    assertEq( log, [ "d.preChildsDestroy",
                     "d.selfDestroy",
                     "a.preChildsDestroy",
                     "b.preChildsDestroy",
                     "b.selfDestroy",
                     "a.selfDestroy"
                   ] );
}
