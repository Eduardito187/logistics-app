import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/printing/mdns_service.dart';

// MdnsService: servicio de impresora anunciado por Bonjour. Detección de Zebra
// por nombre/TXT, puerto a probar y parseo del mapa del canal.

MdnsService _svc({
  String name = 'Impresora',
  String type = '_printer._tcp',
  int port = 515,
  Map<String, String> txt = const {},
}) => MdnsService(
  name: name,
  type: type,
  host: '192.168.2.154',
  port: port,
  txt: txt,
);

void main() {
  group('looksLikeZebra', () {
    test('por nombre del servicio', () {
      expect(_svc(name: 'ZD421-203dpi ZPL').looksLikeZebra, isTrue);
      expect(_svc(name: 'Zebra Technologies ZTC').looksLikeZebra, isTrue);
    });

    test('por TXT product / ty / usb_MDL', () {
      expect(_svc(txt: {'product': '(ZT230)'}).looksLikeZebra, isTrue);
      expect(_svc(txt: {'ty': 'Zebra ZD620'}).looksLikeZebra, isTrue);
      expect(_svc(txt: {'usb_MDL': 'ZQ630'}).looksLikeZebra, isTrue);
    });

    test('Ricoh / HP no son Zebra', () {
      expect(
        _svc(
          name: 'RICOH IM 550 [A1B2C3]',
          txt: {'product': '(RICOH IM 550)', 'usb_MFG': 'RICOH'},
        ).looksLikeZebra,
        isFalse,
      );
      expect(_svc(name: 'HP LaserJet M404').looksLikeZebra, isFalse);
    });
  });

  group('portToProbe', () {
    test('_pdl-datastream usa su puerto anunciado', () {
      final s = _svc(type: '_pdl-datastream._tcp.', port: 9101);
      expect(s.isRawPrinting, isTrue);
      expect(s.portToProbe(9100), 9101);
    });

    test('_printer / _ipp prueban el puerto de impresión cruda', () {
      expect(_svc(type: '_ipp._tcp', port: 631).portToProbe(9100), 9100);
      expect(_svc(type: '_printer._tcp', port: 515).portToProbe(9100), 9100);
    });

    test('_pdl-datastream con puerto inválido -> el pedido', () {
      expect(
        _svc(type: '_pdl-datastream._tcp', port: 0).portToProbe(9100),
        9100,
      );
    });
  });

  group('fromMap', () {
    test('mapa completo', () {
      final s = MdnsService.fromMap({
        'name': ' RICOH IM 550 ',
        'type': '_ipp._tcp',
        'host': '192.168.2.154',
        'port': 631,
        'txt': {'ty': 'RICOH IM 550', 'n': 3},
      })!;

      expect(s.name, 'RICOH IM 550');
      expect(s.type, '_ipp._tcp');
      expect(s.port, 631);
      expect(s.txt, {'ty': 'RICOH IM 550'});
    });

    test('sin host o nombre -> null', () {
      expect(MdnsService.fromMap({'name': 'x'}), isNull);
      expect(MdnsService.fromMap({'host': '1.2.3.4'}), isNull);
      expect(MdnsService.fromMap({'name': ' ', 'host': '1.2.3.4'}), isNull);
      expect(MdnsService.fromMap('basura'), isNull);
    });

    test('tipos faltantes -> valores neutros', () {
      final s = MdnsService.fromMap({'name': 'P', 'host': '10.0.0.2'})!;
      expect(s.type, '');
      expect(s.port, 0);
      expect(s.txt, isEmpty);
    });
  });
}
