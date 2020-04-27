#!/bin/sh

if [[ "$OSTYPE" == "darwin"* ]]; then
  location_shell="$(dirname -- "$(/usr/local/bin/readlink -f -- "$BASH_SOURCE")")"
else
  location_shell="$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")"
fi

virtual_envoronment="${1:-"${locaton_shell}/venv/Scripts/"}"
html_location="${2:-"${locaton_shell}/test_ciss/index.html"}"
sleep_time=${3:-10}

while True
do
  echo "Descargando pdf"
  lines=$( curl -sS -X GET https://www.who.int/emergencies/diseases/novel-coronavirus-2019/situation-reports | grep "Situation report -" | grep "pdf" ); for line in $lines; do if echo $line | grep -q "pdf"; then curl -sS "https://www.who.int$( sed 's/.*href="\(.*\)?.*/\1/' <<< $line )" -o "${location_shell}/reporte_covid.pdf"; break; fi; done

  pdftotext.exe -layout -f 2 -l 8 "${location_shell}/reporte_covid.pdf"

  source "${virtual_envoronment}activate"

  echo "Guardando en base"
  python -m ciss --config "${location_shell}/config.yml" --reporte "${location_shell}/reporte_covid.txt" --salida "${location_shell}/salida"

  deactivate

  rm "${location_shell}/reporte_covid.pdf"
  rm "${location_shell}/reporte_covid.txt"

  echo "Actualizando HTML"

  caso=0;
  while IFS= read -r line;
  do
    caso=$((caso+1));
    IFS='|' read -ra confirmados <<< "$line";
    trim_var=$( echo ${confirmados[1]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<li>.*<span id=\"mas_confirmados_${caso}\" class=\"pull-right\"><b>.*<\/b>/<li>${confirmados[0]}<span id=\"mas_confirmados_${caso}\" class=\"pull-right\"><b>${trim_var}<\/b>/g" "${html_location}";
  done < "${location_shell}/salida_casos_confirmados.txt"

  caso=0;
  while IFS= read -r line;
  do
    caso=$((caso+1));
    IFS='|' read -ra muertes <<< "$line";
    trim_var=$( echo ${muertes[1]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<li>.*<span id=\"mas_muertes_${caso}\" class=\"pull-right\"><b>.*<\/b>/<li>${muertes[0]}<span id=\"mas_muertes_${caso}\" class=\"pull-right\"><b>${trim_var}<\/b>/g" "${html_location}";
  done < "${location_shell}/salida_muertes.txt"

  caso=0;
  while IFS= read -r line;
  do
    caso=$((caso+1));
    IFS='|' read -ra letalidad <<< "$line";
    trim_var=$( echo ${letalidad[1]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<li>.*<span id=\"mas_letalidad_${caso}\" class=\"pull-right\"><b>.*<\/b>/<li>${letalidad[0]}<span id=\"mas_letalidad_${caso}\" class=\"pull-right\"><b>${trim_var}<\/b>/g" "${html_location}";
  done < "${location_shell}/salida_letalidad.txt"

  while IFS= read -r line;
  do
    IFS='|' read -ra global <<< "$line";
    trim_var=$( echo ${global[6]} | sed ':a;N;$!ba;s/\n/;/g' )
    sed -i "s/<span id=\"total_confirmados_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_confirmados_mundo\" class=\"counter\">${global[1]}<\/span>/g" "${html_location}";
    sed -i "s/<span id=\"total_nuevos_confirmados_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_nuevos_confirmados_mundo\" class=\"counter\">${global[2]}<\/span>/g" "${html_location}";
    sed -i "s/<span id=\"total_muertes_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_muertes_mundo\" class=\"counter\">${global[3]}<\/span>/g" "${html_location}";
    sed -i "s/<span id=\"total_nuevas_muertes_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_nuevas_muertes_mundo\" class=\"counter\">${global[5]}<\/span>/g" "${html_location}";
    sed -i "s/<span id=\"total_mortalidad_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_mortalidad_mundo\" class=\"counter\">${trim_var}<\/span>/g" "${html_location}";
    sed -i "s/<span id=\"total_letalidad_mundo\" class=\"counter\">.*<\/span>/<span id=\"total_letalidad_mundo\" class=\"counter\">${global[4]}<\/span>/g" "${html_location}";

    break;
  done < "${location_shell}/salida_total.txt"

  rm "${location_shell}/salida_casos_confirmados.txt"
  rm "${location_shell}/salida_muertes.txt"
  rm "${location_shell}/salida_letalidad.txt"
  rm "${location_shell}/salida_total.txt"

  current_date=$( date +%Y-%m-%d );
  sed -i "s/última actualización: .*<\/h4>/última actualización: ${current_date}<\/h4>/g" "${html_location}";

  echo "Se ha finalizado el proceso"

  sleep "${sleep_time}"

done