import 'package:flutter/material.dart';
import 'package:gersa_regionwatch/Providers/theme_provider.dart';
import 'package:gersa_regionwatch/Screens/login_screen.dart';
import 'package:gersa_regionwatch/Screens/presentacion_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/userModel.dart';
import '../Config/api_config.dart';
import '../services/api_service.dart';
import '../Theme/theme.dart';
import 'package:provider/provider.dart';
import 'nuevaRevision_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SharedPreferences? prefs;
  String? employeeNumber;
  String? employeeName;
  List<dynamic> revisiones = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    employeeNumber = prefs?.getString('employee_id');
    employeeName = prefs?.getString('employee_name');
    dataInicio();
  }

  Future<void> dataInicio() async {
    setState(() {
      cargando = true;
    });

    final response = await ApiService()
        .postRequest(ApiConfig.inicio, {"employee_number": employeeNumber});

    if (response["success"] == true) {
      final data = response['data'];

      setState(() {
        revisiones = data['revisiones'];
        User.roles = data['roles'];
        cargando = false;
      });
    } else {
      setState(() {
        cargando = false;
      });
      print(response["error"] ?? "Error desconocido");
    }
  }

  Future<void> refresh() async {
    // await Future.delayed(Duration(milliseconds: 500));
    final response = await ApiService()
        .postRequest(ApiConfig.inicio, {"employee_number": employeeNumber});

    if (response["success"] == true) {
      final data = response['data'];

      setState(() {
        revisiones = data['revisiones'];
        User.roles = data['roles'];
      });
    }
  }

  Future<void> logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Borra todos los datos almacenados (sesión)

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $employeeName'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
          ),
        ],
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refresh,
              color: AppColors.primary(
                  Theme.of(context).brightness == Brightness.dark),
              backgroundColor: AppColors.background(
                  Theme.of(context).brightness == Brightness.dark),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis últimas revisiones',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: revisiones.length,
                        itemBuilder: (context, index) {
                          final revision = revisiones[index];
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RevisionPresentacionScreen(
                                      uuid: revision["uuid"],
                                    ),
                                  ),
                                );
                              },
                              leading: Icon(
                                Icons.circle,
                                color: (revision["calificacion"] == "Verde")
                                    ? AppColors.verde()
                                    : (revision["calificacion"] == "Amarillo")
                                        ? AppColors.amarillo()
                                        : AppColors.rojo(),
                              ),
                              title: Text(revision["sucursal"]),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 5),
                                  Text('Fecha: ${revision["fecha"]}'),
                                  Text(
                                      'Calificación: ${revision["calificacion"]}'),
                                  Text('Tipo: ${revision["tipo"]}'),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_outlined),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NuevaRevisionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text('Nueva Revisión'),
          ),
        ),
      ),
    );
  }
}
