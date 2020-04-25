from ciss import get_covid_place
from ciss import is_covid_place
from operator import itemgetter
import mysql.connector
import argparse
import yaml
import re

parser = argparse.ArgumentParser(
    description='Ejecura el proceso de lectura y carga de la información de registros actuales de COVID-19'
)

parser.add_argument(
    '-c', '--config',
    default='config.yml',
    help='Archivo de configuración'
)

parser.add_argument(
    '-r', '--reporte',
    default='reporte_covid.txt',
    help='Reporte de resultados de COVID proveniente de WorldHealth Organization en formato txt'
)

parser.add_argument(
    '-s', '--salida',
    default='salida',
    help='Nombre del archivo de salida donde se colocaran los lugares con mayor porcentaje de letalidad, muertes'
)

args = parser.parse_args()

with open(args.config, mode='r', encoding='utf-8') as yaml_file:
    config = yaml.load(yaml_file, Loader=yaml.FullLoader)

covid_report = open(args.reporte, 'r')
paises = 0
places_outline = []
covid_results = {}

for line in covid_report.readlines():
    line = line.strip().upper()
    line = bytes(line, encoding='utf-8').decode("utf-8")

    total_cases = re.findall(r'\d+ +\d+ +\d+ +\d+', line)

    if len(total_cases) == 0:
        if is_covid_place(line.strip()):
            places_outline.append(line.strip())
        else:
            if len(re.findall(r' {22}', line)) > 0:
                line = re.sub(r' {22}[\s\w]*', '', line).strip()
            if is_covid_place(line.strip()):
                places_outline.append(line.strip())
        continue

    line = re.sub(total_cases[0] + r'[\s\w]*', '', line).strip()
    cases = re.findall(r'\d+', total_cases[0])

    if not line and len(places_outline) > 0:
        line = places_outline.pop(0)

    real_name = get_covid_place(line, covid_results) if "TERRITORIES**" != line else line

    if not real_name:
        continue

    covid_results[real_name] = {"nombre": real_name}
    paises += 1
    for i in range(len(cases)):
        key = ""
        if i == 0:
            key = "Total casos confirmados"
        elif i == 1:
            key = "Total nuevos casos confirmados"
        elif i == 2:
            key = "Total muertes"
        elif i == 3:
            key = "Total nuevas muertes"
            try:
                covid_results[real_name]["Total letalidad"] = float("{:.2f}".format(
                    covid_results[real_name]["Total muertes"] / covid_results[real_name]["Total casos confirmados"] *
                    100)
                )
            except ZeroDivisionError:
                covid_results[real_name]["Total letalidad"] = 0.0
        covid_results[real_name][key] = int(cases[i])

    if len(places_outline) > 0 and "TERRITORIES**" in covid_results:
        covid_results[places_outline.pop(0)] = covid_results["TERRITORIES**"]
        del covid_results["TERRITORIES**"]

mydb = mysql.connector.connect(
    host=config["mysql"]["connection"]["host"],
    user=config["mysql"]["connection"]["user"],
    passwd=config["mysql"]["connection"]["password"],
    database=config["mysql"]["connection"]["database"]
)

mycursor = mydb.cursor()

for covid_result in covid_results:
    if covid_result == "TOTAL":
        continue
    mycursor.execute("UPDATE {0} SET {1}='{6}',{2}='{7}',{3}='{8}' WHERE {4}='{5}'".format(
        config["mysql"]["table"]["name"],
        config["mysql"]["table"]["confirmated_cases"],
        config["mysql"]["table"]["deaths"],
        config["mysql"]["table"]["total_case_fatality"],
        config["mysql"]["table"]["country"],
        covid_result,
        covid_results[covid_result]["Total casos confirmados"],
        covid_results[covid_result]["Total muertes"],
        covid_results[covid_result]["Total letalidad"]
    ))


def print_sorted_cases(file_name, field, sort=True):
    outfile = open(args.salida + file_name, 'w', encoding='utf-8')
    if sort:
        top_seven = 0
        for confirmed_cases_sorted in sorted(covid_results.values(), key=itemgetter(field), reverse=True):
            if top_seven > 6:
                break

            outfile.write("{0}|{1}\n".format(
                confirmed_cases_sorted["nombre"].title(),
                f'{confirmed_cases_sorted[field]:,}')
            )
            top_seven += 1
    else:
        line_to_write = ""

        covid_results[field]["Total mortalidad"] = float("{:.2f}".format(
            float(covid_results[field]["Total muertes"])/7780079340.0
        *100000))

        for key in covid_results[field].keys():
            try:
                int(covid_results[field][key])
                line_to_write += f'{covid_results[field][key]:,}' + "|"
            except:
                line_to_write += str(covid_results[field][key]).title() + "|"

        outfile.write("{0}\n".format(
            line_to_write[0:len(line_to_write)-1]
        ))


total = covid_results.pop("TOTAL")
print_sorted_cases("_casos_confirmados.txt", 'Total casos confirmados')
print_sorted_cases("_muertes.txt", 'Total muertes')
print_sorted_cases("_letalidad.txt", 'Total letalidad')
covid_results["TOTAL"] = total
print_sorted_cases("_total.txt", 'TOTAL', False)

mydb.commit()
