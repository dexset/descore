import des.util.logsys;

// write log to string array
synchronized class StringLogOutput : LogOutput
{
    string[] result;

protected:
    override void write( in LogMessage, string msg )
    { result ~= msg; }

    override string formatLogMessage( in LogMessage lm ) const
    { return format( "[%s]: %s", lm.level, lm.message ); }
}

// skip logoutput system
class FastStderrLogger : Logger
{
    protected override void writeLog( in LogMessage lm ) const
    { stderr.writeln( defaultFormatLogMessage( lm ) ); }
}

class A
{
    mixin ClassLogger;

    this()
    {
        logger = new FastStderrLogger;
        callAll();
    }

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

void main()
{
    auto slo = new shared StringLogOutput;
    logoutput.append( "string", slo );
    logoutput.disable( "console" );

    scope a = new A;

    logger.fatal( "fatal message" );
    logger.error( "error message" );
    logger.warn( "warn message" );
    logoutput.enable( "console" );
    logger.info( "info message" );
    logger.Debug( "debug message" );
    logger.trace( "trace message" );

    stdout.writeln( "log result: ", slo.result );
}
