// Embeds the built, standalone oblio-glass-item-helper.so inside oblio-glass.so,
// so a plugin manager that only installs this single output file still ships
// the protocol helper (see ItemHints.cpp: it is written to a memfd and
// dlopen'd from there at PLUGIN_INIT). GNU as, works with both gcc and clang
// as the driver.

.section .rodata
.global oblioGlassItemHelperBlobStart
.balign 8
oblioGlassItemHelperBlobStart:
.incbin "src/item-helper/oblio-glass-item-helper.so"
.global oblioGlassItemHelperBlobEnd
oblioGlassItemHelperBlobEnd:

// Assembly gets no GNU-stack note on its own, which some linkers read as needing an
// executable stack. %progbits, not @progbits: @ starts a comment on 32-bit ARM.
.section .note.GNU-stack,"",%progbits
