Provides tool for program localization.

Example:

```d
import des.util.localization;

void main()
{
    setTranslatePath( "translate/dir" );
    Translator.setLocalization( "ru" );
    writeln( _!"hello" );
}
```

0. run program 
0. copy and rename file `translate/dir/base` to `translate/dir/lang.lt`,
    where <lang> is language to translate
0. translate each line in `translate/dir/lang.lt`
    example:
    `hello : привет`
0. run program
0. when program call `_!"hello"`it returns `"привет"w`
