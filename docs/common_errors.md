# Common Errors and Gotchas

* When skipping an instruction, the CPU takes the same amount of time as the full instruction. This means that skipping two byte instructions takes 4 cycles
* Input for multiple active `S` lines are ORed together
  * Sometimes one of these lines is grounded and always active, which is also ORed