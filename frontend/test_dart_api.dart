import 'dart:convert';
import 'dart:io';

void main() async {
  // Login
  final loginReq = await HttpClient().postUrl(Uri.parse('http://localhost:3000/auth/login'));
  loginReq.headers.contentType = ContentType.json;
  loginReq.write(jsonEncode({'email': 'admin@templo.com', 'password': 'admin'})); // Usa el seed
  // (Intentaré usar la DB primero si falla esto)
}
