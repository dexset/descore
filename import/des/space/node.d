module des.space.node;

public import des.math.linear.vector;
public import des.math.linear.matrix;
public import des.space.transform;

import des.util.arch.tree;

///
interface SpaceNode : Transform, TNode!(SpaceNode,"space")
{
    ///
    mixin template SpaceNodeHelper(bool with_matrix_property=true)
    {
        mixin spaceTNodeHelper!(true,true,true);

        protected mat4 self_mtr;

        static if( with_matrix_property )
            mat4 matrix() @property const { return self_mtr; }
    }

    const @property
    {
        /// local to parent transform
        mat4 matrix();

        final
        {
            ///
            vec3 baseX() { return vec3( matrix.col(0).data[0 .. 3] ); }
            ///
            vec3 baseY() { return vec3( matrix.col(1).data[0 .. 3] ); }
            ///
            vec3 baseZ() { return vec3( matrix.col(2).data[0 .. 3] ); }

            /// in parent system
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
