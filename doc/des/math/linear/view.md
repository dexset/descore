## Module view

Package view provides 4 modules:

- transform - basic module
- node - interface for drawing objects
- resolver - calc full transform matrix
- camera - node for using as camera

### Module transform

#### `interface Transform`

methods:

- `@property mat4 matrix() const;` - you must implement in your realisation
    of Transform interface. This method must return transform matrix from local
    coord system to global.

- `protected final static mat4 getMatrix( const(Transform) tr );` - returns
    identiny matrix if tr is null, and `tr.matrix` otherwise.

#### `class SimpleTransform : Transform`

implement matrix 

```d
    @property
    {
        mat4 matrix() const { return mtr; }
        void matrix( in mat4 m ) { mtr = m; }
    }
```

#### `class TransformList : Transform`

fields:

- `Transform[] list`
- `Order order = Order.DIRECT` - can be `Order.REVERSE`

methods:

- `@property mat4 matrix() const` - return result of multiplication
of `list` matrix by order.

#### `class CachedTransform : Transform`

protected fields: 

- `mat4 mtr` - cached matrix
- `Transform transform_source`

methods:

- `void setTransform( Transform ntr )` - set new transform source and recalc
- `void recalc()` - set `mtr` as `transform_source.matrix` if `transform_source`
  isn't `null`, identity otherwise.

### Module node

#### `interface Node : Transform`

methods:

- `@property mat4 matrix() const` - need implement (`Transform`) - local to
  parent transform matrix
- `@property const(Node) parent() const` - needs for resolving full transform
  matrix
- `final @property vec3 baseX() const` - base X vector of coord sys
- `final @property vec3 baseY() const` - base Y vector of coord sys
- `final @property vec3 baseZ() const` - base Z vector of coord sys
- `final @property vec3 offset() const` - offset in parent system

### Module resolver

#### `class Resolver`

public methods:

- `mat4 opCall( const(Node) obj, const(Node) cam ) const` - calc full transform
  matrix from `obj` coord system to `cam` coord system

### Module camera

#### `class Camera: Node`

protected fields:

- `Node _parent`

public fields:

- `Resolver resolver` - for full transform matrix calculation
- `Transform projection` - present projection matrix
- `Transform transform` - present view matrix

public methods:

- `this( Node parent=null )` - set parent and create new resolver
- `mat4 resolve( const(Node) obj ) const` - return full transform matrix
- `mat4 opCall( const(Node) obj ) const` - return full transform matrix with projection if it
  isn't `null`
- `@property mat4 matrix() const` - return `transform.matrix` if it isn't
  `null`, identity otherwise
- `@property const(Node) parent() const` - return `_parent`

#### `class LookAtTransform : Transform`

public fields:

- `vec3 pos=vec3(0)` - point from which looks
- `vec3 target=vec3(0)` - point where looks
- `vec3 up=vec3(0,0,1)` - up direction

public methods:

- `@property mat4 matrix() const` - return lookAt transform matrix

#### `abstract class ResolveTransform : Transform`

protected fields:

- `Resolver resolver`

public methods:

- `void setResolver( Resolver rsl )`
- `abstract @property mat4 matrix() const`

#### `class LookAtNodeTransform : ResolveTransform`

use `Node` instead of `vec3`

public fields:

- `Node center` - as pos
- `Node target`
- `Node up`

public methods:

- `@property mat4 matrix() const` - return lookAt transform matrix

#### `class PerspectiveTransform : Transform`

public fields:

- `float fov = 70`
- `float ratio = 4.0f / 3.0f`
- `float near = 1e-1`
- `float far = 1e5`

public methods:

- `@property mat4 matrix() const` - return perspective projection matrix

#### `class SimpleCamera : Camera`

Camera with `LookAtTransform` as `transform` and `PerspectiveTransform` as
`projection`

protected fields:

- `LookAtTransform look_tr`
- `PerspectiveTransform perspective`

public methods:

- `this( Node parent=null )` - create new `LookAtTransform` and
  `PerspectiveTransform` objects and sets to `transform` and `projection`

public propertyes (meaning same in `LookAtTransform` and
`PerspectiveTransform`):

- `void fov( float val )`
- `float fov() const`
- `void ratio( float val )`
- `float ratio() const`
- `void near( float val )`
- `float near() const`
- `void far( float val )`
- `float far() const`
- `void pos( in vec3 val )`
- `vec3 pos() const`
- `void up( in vec3 val )`
- `vec3 up() const`
- `void target( in vec3 val )`
- `vec3 target() const`

## Using example

```d

class SomeDrawObject : Node
{
    ...

    protected mat4 mtr;

    ...


    const @property
    {
        mat4 matrix() { return mtr; }
        const(Node) parent() { return null; } // always no parent, world coord sys
    }
}

auto cam = new SimpleCamera;
auto obj = new SomeDrawObject;

auto tr = cam(obj);

// and now you can
someAPI_setTransform(tr);
drawObject( obj );
```
