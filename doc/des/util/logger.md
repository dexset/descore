### Simple using

package has 5 functions for simple logging

```d
void log_[level](Args...)( Args args );
```

where [level] one of [ error, warn, info, debug, trace ]

```d
...
    log_info( "format %s %f %d", "str", 3.14, 4 );
    log_trace( 12 );
...
```

if start program as

```sh
./program --log trace
```

you has output like this

```
[000000.111427128][ INFO][package.name]: format str 3.14 4
[000000.111938579][TRACE][package.name]: 12
```

