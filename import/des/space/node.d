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

module des.space.node;

public import des.math.linear.vector;
public import des.math.linear.matrix;
public import des.space.transform;

import des.util.object.tree;

interface SpaceNode : Transform, TNode!(SpaceNode,"space")
{
    mixin template SpaceNodeHelper(bool with_matrix_property=true)
    {
        mixin spaceTNodeHelper!(true,true,true);

        protected mat4 self_mtr;

        static if( with_matrix_property )
            mat4 matrix() @property const { return self_mtr; }
    }

    const @property
    {
        /+ local to parent transform +/
        mat4 matrix();

        final
        {
            vec3 baseX() { return vec3( matrix.col(0).data[0 .. 3] ); }
            vec3 baseY() { return vec3( matrix.col(1).data[0 .. 3] ); }
            vec3 baseZ() { return vec3( matrix.col(2).data[0 .. 3] ); }

            /+ in parent system +/
            vec3 offset() { return vec3( matrix.col(3).data[0 .. 3] ); }
        }
    }
}

final class DimmyNode : SpaceNode
{
    mixin SpaceNodeHelper!false;

    this( SpaceNode par = null ) { spaceParent = par; }

    @property
    {
        mat4 matrix() const { return self_mtr; }
        ref mat4 matrix() { return self_mtr; }
    }

    void setOffset( in vec3 pnt ) { self_mtr.setCol(3,vec4(pnt,1)); }
}
