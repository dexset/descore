module des.space.resolver;

public import des.math.linear.vector;
public import des.math.linear.matrix;
public import des.space.node;

/++
   resolve transform matrix from obj space node to cam space node
   +/
class Resolver
{
    ///
    mat4 opCall( const(SpaceNode) obj, const(SpaceNode) cam ) const
    {
        const(SpaceNode)[] obj_branch, cam_branch;
        obj_branch ~= obj;
        cam_branch ~= cam;

        while( obj_branch[$-1] )
            obj_branch ~= obj_branch[$-1].spaceParent;
        while( cam_branch[$-1] )
            cam_branch ~= cam_branch[$-1].spaceParent;

        top:
        foreach( cbi, cam_parent; cam_branch )
            foreach( obi, obj_parent; obj_branch )
                if( cam_parent == obj_parent )
                {
                    cam_branch = cam_branch[0 .. cbi];
                    obj_branch = obj_branch[0 .. obi];
                    break top;
                }

        mat4 obj_mtr, cam_mtr;

        foreach( node; obj_branch )
            obj_mtr = node.matrix * obj_mtr;

        foreach( node; cam_branch )
            cam_mtr = cam_mtr * node.matrix.speedTransformInv;

        return cam_mtr * obj_mtr;
    }
}
