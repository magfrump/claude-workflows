Commit: a2cbd9c6
# Lite fix-drift check, U2b2 post-final-pass fixes (128ee81d..a2cbd9c6)

One finding (findings.json): the U2c plan bullet "prescribes" need_root and an import_reset test "without evidence it was executed".

Disposition: refuted. `need_root` exists (`scripts/lib/dev-cycle-read.sh:139`), and the U2c bullet lists work for U2c to do, not work claimed done. No change.
