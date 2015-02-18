module des.util.arch.emm;

import des.util.arch.tree;

///
interface ExternalMemoryManager : TNode!(ExternalMemoryManager,"","EMM")
{
    ///
    mixin template EMM(string file=__FILE__,size_t line=__LINE__)
    {
        static if( !is(typeof(__EMM_BASE_IMPLEMENT)) )
        {
            protected enum __EMM_BASE_IMPLEMENT = true;

            mixin TNodeHelperEMM!(true,true,true);

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
        T registerChildEMM(T)( T obj )
            if( is( T == class ) || is( T == interface ) )
        {
            auto cemm = cast(ExternalMemoryManager)obj;
            if( cemm ) attachChildsEMM( cemm );
            return obj;
        }

        ///
        T[] registerChildEMM(T)( T[] objs )
            if( is( T == class ) || is( T == interface ) )
        {
            foreach( obj; objs )
                registerChildEMM( obj );
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
}

version(todos) pragma(msg,__FILE__, "TODO: add unittests");
