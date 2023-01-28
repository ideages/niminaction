# pandoc -f markdown -t asciidoc -o summary.adoc summary.md 
# chmod 755 con.sh

# pandoc -f markdown -t asciidoc -o 00a.adoc 0about.md
# pandoc -f markdown -t asciidoc -o 00b.adoc 0wl.md
# pandoc -f markdown -t asciidoc -o 01.adoc 01.md
# pandoc -f markdown -t asciidoc -o 02.adoc 02.md
# pandoc -f markdown -t asciidoc -o 03.adoc 03.md
# pandoc -f markdown -t asciidoc -o 04.adoc 04.md
# pandoc -f markdown -t asciidoc -o 05.adoc 05.md
# pandoc -f markdown -t asciidoc -o 06.adoc 06.md
# pandoc -f markdown -t asciidoc -o 07.adoc 07.md
# pandoc -f markdown -t asciidoc -o 08.adoc 08.md
# pandoc -f markdown -t asciidoc -o 09.adoc 09.md

pandoc  -f epub -t asciidoc -o 01.adoc Nim_in_Action_v8_MEAP.epub
pandoc  -f epub -t markdown -o 01.md Nim_in_Action_v8_MEAP.epub
pandoc --lua-filter rsbc.lua -f markdown -t asciidoc -o 01.adoc ../cnbook/01.md
