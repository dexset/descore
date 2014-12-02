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

module des.util.emm;

import des.util.tree;

interface ExternalMemoryManager : TNode!(ExternalMemoryManager,"","EMM")
{
    mixin template DirectEMM(bool with_self_construct=true)
    {
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

        static if( with_self_construct )
            protected void selfConstruct() {}
    }

    mixin template ParentEMM()
    {
        mixin DirectEMM!false;

        protected void selfDestroy() {}
        protected void selfConstruct() {}
    }

    protected
    {
        void selfDestroy();
        void selfConstruct();

        @property void isDestroyed( bool d );
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
            foreach( cemm; childsEMM )
                cemm.destroy();
            selfDestroy();
            isDestroyed = true;
        }
    }
}
