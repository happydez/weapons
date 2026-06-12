# weapons

Weapon spawner + bullet effects (paintball, sparks, electro, tracers, anti-flash) for CS:S

## Dependencies

- [printer](https://github.com/happydez/printer)
- [flags-core](https://github.com/happydez/flags-core)

## flags-core

Only grenades are access-controlled (flags: `f` = flashbang, `s` = smoke, `h` = hegrenade).
When `weapons_allow_nades` is `1` (default) everyone can use grenades; set it to `0` to require flags.

Grant it via flags-core, e.g. in `configs/flags/flags-groups.cfg`:

```
"VIP"
{
    "weapons" { "flags" "fsh" }
}
```
