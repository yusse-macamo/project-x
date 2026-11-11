import 'package:flutter/material.dart';

import 'package:project_x/nucleo/tema/cores_app.dart';

class MarcadorPosicao extends StatelessWidget {
  const MarcadorPosicao({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CoresApp.primaria.withValues(alpha: 0.22),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: CoresApp.primaria,
          shape: BoxShape.circle,
          border: Border.all(color: CoresApp.branco, width: 3),
        ),
      ),
    );
  }
}

class MarcadorMarco extends StatelessWidget {
  const MarcadorMarco({required this.icone, required this.rotulo, super.key});

  final IconData icone;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: CoresApp.creme,
            shape: BoxShape.circle,
            border: Border.all(color: CoresApp.marinho, width: 2),
          ),
          child: Icon(icone, size: 18, color: CoresApp.terracota),
        ),
        Text(
          rotulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: CoresApp.marinho,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class MarcadorPraca extends StatelessWidget {
  const MarcadorPraca({required this.rotulo, super.key});

  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: CoresApp.marinho,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CoresApp.destaque, width: 1.5),
        ),
        child: Text(
          rotulo,
          maxLines: 1,
          style: const TextStyle(
            color: CoresApp.destaque,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class MarcadorMota extends StatelessWidget {
  const MarcadorMota({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: CoresApp.destaque.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: CoresApp.marinho,
          shape: BoxShape.circle,
          border: Border.all(color: CoresApp.destaque, width: 3),
        ),
        child: const Icon(
          Icons.two_wheeler,
          size: 20,
          color: CoresApp.destaque,
        ),
      ),
    );
  }
}

class MarcadorDestino extends StatelessWidget {
  const MarcadorDestino({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: 0.785,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: CoresApp.terracota,
            border: Border.all(color: CoresApp.branco, width: 3),
          ),
        ),
      ),
    );
  }
}

class MarcadorParagem extends StatelessWidget {
  const MarcadorParagem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CoresApp.terracota,
        shape: BoxShape.circle,
        border: Border.all(color: CoresApp.branco, width: 3),
      ),
      child: const Icon(Icons.bookmark, size: 16, color: CoresApp.branco),
    );
  }
}
