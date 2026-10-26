set -e
mkdir -p "$(dirname "$0")/fonts"
cd "$(dirname "$0")/fonts"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120 Safari/537.36"
curl -sS -A "$UA" "https://fonts.googleapis.com/css2?family=Shippori+Mincho:wght@600;800&family=Zen+Kurenaido&display=block" -o g.css
grep -o 'https://fonts.gstatic.com[^)]*' g.css | sort -u > urls.txt
wc -l urls.txt
i=0
while read u; do f=$(echo "$u" | sed 's#https://fonts.gstatic.com/##; s#/#_#g'); [ -f "$f" ] || curl -sS -o "$f" "$u"; done < urls.txt
sed -E 's#https://fonts.gstatic.com/([^)]*)#\1#g' g.css | perl -pe 's#url\(([^)]*)\)#"url(".($1=~s{/}{_}gr).")"#ge' > fonts.css
