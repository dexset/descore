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

module desmath.linear.view.node;

public import desmath.linear.vector;
public import desmath.linear.matrix;
public import desmath.linear.view.transform;

interface Node : Transform
{
    const @property
    {
        /+ local to parent transform +/
        mat4 matrix();

        const(Node) parent();

        final
        {
            vec3 baseX() { return vec3( matrix.col!(0).data[0 .. 3] ); }
            vec3 baseY() { return vec3( matrix.col!(1).data[0 .. 3] ); }
            vec3 baseZ() { return vec3( matrix.col!(2).data[0 .. 3] ); }

            /+ in parent system +/
            vec3 offset() { return vec3( matrix.col!(3).data[0 .. 3] ); }
        }
    }
}

final class DimmyNode : Node
{
private:
    Node _parent;
    mat4 _matrix;

public:
    this( Node par = null ) { _parent = par; }

    @property
    {
        mat4 matrix() const { return _matrix; }
        mat4 matrix( in mat4 m ) { _matrix = m; return _matrix; }
        const(Node) parent() const { return _parent; }
        void parent( Node par ) { _parent = par; }
    }

    void setOffset( vec3 pnt )
    {
        matrix[0,3] = pnt.x;
        matrix[1,3] = pnt.y;
        matrix[2,3] = pnt.z;
    }
}

class TransformNode : Node
{
protected:
    Node _parent;

public:
    Transform transform;

    this( Node par = null ) { _parent = par; }

    @property
    {
        mat4 matrix() const
        {
            if( transform !is null )
                return transform.matrix;
            else return mat4.init;
        }

        const(Node) parent() const { return _parent; }
        void parent( Node par ) { _parent = par; }
    }
}
