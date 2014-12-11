### Simple using

Package provides `static Logger logger`

```d
void logger.error(Args...)( Args args );
void logger.warn (Args...)( Args args );
void logger.info (Args...)( Args args );
void logger.Debug(Args...)( Args args );
void logger.trace(Args...)( Args args );
```

```d
...
    logger.info( "format %s %f %d", "str", 3.14, 4 );
    logger.Debug( "some info" );
    logger.trace( 12 );
...
```

If program starts as `./program --log trace` output must be like this

```
[000000.111427128][ INFO][module.function]: format str 3.14 4
[000000.111427128][DEBUG][module.function]: some info
[000000.111938579][TRACE][module.function]: 12
```

If log function has string as first argument it tries to format other args to this
string, if it failed print converted to string and concatenated args.

If program starts as `./program --log debug` output must be like this (without trace)

```
[000000.111427128][ INFO][module.function]: format str 3.14 4
```

Flag `--log` used for setting max level of logging output.
Default level is `error`. If log function called with greater level it's skipped.
Level has attitudes `off < fatal < error < warn < info < debug < trace`.

Flag `--log` can be used with module name `./program --log draw.point:debug`.
It will set `debug` level for module `draw.point` and default to other.

Flag `--log-use-min` is boolean flag. It forces logging system to skip output from
all child modules if their level greater than parent. Default is `false`.

`./program --log trace --log draw:info --log draw.point:trace --log-use-min=true` 
skips all output from `logger.trace` and `logger.Debug` from whole draw.point,
and doesn't skip from other modules.

`./program --log trace --log draw:info --log draw.point:trace` allow `log_trace`
and `log_debug` only from `draw.point` from module `draw`. For other modules in
`draw` sets level `info`

You can compile program with `version=logonlyerror` for skip all
`trace`, `debug`, `info` and `warn` outputs in logger. It can improve program
release speed.

### Class logging

Module provides some functional for useful logging classes.

Example:

```d
module x;
import des.util.logger;
class A
{
    mixin ClassLogger;
    void func() { logger.trace( "hello" ); }
}
```

```d
module y;
import x;
class B : A { }
```

```d
...
    auto b = new B;
...
    b.func();
...
```

outputs `[000000.148628473][TRACE][x.A.func]: hello`

If create instance logger 

```d
class B : A { this(){ logger = new InstanceLogger(this); } }
```
outputs `[000000.148628473][TRACE][y.B.func]: hello`

If create instance logger with instance name

```d
class B : A { this(){ logger = new InstanceLogger(this,"my object"); } }
```
outputs `[000000.148628473][TRACE][y.B.[my object].func]: hello`

If create instance full logger

```d
class B : A { this(){ logger = new InstanceFullLogger(this); } }
```
outputs `[000000.148628473][TRACE][y.B.[x.A.func]]: hello`

If create instance full logger with name

```d
class B : A { this(){ logger = new InstanceFullLogger(this,"name"); } }
```
outputs `[000000.148628473][TRACE][y.B.[name].[x.A.func]]: hello`

Flag `--log` can get full emitter string `y.B.[name].[x.A.func]`.
```
./program --log "y.B.[one]:trace" --log "y.B.[two]:debug"
```
### `class Logger`

Base Logger class

##### public methods:

```d
void error(Args...)( Args args ) const nothrow
void warn (Args...)( Args args ) const nothrow
void info (Args...)( Args args ) const nothrow
void Debug(Args...)( Args args ) const nothrow
void trace(Args...)( Args args ) const nothrow
```
##### protected methods:

- `void writeLogFailPrint( Exception e ) const nothrow` - if writing to log is
  failed, this function calls

- `void writeLog( in LogMessage lm ) const` - writing to log output

- `string chooseOutputName( in LogMessage lvl ) const` - default return
  "console"

- `string procEmitterName( string name ) const nothrow` - transform emitter name

### `class InstanceLogger : Logger`

Logging class instances

##### ctors:

- `this( Object obj, string inst="" )` - get object and instance name

- `this( string obj, string inst="" )` - get object name and instance name

### `class InstanceFullLogger : InstanceLogger`

Logging class instances with names of base classes

##### ctors same as `InstanceLogger`

### `synchronized abstract class LogOutput`

Base class for log output

##### protected methods:

- `abstract void write( in LogMessage, string )`

- `string formatLogMessage( in LogMessage lm ) const`

### `synchronized class FileLogOutput : LogOutput`

File output

##### ctors:

- `this( string filename )`

### `synchronized final class LogOutputHandler`

##### publid property:

- `bool broadcast` - if true all log messages writes to all enabled outputs,
                     else writes only to target output

##### publid methods:

- `void enable( string name )` - enable output by name

- `void disable( string name )` - disable output by name

- `void append( string name, shared LogOutput output )` - append output and
  enable it

- `void remove( string name )` - remove output
