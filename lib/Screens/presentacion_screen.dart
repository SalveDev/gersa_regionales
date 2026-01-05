import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gersa_regionwatch/Config/api_config.dart';
import 'package:gersa_regionwatch/Providers/theme_provider.dart';
import 'package:gersa_regionwatch/Theme/theme.dart';
import 'package:gersa_regionwatch/services/api_service.dart';
import 'package:provider/provider.dart';
import '../utils/utils.dart';

class RevisionPresentacionScreen extends StatefulWidget {
  final String uuid;

  const RevisionPresentacionScreen({required this.uuid, Key? key})
      : super(key: key);

  @override
  _RevisionPresentacionScreenState createState() =>
      _RevisionPresentacionScreenState();
}

class _RevisionPresentacionScreenState
    extends State<RevisionPresentacionScreen> {
  List<dynamic> _preguntas = [];
  bool cargando = true;
  String? nombreSucursal;
  String? rol;
  List revReg = [];

  @override
  void initState() {
    super.initState();
    obtenerDatos();
  }

  Future<void> obtenerDatos() async {
    setState(() {
      cargando = true;
    });

    final response = await ApiService()
        .postRequest(ApiConfig.obtenerVieja, {"uuid": widget.uuid});

    if (response["success"] == true) {
      final data = response['data'];
      final revision = data['revision'];

      setState(() {
        _preguntas = revision['preguntas'];
        nombreSucursal = data['nombre_sucursal'];
        rol = data['rol'];
        revReg = revision['revReg'];
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
      print(response["error"] ?? "Error desconocido");
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<dynamic>> preguntasPorSeccion = {};

    for (var pregunta in _preguntas) {
      final seccion = pregunta["seccion"] ?? "Sin Sección";
      if (!preguntasPorSeccion.containsKey(seccion)) {
        preguntasPorSeccion[seccion] = [];
      }
      preguntasPorSeccion[seccion]!.add(pregunta);
    }

    return Scaffold(
      appBar: cargando
          ? AppBar(
              title: Text('Cargando...'),
            )
          : AppBar(
              title: Text('Revision ${revReg[0]['Tipo']}'),
            ),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: cargando
            ? Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Card(
                    color: revReg[0]['Calificacion'] == 'Verde'
                        ? AppColors.verde()
                        : revReg[0]['Calificacion'] == 'Amarillo'
                            ? AppColors.amarillo()
                            : AppColors.rojo(),
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'UUID:',
                                style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonText(
                                        Provider.of<ThemeProvider>(context)
                                                .themeMode ==
                                            ThemeMode.dark)),
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                revReg[0]['UUID'],
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonText(
                                      Provider.of<ThemeProvider>(context)
                                              .themeMode ==
                                          ThemeMode.dark),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Nombre de la Sucursal:',
                                style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonText(
                                        Provider.of<ThemeProvider>(context)
                                                .themeMode ==
                                            ThemeMode.dark)),
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                revReg[0]['Sucursal'],
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonText(
                                      Provider.of<ThemeProvider>(context)
                                              .themeMode ==
                                          ThemeMode.dark),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Fecha de Revisión:',
                                style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonText(
                                        Provider.of<ThemeProvider>(context)
                                                .themeMode ==
                                            ThemeMode.dark)),
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                formatearFecha(revReg[0]['Fecha']),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonText(
                                      Provider.of<ThemeProvider>(context)
                                              .themeMode ==
                                          ThemeMode.dark),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Calificación General:',
                                style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.buttonText(
                                        Provider.of<ThemeProvider>(context)
                                                .themeMode ==
                                            ThemeMode.dark)),
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                revReg[0]['Calificacion'],
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.buttonText(
                                      Provider.of<ThemeProvider>(context)
                                              .themeMode ==
                                          ThemeMode.dark),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...preguntasPorSeccion.entries.map((entry) {
                    return Column(
                      children: [
                        ExpansionTile(
                          title: Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary(
                                  Theme.of(context).brightness ==
                                      Brightness.dark),
                            ),
                          ),
                          backgroundColor: AppColors.background(
                              Theme.of(context).brightness == Brightness.dark),
                          children: entry.value
                              .map((pregunta) => _buildPregunta(pregunta))
                              .toList(),
                        ),
                        SizedBox(height: 20.0),
                      ],
                    );
                  }).toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildPregunta(dynamic pregunta) {
    final preguntaTexto = pregunta['pregunta'] ?? 'Pregunta no definida';
    final respuesta = pregunta['respuesta'] ?? 'No disponible';

    return _buildCard(preguntaTexto, Text(respuesta));
  }

  Widget _buildCard(String titulo, Widget contenido) {
    return Card(
      margin: EdgeInsets.all(8.0),
      color: (contenido as Text).data == 'Verde'
          ? AppColors.verde()
          : (contenido as Text).data == 'Amarillo'
              ? AppColors.amarillo()
              : (contenido as Text).data == 'Rojo'
                  ? AppColors.rojo()
                  : AppColors.element(
                      Theme.of(context).brightness == Brightness.dark),
      child: Container(
        width: double
            .infinity, // Esto hace que la Card ocupe todo el ancho disponible
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            if (RegExp(
                    r'^[A-Za-z]{3}, \d{2} [A-Za-z]{3} \d{4} \d{2}:\d{2}:\d{2} GMT$')
                .hasMatch(contenido.data ?? ''))
              Text(formatearFecha(contenido.data!))
            else
              contenido
          ],
        ),
      ),
    );
  }
}
