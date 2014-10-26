### Simple using

Package has 5 functions for simple logging:

```d
void log_error(Args...)( Args args );
void log_warn (Args...)( Args args );
void log_info (Args...)( Args args );
void log_debug(Args...)( Args args );
void log_trace(Args...)( Args args );
```

```d
...
    log_info( "format %s %f %d", "str", 3.14, 4 );
    log_debug( "some info" );
    log_trace( 12 );
...
```

If start program as `./program --log trace` output must be like this

```
[000000.111427128][ INFO][module.function]: format str 3.14 4
[000000.111427128][DEBUG][module.function]: some info
[000000.111938579][TRACE][module.function]: 12
```

If start program as `./program --log debug` output must be like this (without trace)

```
[000000.111427128][ INFO][module.function]: format str 3.14 4
```

Flag `--log` used for setting max level of logging output.
Default level is `error`. If log function called with greater level it's skipped.
Level has attitude `off < error < warn < info < debug < trace`.

Flag `--log` may used with module name `./program --log draw.point:debug`.
It's set `debug` level for module `draw.point` and default to other.

Flag `--log-use-min` is boolean flag. It makes logging system skips output from
all child modules if their level greater that parent. Default is `false`.

`./program --log trace --log draw:info --log draw.point:trace --log-use-min=true` 
skips all `log_trace` and `log_debug` from whole draw.point, and not skip from
other modules.

`./program --log trace --log draw:info --log draw.point:trace` allow `log_trace`
and `log_debug` only from `draw.point` from module `draw`. For other modules in
`draw` sets level `info`

### Class logging

Module des.util.logger provides some functional for useful logging classes.

Example:

```d
module x;
import des.util.logger;
class A
{
    mixin AnywayLogger;
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
./program --log y.B.[one]:trace --log y.B.[two]:debug
```
