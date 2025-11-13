import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "web/.env");
    print(" Archivo .env cargado correctamente");
  } catch (e) {
    print(" No se pudo cargar el .env, usando valor por defecto");
  }

  
  dotenv.env.putIfAbsent('OWM_API_KEY', () => 'db6592ace0abf8b024ebf8ebe49a1f76');

  print(" API Key en memoria: ${dotenv.env['OWM_API_KEY']}");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clima App',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String? _resultado;
  bool _cargando = false;
  String? _error;

  Future<void> _buscarClima() async {
    final ciudad = _controller.text.trim();

    if (ciudad.isEmpty) {
      setState(() => _error = "Ingresa una ciudad");
      return;
    }

    setState(() {
      _cargando = true;
      _resultado = null;
      _error = null;
    });

    final apiKey = dotenv.env['OWM_API_KEY'];
    final url = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': ciudad,
      'appid': apiKey,
      'units': 'metric',
      'lang': 'es',
    });

    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final temp = data['main']['temp'];
        final desc = data['weather'][0]['description'];

        setState(() {
          _resultado = "🌡️ Temperatura: $temp°C\n☁️ Descripción: $desc";
        });
      } else if (resp.statusCode == 404) {
        setState(() => _error = "Ciudad no encontrada");
      } else {
        setState(() => _error = "Error ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Error de conexión o tiempo agotado");
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clima con API REST")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Ciudad (ej. Querétaro, MX)",
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscarClima(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargando ? null : _buscarClima,
              child: const Text("Buscar clima"),
            ),
            const SizedBox(height: 24),
            if (_cargando)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_resultado != null)
              Text(
                _resultado!,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              )
            else
              const Text("Escribe una ciudad y presiona Buscar"),
          ],
        ),
      ),
    );
  }
}
