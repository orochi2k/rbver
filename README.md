# rbver

Ruby version info (core only, without stdlib).

You can download [the json format file](versions.json),
or [the marshal one](versions.ri).

The structure of this file is:

```ruby
{
  "ClassName": {
    "i": { "instance_method1": 30 },
    "c": { "class_method1": 90 },
    "a": { "attribute1": 160 },
    "_": 100, # _ means the class itself
  }
}
```

The number followed by a method/attribute is the version of ruby - 100.
Which means `93` is `ruby_1_9_3`, `160` is `ruby_2_6_0`, etc.
I choose this way to store the number mainly because in ruby marshal numbers
under 127 will only take one byte to store. :p

~~It seems that~~ We can write a [user script](rbver.user.js) to
https://ruby-doc.org to show the versions.

There is also an [`ancestors.json`](ancestors.json) containing the inherit
information. However I didn't put any version info in it. Structure of that
file is:

```json
{
  "ClassName": ["ClassName", "SuperClass", "SuperSuperClass"]
}
```

### RGSS Specific Data

I also gathered some info from RM (RPG Maker) XP/VX/VXAce.
Check the [rgss/](rgss) folder.

## Script

The `versions.ri` and `ancestors.ri` file was generated by
[`rbver.rb`](rbver.rb) and [`dig.rb`](dig.rb).
You may notice that I am using `ruby.exe` to get these info.
So results must be different from linux ones
(e.g. there is `RubyInstaller` module in ruby 2.x).

Files generated by dig.rb are put in [each/](each) folder,
and their structure is

```ruby
# s: x::child-mod
# t: x::constants
# i: instance methods
# c: class methods
# a: ancestors
{
  :s => {},
  :t => [],
  :i => x.instance_methods(false),
  :c => x.singleton_methods(false),
  :a => x.ancestors.map(&:to_s)
}
```

Some fields may be missing if they are empty and for smaller file size.

## License

:shit: WTFPL.
