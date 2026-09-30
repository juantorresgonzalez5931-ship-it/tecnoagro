import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/colores.dart';
import 'package:frontend/service/services/recuperar_service.dart';
import 'package:frontend/widgets/app_text_field.dart';

class VerificarCodigoScreen extends StatefulWidget {
  final String email;
  const VerificarCodigoScreen({super.key, required this.email});

  @override
  State<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

class _VerificarCodigoScreenState extends State<VerificarCodigoScreen> {
  static const _largoCodigo = 6;

  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codigoFocus = FocusNode();
  final _recuperarService = RecuperarService();

  bool _isLoading = false;
  bool _isResending = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Redibuja los círculos cuando cambia el código o el foco.
    _codigoController.addListener(() => setState(() {}));
    _codigoFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    _codigoFocus.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    final codigo = _codigoController.text.trim();
    final password = _passwordController.text;

    if (codigo.length != _largoCodigo) {
      _mostrarMensaje('Ingresa el código de 6 dígitos', esError: true);
      return;
    }
    if (password.length < 6) {
      _mostrarMensaje('La contraseña debe tener al menos 6 caracteres', esError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final mensaje = await _recuperarService.restablecerContrasena(
        email: widget.email,
        codigo: codigo,
        nuevaContrasena: password,
      );
      if (!mounted) return;
      _mostrarMensaje(mensaje);
      // Cierra esta pantalla y la del correo: vuelve al login.
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reenviarCodigo() async {
    setState(() => _isResending = true);
    try {
      await _recuperarService.enviarCodigo(widget.email);
      if (!mounted) return;
      _mostrarMensaje('Te enviamos un nuevo código');
    } catch (e) {
      if (!mounted) return;
      _mostrarMensaje(e.toString().replaceAll('Exception: ', ''), esError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: esError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Seis círculos que muestran el código. Debajo hay un campo real invisible
  /// que da el teclado numérico y permite borrar y pegar el código.
  Widget _casillasCodigo() {
    final texto = _codigoController.text;
    final activa = _codigoFocus.hasFocus
        ? texto.length.clamp(0, _largoCodigo - 1)
        : -1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _codigoFocus.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_largoCodigo, (i) {
              final lleno = i < texto.length;
              final esActiva = i == activa;
              return Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: esActiva ? AppColors.verdePrimario : Colors.grey.shade300,
                    width: esActiva ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  lleno ? texto[i] : '-',
                  style: TextStyle(
                    color: lleno ? AppColors.textoPrincipal : AppColors.textoPlaceholder,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _codigoController,
                focusNode: _codigoFocus,
                autofocus: true,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_largoCodigo),
                ],
                enableInteractiveSelection: false,
                showCursor: false,
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.verdePrimario),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/images/logo-tecnoagro.png',
                    width: 100, height: 100, fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [AppColors.verdeClaro, AppColors.verdeOscuro],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(b),
                child: const Text('Recuperar contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 22),
              Text(
                'Ingresa el código de 6 dígitos enviado a tu correo:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textoPrincipal,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textoSecundario, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _casillasCodigo(),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Nueva contraseña',
                hint: 'Mínimo 6 caracteres',
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                enabled: !_isLoading,
                onSubmitted: (_) => _restablecer(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _restablecer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.verdePrimario,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('LISTO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: (_isResending || _isLoading) ? null : _reenviarCodigo,
                  style: TextButton.styleFrom(foregroundColor: AppColors.verdePrimario),
                  child: Text(
                    _isResending ? 'Enviando...' : 'Reenviar código',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: AppColors.textoSecundario, fontSize: 13.5),
                    children: [
                      const TextSpan(text: '¿Ya recordaste tu contraseña? '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text('INICIAR SESIÓN',
                              style: TextStyle(color: AppColors.verdePrimario, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}