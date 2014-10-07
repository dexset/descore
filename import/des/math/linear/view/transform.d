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

module des.math.linear.view.transform;

public import des.math.linear.vector;
public import des.math.linear.matrix;

interface Transform
{
    @property mat4 matrix() const;

    protected final static mat4 getMatrix( const(Transform) tr )
    {
        if( tr !is null )
            return tr.matrix;
        return mat4.diag(1);
    }
}

class TransformList : Transform
{
    Transform[] list;

    @property mat4 matrix() const
    {
        mat4 buf;
        foreach( tr; list )
            buf = tr.matrix * buf;
        return buf;
    }
}

class CachedTransform : Transform
{
protected:
    mat4 mtr;
    Transform tform;

public:

    this( Transform ntr ) { setTransform( ntr ); }

    void setTransform( Transform ntr )
    {
        tform = ntr;
        recalc();
    }

    void recalc()
    {
        if( tform !is null ) mtr = tform.matrix;
        else mtr = mat4.diag(1);
    }

    @property mat4 matrix() const { return mtr; }
}
