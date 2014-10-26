Provides tool for localization program.

Example:

```d
    mixin( useTranslatorMixin( "translate/dir" ) );

    writeln( _!"hello" );

    Translator.setLocalization( "ru" );

    writeln( _!"hello" );
    writeln( _!"world" );
```

0. run program 
0. copy and rename "translate/dir/base" to "translate/dir/lang.lt",
    where <lang> is language to translate
0. in each line in "translate/dir/lang.lt" write translation of line
    example:
    hello : привет
0. when program call _!"hello" it print "привет"
