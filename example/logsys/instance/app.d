import des.util.logsys;

class A
{
    mixin ClassLogger;

    this() { logger.info( "ctor A" ); }

    void callAll()
    {
        logger.fatal( "fatal message" );
        logger.error( "error message" );
        logger.warn( "warn message" );
        logger.info( "info message" );
        logger.Debug( "debug message" );
        logger.trace( "trace message" );
    }
}

class B : A
{
    this()
    {
        super();
        logger.trace( "ctor B" );
        callAll();
    }
}

class C : A
{
    this( string name )
    {
        logger = new InstanceFullLogger( this, name );
        super();
        callAll();
    }
}

void main()
{
    scope a = new B;
    scope f = new C( "first" );
    scope s = new C( "second" );
}
