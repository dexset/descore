module des.space.camera;

public import des.space.node;
public import des.space.resolver;

///
interface Camera : SpaceNode
{
    mixin template CameraHelper()
    {
        mixin SpaceNodeHelper!false;

        protected Resolver resolver;
        protected Transform projection, transform;

        const
        {
            mat4 resolve( const(SpaceNode) obj )
            {
                assert( resolver !is null, "resolver is null" );
                return resolver( obj, this );
            }

            @property
            {
                mat4 matrix() { return getMatrix( transform ); }
                mat4 projectMatrix() { return getMatrix( projection ); }
                vec3 offset() { return vec3( matrix.col(3).data[0..3] ); }
            }
        }
    }

    const
    {
        /// get transform matrix from obj local coord system to camera coord system
        mat4 resolve( const(SpaceNode) obj );

        /// `projectMatrix * resolve`
        final mat4 view( const(SpaceNode) obj )
        { return projectMatrix * resolve( obj ); }

        @property
        {
            /// transform from local to parent
            mat4 matrix();
            ///
            mat4 projectMatrix();
            ///
            vec3 offset();
        }
    }
}

/++ simple lookAt perspective/ortho camera +/
class SimpleCamera : Camera
{
    mixin CameraHelper;

protected:

    ///
    LookAtTransform look_tr;
    ///
    PerspectiveTransform perspective;
    ///
    OrthoTransform ortho;

public:

    ///
    this( SpaceNode p=null )
    {
        spaceParent = p;
        resolver = new Resolver;

        look_tr = new LookAtTransform;
        look_tr.up = vec3(0,0,1);
        transform = look_tr;
        perspective = new PerspectiveTransform;
        ortho = new OrthoTransform;
        projection = perspective;
    }

    ///
    void setPerspective() { projection = perspective; }
    ///
    void setOrtho() { projection = ortho; }

    @property
    {
        ///
        bool isPerspective() const { return projection == perspective; }
        ///
        bool isOrtho() const { return projection == ortho; }

        /// for perspective
        void fov( float val ) { perspective.fov = val; }
        /// ditto
        float fov() const { return perspective.fov; }

        /// for ortho
        void scale( float val ) { ortho.scale = val; }
        /// ditto
        float scale() const { return ortho.scale; }

        ///
        void ratio( float val )
        {
            perspective.ratio = val;
            ortho.ratio = val;
        }
        ///
        float ratio() const { return perspective.ratio; }

        ///
        void near( float val )
        {
            perspective.near = val;
            ortho.near = val;
        }
        ///
        float near() const { return perspective.near; }

        ///
        void far( float val )
        {
            perspective.far = val;
            ortho.far = val;
        }
        ///
        float far() const { return perspective.far; }

        ///
        void pos( in vec3 val ) { look_tr.pos = val; }
        ///
        vec3 pos() const { return look_tr.pos; }

        ///
        void up( in vec3 val ) { look_tr.up = val; }
        ///
        vec3 up() const { return look_tr.up; }

        ///
        void target( in vec3 val ) { look_tr.target = val; }
        ///
        vec3 target() const { return look_tr.target; }
    }
}
