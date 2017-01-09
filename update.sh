#!/bin/sh

URL='http://standards.ieee.org/develop/regauth/oui/oui.txt'
WWWDIR="${1:-/var/www/oui}"
FILE="${2:-oui.txt}"		# if file already exists, it is not downloaded
NEW=0

if test -e "$FILE" || wget -O "$FILE" "$URL"; then
	# 3C-D9-2B   (hex)                Hewlett Packard
	# 3CD92B     (base 16)            Hewlett Packard
	#                                 11445 Compaq Center Drive
	#                                 Houston    77070
	#                                 US
	#
	# (next entry ...)

	while read -r LINE; do
		# shellcheck disable=SC2086
		set -- $LINE

		case "$1" in
			[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])
				mac="$( echo "$1" | sed 'y/ABCDEF/abcdef/' )"	# lowercase

				DIR1="$( echo "$mac" | cut -b 1,2 )"
				DIR2="$( echo "$mac" | cut -b 3,4 )"
				DIR3="$( echo "$mac" | cut -b 5,6 )"
				OUTFILE="$WWWDIR/$DIR1/$DIR2/$DIR3"	# e.g. 3CD92B -> oui/3c/d9/2b

				if [ -e "$OUTFILE" ]; then
					ORGANIZATION=			# no need for writing again
				else
					NEW=$(( NEW + 1 ))
					mkdir -p "$WWWDIR/$DIR1/$DIR2"

					shift 3
					ORGANIZATION="$*"
					echo >"$OUTFILE" "$ORGANIZATION"
				fi
			;;
			*[a-z0-9]*)
				test "$ORGANIZATION" && echo >>"$OUTFILE" "$*"
			;;
			*)
				ORGANIZATION=		# abort parsing, wait for next entry
			;;
		esac
	done <"$FILE"

	if [ $NEW -gt 0 ]; then
		logger -s "new entries: $NEW"

		tar -C "$WWWDIR" -cf 'oui.tar' --exclude='oui.tar.xz' .
		xz -e 'oui.tar'
		mv 'oui.tar.xz' "$WWWDIR"	# ~ 800 Kbytes
	else
		logger -s "no new entries"
	fi
else
	rm "$FILE"
	false
fi
