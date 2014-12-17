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

module des.util.object.emm;

import des.util.object.tree;

interface ExternalMemoryManager : TNode!(ExternalMemoryManager,"","EMM")
{
    mixin template EMM()
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
        }
    }

    /+ backward compatibility +/
    mixin template DirectEMM(bool self_construct=true, bool pre_childs_destroy=true)
    {
        mixin EmptyImplementEMM!(false,self_construct,pre_childs_destroy);
    }

    mixin template ParentEMM() { mixin EmptyImplementEMM; }

    mixin template EmptyImplementEMM(bool self_destroy=true,
                                     bool pre_childs_destroy=true,
                                     bool self_construct=true)
    {
        mixin EMM;

        static if( self_construct )
            protected void selfConstruct() {}

        static if( pre_childs_destroy )
            protected void preChildsDestroy() {}

        static if( self_destroy )
            protected void selfDestroy() {}
    }

    protected
    {
        @property void isDestroyed( bool d );

        void selfConstruct();
        void selfDestroy();
        void preChildsDestroy();
    }

    @property bool isDestroyed() const;

    final
    {
        T registerChildsEMM(T)( T obj )
            if( is( T == class ) || is( T == interface ) )
        {
            auto cemm = cast(ExternalMemoryManager)obj;
            if( cemm ) attachChildsEMM( cemm );
            return obj;
        }

        T[] registerChildsEMM(T)( T[] objs )
            if( is( T == class ) || is( T == interface ) )
        {
            foreach( obj; objs )
                registerChildsEMM( obj );
            return objs;
        }

        T newEMM(T,Args...)( Args args )
        { return registerChildsEMM( new T(args) ); }

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
