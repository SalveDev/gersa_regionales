import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gersa_regionwatch/Config/api_config.dart';
import 'package:gersa_regionwatch/Providers/theme_provider.dart';
import 'package:gersa_regionwatch/Screens/home_screen.dart';
import 'package:gersa_regionwatch/Theme/theme.dart';
import 'package:gersa_regionwatch/services/api_service.dart';
import 'package:gersa_regionwatch/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RevisionScreen extends StatefulWidget {
  var nombreSucursal;
  var rol;
  var uuid;

  @override
  RevisionScreen(
      {required this.nombreSucursal, required this.rol, required this.uuid});

  _RevisionScreenState createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  List<dynamic> _preguntas = [];
  bool cargando = true;
  Map<String, dynamic> _respuestas = {};
  final Map<String, TextEditingController> _controllers = {};
  SharedPreferences? prefs;
  String? employeeNumber;

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    employeeNumber = prefs?.getString('employee_id');

    await prefs?.setString('nombre_sucursal', widget.nombreSucursal);
    await prefs?.setString('rol', widget.rol);
    await prefs?.setString('uuid', widget.uuid);

    await cargarRespuestasDesdePrefs(); // Cargar respuestas guardadas
    await dataInicio();
  }

  Future<void> guardarRespuestasEnPrefs() async {
    if (prefs != null) {
      await prefs!.setString('respuestas_revision', jsonEncode(_respuestas));
    }
  }

  Future<void> cargarRespuestasDesdePrefs() async {
    if (prefs != null) {
      String? respuestasGuardadas = prefs!.getString('respuestas_revision');
      if (respuestasGuardadas != null) {
        final data = jsonDecode(respuestasGuardadas);
        setState(() {
          _respuestas = data;
        });

        // Crea controladores con el texto guardado
        data.forEach((key, value) {
          _controllers[key] = TextEditingController(text: value);
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> dataInicio() async {
    setState(() {
      cargando = true;
    });

    print(Theme.of(context).brightness == Brightness.dark
        ? 'Modo Oscuro'
        : 'Modo Claro');

    final response = await ApiService().postRequest(
        ApiConfig.obtenerRevision, {"employee_number": employeeNumber});

    if (response["success"] == true) {
      final data = response['data'];

      setState(() {
        _preguntas = data['preguntas'];
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
      print(response["error"] ?? "Error desconocido");
    }
  }

  Future<void> cancelarRevision() async {
    final response =
        await ApiService().postRequest(ApiConfig.cancelarRevision, {
      "uuid": widget.uuid,
    });

    if (response["success"] == true) {
      // borrar respuestas guardadas
      prefs?.remove('respuestas_revision');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      final server = response["error"];
      mostrarDialogo(context, server["message"] ?? "Error desconocido");
    }
  }

  Future<void> enviarRespuestas() async {
    final List<dynamic> respuestas = [];

    for (var pregunta in _preguntas) {
      final preguntaId = pregunta['columna'];
      final respuesta = _respuestas[preguntaId];
      if (respuesta != null) {
        respuestas.add({
          "columna": preguntaId,
          "respuesta": respuesta,
        });
      }
    }

    final response =
        await ApiService().postRequest(ApiConfig.finalizarRevision, {
      "uuid": widget.uuid,
      "respuestas": respuestas,
    });

    if (response["success"] == true) {
      // borrar respuestas guardadas
      prefs?.remove('respuestas_revision');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      final server = response["error"];
      mostrarDialogo(context, server["message"] ?? "Error desconocido");
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
      appBar: AppBar(
        title: Text('${widget.nombreSucursal} | ${widget.rol}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Cancelar Revisión'),
                  content:
                      Text('¿Está seguro de que desea cancelar la revisión?'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('No'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text('Sí'),
                      onPressed: () {
                        cancelarRevision();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: cargando
            ? Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Card(
                    color: AppColors.primary(Theme.of(context).brightness == Brightness.dark),
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
                                        Theme.of(context).brightness == Brightness.dark)),
                              ),
                              SizedBox(width: 10.0),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    widget.uuid,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.buttonText(
                                        Provider.of<ThemeProvider>(context)
                                                .themeMode ==
                                            ThemeMode.dark,
                                      ),
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
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
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    widget.nombreSucursal,
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.buttonText(
                                        Provider.of<ThemeProvider>(context)
                                                .themeMode ==
                                            ThemeMode.dark,
                                      ),
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Rol:',
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
                                widget.rol,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          enviarRespuestas();
        },
        child: Icon(Icons.send),
      ),
    );
  }

  Widget _buildPregunta(dynamic pregunta) {
    final tipoPregunta = pregunta['tipo'] ?? 'Desconocido';
    final preguntaTexto = pregunta['pregunta'] ?? 'Pregunta no definida';
    final preguntaId = pregunta['columna'];
    final opciones = pregunta['opciones'] ?? [];
    final optionDefault = 'Seleccionar';

    Color getCardColor(String? value) {
      switch (value) {
        case 'Verde':
          return AppColors.verde();
        case 'Amarillo':
          return AppColors.amarillo();
        case 'Rojo':
          return AppColors.rojo();
        default:
          return AppColors.element(
              Theme.of(context).brightness == Brightness.dark);
      }
    }

    switch (tipoPregunta) {
      case 'text':
        return _buildCard(
          preguntaTexto,
          TextField(
            controller: _controllers.putIfAbsent(
              preguntaId,
              () => TextEditingController(text: _respuestas[preguntaId] ?? ''),
            ),
            decoration: InputDecoration(
              hintText: 'Escribe tu respuesta aquí',
              border: const OutlineInputBorder(),
            ),
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            maxLines: null,
            keyboardType: TextInputType.multiline,
            onChanged: (value) {
              _respuestas[preguntaId] = value;
              guardarRespuestasEnPrefs(); // guarda en prefs
            },
          )
        );
      case 'date':
        return _buildCard(
          preguntaTexto,
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (selectedDate != null) {
                    setState(() {
                      _respuestas[preguntaId] =
                          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                    });
                    guardarRespuestasEnPrefs(); // Guardar en SharedPreferences
                  }
                },
                child: Text(
                  _respuestas[preguntaId] ?? 'Seleccionar Fecha',
                ),
              ),
            ),
          ),
          color: getCardColor(_respuestas[preguntaId]),
        );
      case 'selector':
        return _buildCard(
          preguntaTexto,
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: double.infinity,
              child: DropdownMenu<String>(
                initialSelection: _respuestas[preguntaId] ?? optionDefault,
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: [
                  DropdownMenuEntry(
                      value: optionDefault,
                      label: optionDefault,
                      style: MenuItemButton.styleFrom(
                        foregroundColor: AppColors.placeholder(Theme.of(context).brightness == Brightness.dark),
                      )),
                  for (var opcion in opciones)
                    DropdownMenuEntry(value: opcion, label: opcion)
                ],
                onSelected: (value) {
                  setState(() {
                    _respuestas[preguntaId] = value;
                  });
                  guardarRespuestasEnPrefs(); // Guardar en SharedPreferences
                },
              ),
            ),
          ),
          color: getCardColor(_respuestas[preguntaId]),
        );
      default:
        return _buildCard(preguntaTexto, Text('Tipo no soportado'));
    }
  }

  Widget _buildCard(String titulo, Widget contenido, {Color? color}) {
    color ??= AppColors.element(Theme.of(context).brightness == Brightness.dark);
    return Card(
      color: color, // Aplicamos el color dinámico aquí
      margin: EdgeInsets.all(8.0),
      child: Padding(
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
            contenido,
          ],
        ),
      ),
    );
  }
}
