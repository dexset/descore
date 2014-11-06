ExternalMemoryManager is used when class manipulate some raw data and must free it then work is finished.
For example OpenGL wrapers must free data when on destroy.
Standart destructor mechanism does not provide immediate free data.

ExternalMemoryManager can store other EMM's and then call `destroy()` for
it `destroy()` calls for all stored EMM's.

ExternalMemoryManager can store other EMM's and call `destroy()` for all of them when necessary.

##### Example:

```d
import des.util.emm;

class RawHandler : ExternalMemoryManager
{
    mixin DirectEMM; // you must implement selfDestroy()

    protected void selfDestroy() { ... free some data ...  }
}

class Parent : ExternalMemoryManager
{
    mixin ParentEMM;

    RawHandler a;
    RawHandler b;

    RawHandler func() { return new RawHandler; }

    this()
    {
        // all child EMM's must be stored

        // when child EMM is returned from function
        a = registerChildEMM( func() );

        // when child EMM is created
        b = newEMM!RawHandler( ... args for RawHandler ctor ... );
    }
}
```

If object isn't EMM `registerChildEMM` and `newEMM` doesn't throw any exceptions,
object will be returned as is.
