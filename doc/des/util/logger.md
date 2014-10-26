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
Default level is 'error'. If log function called with greater level it's skipped.
Level has attitude `off < error < warn < info < debug < trace`.

