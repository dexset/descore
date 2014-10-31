It used if class manipulate some raw data and must free it then finish work.
For example OpenGL wrapers must free data when it destroy.
Standart destructor mechanism does not provide immediate free data.

ExternalMemoryManager can store other EMM's and then call `destroy()` for
it `destroy()` calls for all stored EMM's.

Example:

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
        // all childs EMM's must be stored

        // use if get child EMM from function
        a = registerChildEMM( func() );

        // use if create here
        b = newEMM!RawHandler( ... args for RawHandler ctor ... );
    }
}
```

If object isn't EMM `registerChildEMM` and `newEMM` not throw any exception,
object return as is.
