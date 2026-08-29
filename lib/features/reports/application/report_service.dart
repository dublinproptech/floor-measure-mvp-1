import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../projects/data/project_model.dart';
import '../../rooms/data/room_model.dart';
import '../../rooms/domain/measurement_service.dart';
import '../../../data/models/flooring_type_model.dart';
import '../../snaglist/data/snag_model.dart';
import '../../files/data/attachment_model.dart';

class ReportData {
  final ProjectModel project;
  final List<RoomModel> rooms;
  final List<SnagModel> snags;
  final List<FlooringTypeModel> flooringTypes;
  final List<AttachmentModel> attachments;
  const ReportData({
    required this.project,
    required this.rooms,
    required this.snags,
    required this.flooringTypes,
    required this.attachments,
  });
}

class ReportService {
  const ReportService();

  static const _svc = MeasurementService();
  static const PdfColor _gold = PdfColor.fromInt(0xFFC17F22);
  static const PdfColor _ink = PdfColor.fromInt(0xFF1C1A17);
  static const PdfColor _muted = PdfColor.fromInt(0xFF8A8078);
  static const PdfColor _line = PdfColor.fromInt(0xFFE6DDD0);

  Future<Uint8List> build(ReportData d) async {
    final doc = pw.Document();
    final typeById = {for (final t in d.flooringTypes) t.id: t};

    // Decode snag photos and up to 4 site photos once, up front.
    final snagPhotos = <String, pw.MemoryImage>{};
    for (final a in d.attachments.where((a) => a.snagId != null)) {
      snagPhotos[a.snagId!] = pw.MemoryImage(base64Decode(a.imageBase64));
    }
    final sitePhotos = d.attachments
        .where((a) => a.snagId == null && a.roomId == null)
        .take(4)
        .map((a) => pw.MemoryImage(base64Decode(a.imageBase64)))
        .toList();

    var totalArea = 0.0, totalOrder = 0.0;
    for (final r in d.rooms) {
      totalArea += r.area;
      totalOrder += _svc.orderArea(r.area, r.wastagePct);
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(), // default fonts; matches system look
        ),
        header: (ctx) => ctx.pageNumber == 1 ? _header(d.project) : _runningHead(d.project),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: _muted)),
        ),
        build: (ctx) => [
          _sectionTitle('Project details'),
          _projectInfo(d.project),
          pw.SizedBox(height: 16),
          _sectionTitle('Measurement summary'),
          _roomsTable(d.rooms, typeById),
          pw.SizedBox(height: 8),
          _totalsRow(totalArea, totalOrder),
          pw.SizedBox(height: 16),
          _sectionTitle('Snaglist (${d.snags.length})'),
          ..._snagWidgets(d.snags, snagPhotos),
          if (sitePhotos.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _sectionTitle('Site photos'),
            _photoGrid(sitePhotos),
          ],
          pw.SizedBox(height: 20),
          _summary(d, totalArea, totalOrder),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _header(ProjectModel p) => pw.Container(
    padding: const pw.EdgeInsets.only(bottom: 12),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _gold, width: 2)),
    ),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Dublin PropTech',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _ink)),
      pw.Text('Floor Survey Report',
          style: const pw.TextStyle(fontSize: 12, color: _muted)),
    ]),
  );

  pw.Widget _runningHead(ProjectModel p) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text('Dublin PropTech  ·  ${p.name}',
        style: const pw.TextStyle(fontSize: 9, color: _muted)),
  );

  pw.Widget _sectionTitle(String text) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(text,
        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _gold)),
  );

  pw.Widget _projectInfo(ProjectModel p) {
    final d = p.surveyDate;
    return pw.Column(children: [
      _infoRow('Project', p.name),
      _infoRow('Client', p.client),
      _infoRow('Address', p.address),
      _infoRow('Contact', p.contactDetails),
      _infoRow('Survey date', '${d.day}/${d.month}/${d.year}'),
      _infoRow('Status', p.status.label),
      if (p.notes.isNotEmpty) _infoRow('Notes', p.notes),
    ]);
  }

  pw.Widget _infoRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(
          width: 90,
          child: pw.Text(label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _muted))),
      pw.Expanded(
          child: pw.Text(value.isEmpty ? '-' : value,
              style: const pw.TextStyle(fontSize: 10, color: _ink))),
    ]),
  );

  pw.Widget _roomsTable(List<RoomModel> rooms, Map<String, FlooringTypeModel> types) {
    final headers = ['Room', 'Dimensions', 'Area', 'Flooring', 'Waste', 'Packs'];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAF8F4)),
      cellAlignment: pw.Alignment.centerLeft,
      border: pw.TableBorder.all(color: _line, width: 0.5),
      data: rooms.map((r) {
        final t = types[r.flooringTypeId];
        final order = _svc.orderArea(r.area, r.wastagePct);
        final packs = t == null ? '-' : '${_svc.packs(order, t.packSize)}';
        return [
          r.name,
          '${r.length} x ${r.width} ${r.unit}',
          '${r.area.toStringAsFixed(2)} m2',
          t?.name ?? '-',
          '${r.wastagePct.toStringAsFixed(0)}%',
          packs,
        ];
      }).toList(),
    );
  }

  pw.Widget _totalsRow(double area, double order) => pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: const PdfColor.fromInt(0xFFFAF8F4),
      border: pw.Border.all(color: _line, width: 0.5),
    ),
    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('Total floor area: ${area.toStringAsFixed(2)} m2',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
      pw.Text('Order area (with waste): ${order.toStringAsFixed(2)} m2',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
    ]),
  );

  List<pw.Widget> _snagWidgets(List<SnagModel> snags, Map<String, pw.MemoryImage> photos) {
    if (snags.isEmpty) {
      return [pw.Text('No snags recorded.', style: const pw.TextStyle(fontSize: 10, color: _muted))];
    }
    return snags.map((s) {
      final photo = photos[s.id];
      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _line, width: 0.5)),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('${s.ref}  ·  ${s.location}',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink)),
              pw.SizedBox(height: 2),
              pw.Text(s.description, style: const pw.TextStyle(fontSize: 9, color: _ink)),
              pw.SizedBox(height: 2),
              pw.Text('${s.category}  ·  ${s.priority.name}  ·  ${s.status.name}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ]),
          ),
          if (photo != null) ...[
            pw.SizedBox(width: 8),
            pw.ClipRRect(
              horizontalRadius: 4, verticalRadius: 4,
              child: pw.Image(photo, width: 80, height: 80, fit: pw.BoxFit.cover),
            ),
          ],
        ]),
      );
    }).toList();
  }

  pw.Widget _photoGrid(List<pw.MemoryImage> photos) => pw.Wrap(
    spacing: 8, runSpacing: 8,
    children: photos
        .map((img) => pw.ClipRRect(
      horizontalRadius: 4, verticalRadius: 4,
      child: pw.Image(img, width: 120, height: 120, fit: pw.BoxFit.cover),
    ))
        .toList(),
  );

  pw.Widget _summary(ReportData d, double area, double order) {
    final openSnags = d.snags
        .where((s) => s.status == SnagStatus.open || s.status == SnagStatus.inProgress)
        .length;
    final doneSnags = d.snags.length - openSnags;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _gold, width: 1)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Summary',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink)),
        pw.SizedBox(height: 6),
        _infoRow('Rooms', '${d.rooms.length}'),
        _infoRow('Total floor area', '${area.toStringAsFixed(2)} m2'),
        _infoRow('Total order area', '${order.toStringAsFixed(2)} m2'),
        _infoRow('Snags total', '${d.snags.length}'),
        _infoRow('Snags open', '$openSnags'),
        _infoRow('Snags completed', '$doneSnags'),
      ]),
    );
  }
}