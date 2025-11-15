// A tiny tool to extract embedded Lighthouse JSON from HTML reports
// and generate a comparison markdown between previous and current runs.
// Run: dart run tool/lighthouse_compare.dart

import 'dart:convert';
import 'dart:io';

class LhReport {
  final File htmlFile;
  final Map<String, dynamic> json;
  final DateTime? fetchTime;
  final String finalDisplayedUrl;
  final String group; // 'desktop' or 'mobile' heuristic

  LhReport({
    required this.htmlFile,
    required this.json,
    required this.fetchTime,
    required this.finalDisplayedUrl,
    required this.group,
  });
}

Future<void> main() async {
  final auditDir = Directory('docs/audit');
  if (!await auditDir.exists()) {
    stderr.writeln('docs/audit not found');
    exit(1);
  }

  final htmlFiles = await auditDir
      .list()
      .where((e) => e is File && e.path.endsWith('.html'))
      .cast<File>()
      .toList();

  if (htmlFiles.isEmpty) {
    stdout.writeln('No HTML reports found under docs/audit');
    return;
  }

  final reports = <LhReport>[];
  for (final file in htmlFiles) {
    try {
      final text = await file.readAsString();
      final jsonText = _extractEmbeddedJson(text);
      if (jsonText == null) {
        stderr.writeln('WARN: Could not extract JSON from ${file.path}');
        continue;
      }
      final data = json.decode(jsonText) as Map<String, dynamic>;
      // Save JSON next to HTML (same base name)
      final jsonOut = File(file.path.replaceAll(RegExp(r'\.html$'), '.json'));
      await jsonOut.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      final fetchTimeStr = data['fetchTime'] as String?;
      DateTime? fetchTime;
      if (fetchTimeStr != null) {
        try { fetchTime = DateTime.parse(fetchTimeStr); } catch (_) {}
      }
      final finalDisplayedUrl = (data['finalDisplayedUrl'] as String?) ?? '';
      final ua = (data['userAgent'] as String?) ?? '';
      final isMobileUA = ua.toLowerCase().contains('mobile') || ua.toLowerCase().contains('android') || ua.toLowerCase().contains('iphone');
      final group = isMobileUA || file.path.contains('device') ? 'mobile' : 'desktop';

      reports.add(LhReport(
        htmlFile: file,
        json: data,
        fetchTime: fetchTime,
        finalDisplayedUrl: finalDisplayedUrl,
        group: group,
      ));
    } catch (e) {
      stderr.writeln('ERROR processing ${file.path}: $e');
    }
  }

  if (reports.isEmpty) {
    stderr.writeln('No parsable reports found.');
    exit(1);
  }

  // Select pairs for comparison
  // Heuristic: previous = files starting with 'localhost_' (baseline), current = others (new*/device 1)
  List<LhReport> prevDesktop = reports.where((r) => r.group=='desktop' && r.htmlFile.path.contains('localhost_')).toList();
  List<LhReport> currDesktop = reports.where((r) => r.group=='desktop' && !r.htmlFile.path.contains('localhost_')).toList();
  prevDesktop.sort((a,b)=> (a.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)).compareTo(b.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)));
  currDesktop.sort((a,b)=> (a.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)).compareTo(b.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)));

  List<LhReport> prevMobile = reports.where((r) => r.group=='mobile' && (r.htmlFile.path.contains('device') || r.htmlFile.path.contains('localhost_'))).toList();
  List<LhReport> currMobile = reports.where((r) => r.group=='mobile' && !r.htmlFile.path.contains('localhost_')).toList();
  prevMobile.sort((a,b)=> (a.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)).compareTo(b.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)));
  currMobile.sort((a,b)=> (a.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)).compareTo(b.fetchTime??DateTime.fromMillisecondsSinceEpoch(0)));

  final desktopPrev = prevDesktop.isNotEmpty ? prevDesktop.last : null;
  final desktopCurr = currDesktop.isNotEmpty ? currDesktop.last : null;
  // For mobile, prefer explicit device vs device 1 ordering by time
  final mobilePrev = prevMobile.isNotEmpty ? prevMobile.first : null; // earlier
  final mobileCurr = currMobile.isNotEmpty ? currMobile.last : (prevMobile.length>1 ? prevMobile.last : null);

  final buffer = StringBuffer();
  buffer.writeln('# Lighthouse Comparison — ${DateTime.now().toIso8601String().substring(0,10)}');
  buffer.writeln();

  void section(String title, LhReport? prev, LhReport? curr) {
    buffer.writeln('## $title');
    if (prev == null || curr == null) {
      buffer.writeln('- Not enough reports to compare.');
      buffer.writeln();
      return;
    }
    final p = _scores(prev.json);
    final c = _scores(curr.json);
    buffer.writeln('- Previous: ${prev.htmlFile.uri.pathSegments.last} (${prev.fetchTime ?? ''})');
    buffer.writeln('- Current:  ${curr.htmlFile.uri.pathSegments.last} (${curr.fetchTime ?? ''})');
    buffer.writeln();
    buffer.writeln('| Category | Prev | Curr | Δ |');
    buffer.writeln('|---|---:|---:|---:|');
    for (final key in ['performance','accessibility','best-practices','seo']) {
      final pv = p[key];
      final cv = c[key];
      if (pv == null || cv == null) continue;
      final delta = (cv - pv);
      buffer.writeln('| ${_label(key)} | ${pv.toStringAsFixed(2)} | ${cv.toStringAsFixed(2)} | ${_sign(delta)} |');
    }
    buffer.writeln();
    // Core metrics
    final pm = _metrics(prev.json);
    final cm = _metrics(curr.json);
    buffer.writeln('| Metric | Prev | Curr | Δ |');
    buffer.writeln('|---|---:|---:|---:|');
    void row(String name, num? a, num? b, {String unit=''}){
      if (a==null || b==null) return;
      final d = (b - a);
      String fmt(num v){
        if (unit=='s') return '${(v/1000).toStringAsFixed(2)}s';
        if (unit=='ms') return '${v.toStringAsFixed(0)}ms';
        return v.toStringAsFixed(3);
      }
      String dfmt(num v){
        if (unit=='s') return '${_sign(v/1000, decimals:2)}s';
        if (unit=='ms') return '${_sign(v, decimals:0)}ms';
        return _sign(v, decimals:3);
      }
      buffer.writeln('| $name | ${fmt(a)} | ${fmt(b)} | ${dfmt(d)} |');
    }
    row('FCP', pm.fcpMs, cm.fcpMs, unit: 'ms');
    row('LCP', pm.lcpMs, cm.lcpMs, unit: 'ms');
    row('TBT', pm.tbtMs, cm.tbtMs, unit: 'ms');
    row('CLS', pm.cls, cm.cls);
    buffer.writeln();
  }

  section('Desktop', desktopPrev, desktopCurr);
  section('Mobile', mobilePrev, mobileCurr);

  final out = File('docs/audit/COMPARISON_2025-11-12.md');
  await out.writeAsString(buffer.toString());
  stdout.writeln('Wrote ${out.path}');
}

String _label(String key) {
  switch (key) {
    case 'performance': return 'Performance';
    case 'accessibility': return 'Accessibility';
    case 'best-practices': return 'Best Practices';
    case 'seo': return 'SEO';
  }
  return key;
}

String _sign(num v, {int decimals = 2}) {
  final s = v.toStringAsFixed(decimals);
  if (v > 0) return '+$s';
  if (v < 0) return s; // already has '-'
  return '0.${'0'*decimals}';
}

class _Metrics { final num? fcpMs, lcpMs, tbtMs, cls; const _Metrics({this.fcpMs, this.lcpMs, this.tbtMs, this.cls}); }

_Metrics _metrics(Map<String, dynamic> j){
  num? getMs(String id){
    final a = (j['audits'] as Map?)?[id] as Map?;
    final v = a?['numericValue'];
    if (v is num) return v;
    return null;
  }
  num? getNum(String id){
    final a = (j['audits'] as Map?)?[id] as Map?;
    final v = a?['numericValue'];
    if (v is num) return v;
    return null;
  }
  return _Metrics(
    fcpMs: getMs('first-contentful-paint'),
    lcpMs: getMs('largest-contentful-paint'),
    tbtMs: getMs('total-blocking-time'),
    cls: getNum('cumulative-layout-shift'),
  );
}

Map<String,double> _scores(Map<String, dynamic> j){
  final cats = (j['categories'] as Map?) ?? const {};
  double? s(String id){
    final v = (cats[id] as Map?)?['score'];
    if (v is num) return v.toDouble();
    return null;
  }
  final map = <String,double>{};
  for (final id in ['performance','accessibility','best-practices','seo']){
    final v = s(id);
    if (v!=null) map[id]=v;
  }
  return map;
}

String? _extractEmbeddedJson(String html){
  final marker = 'window.__LIGHTHOUSE_JSON__ = ';
  final idx = html.indexOf(marker);
  if (idx < 0) return null;
  int i = idx + marker.length;
  // Skip to first '{'
  while (i < html.length && html[i] != '{') {
    i++;
  }
  if (i >= html.length) return null;
  final start = i;
  int depth = 0;
  bool inString = false;
  bool escape = false;
  for (; i < html.length; i++){
    final ch = html[i];
    if (inString){
      if (escape){ escape = false; continue; }
      if (ch == '\\') { escape = true; continue; }
      if (ch == '"') { inString = false; }
      continue;
    } else {
      if (ch == '"') { inString = true; continue; }
      if (ch == '{') depth++;
      if (ch == '}') { depth--; if (depth==0){ final end = i+1; return html.substring(start, end); } }
    }
  }
  return null;
}
