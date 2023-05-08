MAME Game and Watch ROMs contain SVGs with the LCD assets. Each of the paths have a `title` attribute that specify which wires in the segment matrix go to that LCD segment. This segment is in the form `x.y.y`, where `x` is in the range `\[0, 2]`, and `y` is in the range `\[0, 15]`.

* The first value `x` represents which segment lines are used. `0 -> seg_a`, `1 -> seg_b`, `2 -> seg_bs`
* The second value (first `y`) is the column of the data, or the bit in the `seg_a/b/bs` line
* The third value (second `y`) is the row of the data, or the `H` selection