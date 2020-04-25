#!/bin/sh

while True
do
  echo "Descargando pdf"
  lines=$( curl -sS -X GET https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports | grep "Situation report -" | grep "pdf" ); for line in $lines; do if echo $line | grep -q "pdf"; then curl -sS "https://www.who.int$( sed 's/.*href="\(.*\)?.*/\1/' <<< $line )" -o "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/reporte_covid.pdf"; break; fi; done

  pdftotext.exe -layout -f 2 -l 8 "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/reporte_covid.pdf"

  source /c/Users/danyg/PycharmProjects/ciss/venv/Scripts/activate
  echo "Guardando en base"
  python -m ciss --config config.yml --reporte reporte_covid.txt --salida "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida"

  deactivate

  rm "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/reporte_covid.pdf"
  rm "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/reporte_covid.txt"

  echo "Actualizando HTML"

  caso=0;
  while IFS= read -r line;
  do
    caso=$((caso+1));
    IFS='|' read -ra confirmados <<< "$line";
    trim_var=$( echo ${confirmados[1]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<li>.*<span id=\"mas_confirmados_${caso}\" class=\"pull-right\"><b>.*<\/b>/<li>${confirmados[0]}<span id=\"mas_confirmados_${caso}\" class=\"pull-right\"><b>${trim_var}<\/b>/g" test_ciss/index.html;
  done < "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_casos_confirmados.txt"

  caso=0;
  while IFS= read -r line;
  do
    caso=$((caso+1));
    IFS='|' read -ra muertes <<< "$line";
    trim_var=$( echo ${muertes[1]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<li>.*<span id=\"mas_muertes_${caso}\" class=\"pull-right\"><b>.*<\/b>/<li>${muertes[0]}<span id=\"mas_muertes_${caso}\" class=\"pull-right\"><b>${trim_var}<\/b>/g" test_ciss/index.html;
  done < "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_muertes.txt"

  caso=0;
  while IFS= read -r line;
  do
    caso=$((caso+1));
    IFS='|' read -ra letalidad <<< "$line";
    trim_var=$( echo ${letalidad[1]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<li>.*<span id=\"mas_letalidad_${caso}\" class=\"pull-right\"><b>.*<\/b>/<li>${letalidad[0]}<span id=\"mas_letalidad_${caso}\" class=\"pull-right\"><b>${trim_var}<\/b>/g" test_ciss/index.html;
  done < "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_letalidad.txt"

  while IFS= read -r line;
  do
    IFS='|' read -ra global <<< "$line";
    trim_var=$( echo ${global[6]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<span id=\"total_confirmados_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_confirmados_mundo\" class=\"counter\">${global[1]}<\/span>/g" test_ciss/index.html;
    sed -i "s/<span id=\"total_nuevos_confirmados_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_nuevos_confirmados_mundo\" class=\"counter\">${global[2]}<\/span>/g" test_ciss/index.html;
    sed -i "s/<span id=\"total_muertes_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_muertes_mundo\" class=\"counter\">${global[3]}<\/span>/g" test_ciss/index.html;
    sed -i "s/<span id=\"total_nuevas_muertes_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_nuevas_muertes_mundo\" class=\"counter\">${global[5]}<\/span>/g" test_ciss/index.html;
    sed -i "s/<span id=\"total_mortalidad_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_mortalidad_mundo\" class=\"counter\">${trim_var}<\/span>/g" test_ciss/index.html;
    sed -i "s/<span id=\"total_letalidad_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_letalidad_mundo\" class=\"counter\">${global[4]}<\/span>/g" test_ciss/index.html;

    break;
  done < "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_total.txt"

  rm "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_casos_confirmados.txt"
  rm "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_muertes.txt"
  rm "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_letalidad.txt"
  rm "$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")/salida_total.txt"

  current_date=$( date +%Y-%m-%d );
  sed -i "s/última actualización: .*<\/h4>/última actualización: ${current_date}<\/h4>/g" test_ciss/index.html;

  echo "Se ha finalizado el proceso"

  sleep 10

done