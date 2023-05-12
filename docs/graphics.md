MAME Game and Watch ROMs contain SVGs with the LCD assets. Each of the paths have a `title` attribute that specify which wires in the segment matrix go to that LCD segment \[1]. This segment is in the form `x.y.z`, where `x` is in the range `\[0, 2]`, `y` is in the range `\[0, 15]`, and `z` is in the range `\[0, 3]`.

* The first value `x` represents which segment lines are used. `0 -> seg_a`, `1 -> seg_b`, `2 -> seg_bs`
* The second value `y` is the column of the data, or the bit in the `seg_a/b/bs` line
* The third value `z` is the row of the data, or the `H` selection

Notes:
1. A path does not have to have a title tag. It can be part of a group that has a title tag