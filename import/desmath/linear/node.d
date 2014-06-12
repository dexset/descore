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

module desmath.linear.node;

public import desmath.linear.matrix;

interface Node
{
    @property mat4 self() const;
    @property Node parent();
}

class Resolver
{
    mat4 opCall( Node obj, Node cam )
    {
        Node[] obj_branch, cam_branch;
        obj_branch ~= obj;
        cam_branch ~= cam;

        while( obj_branch[$-1] )
            obj_branch ~= obj_branch[$-1].parent;
        while( cam_branch[$-1] )
            cam_branch ~= cam_branch[$-1].parent;

        top: 
        foreach( cbi, camparents; cam_branch )
            foreach( obi, objparents; obj_branch )
                if( camparents == objparents )
                {
                    cam_branch = cam_branch[0 .. cbi+1];
                    obj_branch = obj_branch[0 .. obi+1];
                    break top;
                }

        mat4 obj_mtr, cam_mtr;

        foreach( node; obj_branch )
            if( node ) obj_mtr = node.self * obj_mtr;
            else break;

        foreach( node; cam_branch )
            if( node ) cam_mtr = cam_mtr * node.self.speedTransformInv;
            else break;

        return cam_mtr * obj_mtr;
    }
}
