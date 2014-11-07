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

interface ExternalMemoryManager
{
    mixin template DirectEMM()
    {
        private ExternalMemoryManager[] chemm;
        private bool is_destroyed = false;

        protected final ref ExternalMemoryManager[] childEMM() { return chemm; }

        public final bool isDestroyed() const { return is_destroyed; }
        protected final void isDestroyed( bool d ) { is_destroyed = d; }
    }

    mixin template ParentEMM()
    {
        mixin DirectEMM;
        protected void selfDestroy() {}
    }

    protected
    {
        @property ref ExternalMemoryManager[] childEMM();
        void selfDestroy();

        @property void isDestroyed( bool d );
    }

    @property bool isDestroyed() const;

    final
    {
        T registerChildEMM(T)( T obj )
            if( is( T == class ) || is( T == interface ) )
        {
            auto cemm = cast(ExternalMemoryManager)obj;
            if( cemm ) childEMM ~= cemm; 
            return obj;
        }

        T[] registerChildEMM(T)( T[] objs )
            if( is( T == class ) || is( T == interface ) )
        {
            foreach( obj; objs )
                registerChildEMM( obj );
            return objs;
        }

        T newEMM(T,Args...)( Args args )
        { return registerChildEMM( new T(args) ); }

        void destroy()
        {
            if( isDestroyed ) return;
            foreach( cemm; childEMM )
                cemm.destroy();
            selfDestroy();
            isDestroyed = true;
        }
    }
}
