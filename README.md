# html2slang
Converts HTML pages to slang (template language)

This tool converts HTML pages into [slang](https://github.com/jeromegn/slang).

Does it work? YES.

Primary use case is converting HTML templates into much nicer and more efficient slang syntax, so that the development can be done in slang from there.

It might not cover absolutely all edge cases, but does pretty well and should get you in a good position.
(Currently the only outstanding issue is that it does not preserve whitespace in preformatted blocks of text, and simply treats everything as HTML.)

Various methods of running it:

```shell
  perl html2slang.pl file1.html file2.html
  cat file1.html | perl html2slang.pl
  perl html2slang.pl < file1.html
```
