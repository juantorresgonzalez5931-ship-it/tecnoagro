import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../core/colores.dart';

class ManualesScreen extends StatefulWidget {
  const ManualesScreen({super.key});

  @override
  State<ManualesScreen> createState() => _ManualesScreenState();
}

class _ManualesScreenState extends State<ManualesScreen> {
  late final PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfControllerPinch(
      document: PdfDocument.openAsset('assets/manual/manual_tecnoagro.pdf'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoCrema,
      appBar: AppBar(
        backgroundColor: AppColors.verdePrimario,
        foregroundColor: AppColors.blanco,
        elevation: 0,
        title: const Text(
          'Manual de usuario',
          style: TextStyle(
            color: AppColors.blanco,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          PdfPageNumber(
            controller: _controller,
            builder: (context, loadingState, page, pagesCount) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$page / ${pagesCount ?? 0}',
                  style: const TextStyle(
                    color: AppColors.blanco,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: PdfViewPinch(
        controller: _controller,
        backgroundDecoration: const BoxDecoration(color: AppColors.fondoCrema),
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.verdePrimario),
          ),
          pageLoaderBuilder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.verdePrimario),
          ),
          errorBuilder: (_, error) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudo abrir el manual. Inténtalo de nuevo más tarde.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textoSecundario),
              ),
            ),
          ),
        ),
      ),
    );
  }
}