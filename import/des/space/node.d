module des.space.node;

public import des.math.linear.vector;
public import des.math.linear.matrix;
public import des.space.transform;

import des.util.arch.tree;
import des.util.testsuite;

///
interface SpaceNode : Transform, TNode!(SpaceNode,"space")
{
    /++ past code
     + ---
     + mixin spaceTNodeHelper!(true,true,true);
     + ---
     + 
     + if `with_matrix_field` add `protected mat4 self_mtr` field
     + and realization for `matrix` and `offset` properties (with setters)
     +/
    mixin template SpaceNodeHelper(bool with_matrix_field=true)
    {
        mixin spaceTNodeHelper!(true,true,true);

        static if( with_matrix_field )
        {
            protected mat4 self_mtr;

            public @property
            {
                mat4 matrix() const { return self_mtr; }
                mat4 matrix( in mat4 m ) { self_mtr = m; return m; }

                vec3 offset() const { return vec3( self_mtr.col(3).data[0..3] ); }
                vec3 offset( in vec3 o ) { self_mtr.setCol( 3, vec4( o, matrix[3][3] ) ); return o; }
            }
        }
    }

    const @property
    {
        /// local to parent transform
        mat4 matrix();

        /// in parent system
        vec3 offset();

        final
        {
            /// e1
            vec3 baseX() { return vec3( matrix.col(0).data[0 .. 3] ); }
            /// e2
            vec3 baseY() { return vec3( matrix.col(1).data[0 .. 3] ); }
            /// e3
            vec3 baseZ() { return vec3( matrix.col(2).data[0 .. 3] ); }
        }
    }
}

final class DimmyNode : SpaceNode
{
    mixin SpaceNodeHelper;
    this( SpaceNode par = null ) { spaceParent = par; }
}

unittest
{
    auto tsn = new DimmyNode;

    assertEq( tsn.baseX, vec3( 1,0,0 ) );
    assertEq( tsn.baseY, vec3( 0,1,0 ) );
    assertEq( tsn.baseZ, vec3( 0,0,1 ) );
    assertEq( tsn.offset, vec3( 0,0,0 ) );

    tsn.offset = vec3( 1, 2, 3 );

    assertEq( vec4( tsn.matrix.col(3) ), vec4(1,2,3,1) );
}
