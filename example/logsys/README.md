For building type:

```
$ cd <example_dir>
$ dub build
```

Run variants:

```
$ bin/app --log trace
$ bin/app --log info
$ bin/app --log <name>:debug
$ bin/app --log <name>.<subname>:warn
$ bin/app --log-file=<filename>
$ bin/app --log trace --log-console-color=false
```
